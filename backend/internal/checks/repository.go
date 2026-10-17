package checks

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// CreateCheckParams carries the fields needed to insert a private_checks row.
// OwnerUserID is always set: private detection is owner-scoped. A nil Assessment
// stores SQL NULL (used for deferred/processing checks).
type CreateCheckParams struct {
	OwnerUserID int64
	Status      string
	InputText   *string
	Locale      string
	Verdict     *string
	Assessment  *Assessment
	CompletedAt *time.Time
}

// CreateUploadParams carries the fields needed to insert a private_uploads row
// for a freshly stored image. OwnerUserID is always set: uploads are
// owner-scoped. The upload starts unlinked and in status 'uploaded';
// ProcessUpload later links it to a check and redacts it.
type CreateUploadParams struct {
	OwnerUserID int64
	StorageKey  string
	MediaType   string
	ByteSize    int64
}

// PurgeKey identifies the stored blobs of an upload removed by PurgeExpired, so
// the caller can delete the corresponding objects from the blob store.
type PurgeKey struct {
	StorageKey         string
	RedactedStorageKey *string
}

// CheckListItem is the reduced projection returned by list queries. It never
// includes input_text or extracted_text.
type CheckListItem struct {
	ID        int64
	Status    string
	Verdict   *string
	CreatedAt time.Time
}

// Cursor is an opaque pagination position over (created_at, id) in descending
// order.
type Cursor struct {
	CreatedAt time.Time
	ID        int64
}

// Repository is the persistence contract for the checks domain.
type Repository interface {
	// CreateCheck inserts a private_checks row and returns it with server-set
	// fields (id, created_at) populated.
	CreateCheck(ctx context.Context, p CreateCheckParams) (Check, error)
	// GetCheckByID returns a check by primary key. Returns ErrCheckNotFound if
	// absent. Ownership is enforced by the service, not here.
	GetCheckByID(ctx context.Context, id int64) (Check, error)
	// ListChecksByOwner returns a page of the owner's checks ordered by
	// (created_at, id) descending. limit rows are requested; the caller detects
	// whether more remain. cursor is nil for the first page.
	ListChecksByOwner(ctx context.Context, ownerUserID int64, limit int, cursor *Cursor) ([]CheckListItem, error)

	// CreateUpload inserts a private_uploads row for a freshly stored image and
	// returns it with server-set fields (id, created_at) populated. The upload
	// starts unlinked (check_id NULL) in status 'uploaded'.
	CreateUpload(ctx context.Context, p CreateUploadParams) (Upload, error)
	// GetUploadByID returns an upload by primary key. Returns ErrUploadNotFound
	// if absent.
	GetUploadByID(ctx context.Context, id int64) (Upload, error)
	// GetUploadByCheckID returns the upload linked to a check. Returns
	// ErrUploadNotFound if the check has no linked upload.
	GetUploadByCheckID(ctx context.Context, checkID int64) (Upload, error)
	// LinkUploadToCheck sets private_uploads.check_id.
	LinkUploadToCheck(ctx context.Context, uploadID, checkID int64) error
	MarkUploadProcessing(ctx context.Context, uploadID int64) error
	CompleteUploadRedaction(ctx context.Context, uploadID int64, extractedText *string, redactedStorageKey string) error
	FailUpload(ctx context.Context, uploadID int64) error

	// CompleteCheckFromUpload stores the result produced by the OCR worker: it
	// sets extracted_text, verdict, assessment, status='ready', and
	// completed_at on the check, and sets the upload's redacted_storage_key and
	// marks it ready. Used by ProcessUpload.
	//
	// extractedText and a are both nil when the worker recovered no readable
	// text: the check still completes as 'ready' but carries no extracted text,
	// no verdict, and no assessment (classification is skipped entirely).
	CompleteCheckFromUpload(ctx context.Context, checkID int64, extractedText *string, a *Assessment) error
	// FailCheck marks a check failed. Upload state is owned exclusively by the
	// PII-redaction worker, so failing a check never touches the upload.
	FailCheck(ctx context.Context, checkID int64) error

	// DeleteCheck permanently removes a check and, via ON DELETE CASCADE, its
	// linked uploads. It returns the deleted uploads so the caller can purge
	// their stored blobs. Returns ErrCheckNotFound if the check is absent.
	DeleteCheck(ctx context.Context, checkID int64) ([]Upload, error)
	// DeleteUpload permanently removes a single upload row and returns it so the
	// caller can purge its stored blobs. Returns ErrUploadNotFound if absent.
	DeleteUpload(ctx context.Context, uploadID int64) (Upload, error)
	// PurgeExpired removes every expired private check and upload and returns
	// the storage keys of the uploads removed (directly or by cascade) so the
	// caller can purge their stored blobs. It never touches unexpired rows.
	PurgeExpired(ctx context.Context) ([]PurgeKey, error)

	// RecordResourceOpen idempotently records a resource_opens row for the
	// success metric. At most one row per (check_id, resource_id) pair is kept.
	// Returns ErrResourceNotFound if the resource does not exist.
	RecordResourceOpen(ctx context.Context, p ResourceOpenParams) error

	// FindSimilarReports returns public reports resembling the given text. The
	// initial implementation may return an empty slice; callers must tolerate
	// that. It only ever reads public, sanitized report material.
	FindSimilarReports(ctx context.Context, text string, limit int) ([]SimilarReport, error)
}

// ResourceOpenParams carries the fields for a resource-open metric row. Either
// UserID or CheckID must be non-nil to satisfy the table CHECK constraint.
type ResourceOpenParams struct {
	UserID     *int64
	CheckID    *int64
	GuidanceID *int64
	ResourceID int64
}

// PostgresRepository is a pgx-backed Repository.
type PostgresRepository struct {
	pool *pgxpool.Pool
}

// NewPostgresRepository constructs a PostgresRepository.
func NewPostgresRepository(pool *pgxpool.Pool) *PostgresRepository {
	return &PostgresRepository{pool: pool}
}

// CreateCheck implements Repository.
func (r *PostgresRepository) CreateCheck(ctx context.Context, p CreateCheckParams) (Check, error) {
	var assessmentJSON []byte
	if p.Assessment != nil {
		b, err := json.Marshal(p.Assessment)
		if err != nil {
			return Check{}, fmt.Errorf("checks: marshal assessment: %w", err)
		}
		assessmentJSON = b
	}

	const q = `
		INSERT INTO private_checks (owner_user_id, status, input_text, locale, verdict, assessment, completed_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at`

	c := Check{
		OwnerUserID: p.OwnerUserID,
		Status:      p.Status,
		InputText:   p.InputText,
		Locale:      p.Locale,
		Verdict:     p.Verdict,
		Assessment:  p.Assessment,
		CompletedAt: p.CompletedAt,
	}
	err := r.pool.QueryRow(ctx, q,
		p.OwnerUserID, p.Status, p.InputText, p.Locale, p.Verdict, assessmentJSON, p.CompletedAt,
	).Scan(&c.ID, &c.CreatedAt)
	if err != nil {
		return Check{}, fmt.Errorf("checks: insert check: %w", err)
	}
	return c, nil
}

// CreateUpload implements Repository. The row starts unlinked (check_id NULL)
// in status 'uploaded'; the redacted copy is attached later by the OCR worker.
func (r *PostgresRepository) CreateUpload(ctx context.Context, p CreateUploadParams) (Upload, error) {
	const q = `
		INSERT INTO private_uploads (owner_user_id, storage_key, media_type, byte_size, status)
		VALUES ($1, $2, $3, $4, 'uploaded')
		RETURNING id, created_at`

	u := Upload{
		OwnerUserID: p.OwnerUserID,
		StorageKey:  p.StorageKey,
		MediaType:   p.MediaType,
		ByteSize:    p.ByteSize,
		Status:      UploadStatusUploaded,
	}
	err := r.pool.QueryRow(ctx, q,
		p.OwnerUserID, p.StorageKey, p.MediaType, p.ByteSize,
	).Scan(&u.ID, &u.CreatedAt)
	if err != nil {
		return Upload{}, fmt.Errorf("checks: insert upload: %w", err)
	}
	return u, nil
}

// GetCheckByID implements Repository.
func (r *PostgresRepository) GetCheckByID(ctx context.Context, id int64) (Check, error) {
	const q = `
		SELECT id, owner_user_id, status, input_text, extracted_text, locale, verdict, assessment, created_at, completed_at
		FROM private_checks
		WHERE id = $1`

	var (
		c              Check
		assessmentJSON []byte
	)
	err := r.pool.QueryRow(ctx, q, id).Scan(
		&c.ID, &c.OwnerUserID, &c.Status, &c.InputText, &c.ExtractedText,
		&c.Locale, &c.Verdict, &assessmentJSON, &c.CreatedAt, &c.CompletedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Check{}, ErrCheckNotFound
		}
		return Check{}, fmt.Errorf("checks: get check: %w", err)
	}
	if len(assessmentJSON) > 0 {
		var a Assessment
		if err := json.Unmarshal(assessmentJSON, &a); err != nil {
			return Check{}, fmt.Errorf("checks: unmarshal assessment: %w", err)
		}
		c.Assessment = &a
	}
	return c, nil
}

// ListChecksByOwner implements Repository.
func (r *PostgresRepository) ListChecksByOwner(ctx context.Context, ownerUserID int64, limit int, cursor *Cursor) ([]CheckListItem, error) {
	// Keyset pagination over (created_at, id) descending. The cursor row itself
	// is excluded via the strict tuple comparison.
	var rows pgx.Rows
	var err error
	if cursor == nil {
		const q = `
			SELECT id, status, verdict, created_at
			FROM private_checks
			WHERE owner_user_id = $1
			ORDER BY created_at DESC, id DESC
			LIMIT $2`
		rows, err = r.pool.Query(ctx, q, ownerUserID, limit)
	} else {
		const q = `
			SELECT id, status, verdict, created_at
			FROM private_checks
			WHERE owner_user_id = $1
			  AND (created_at, id) < ($2, $3)
			ORDER BY created_at DESC, id DESC
			LIMIT $4`
		rows, err = r.pool.Query(ctx, q, ownerUserID, cursor.CreatedAt, cursor.ID, limit)
	}
	if err != nil {
		return nil, fmt.Errorf("checks: list checks: %w", err)
	}
	defer rows.Close()

	var items []CheckListItem
	for rows.Next() {
		var it CheckListItem
		if err := rows.Scan(&it.ID, &it.Status, &it.Verdict, &it.CreatedAt); err != nil {
			return nil, fmt.Errorf("checks: scan check row: %w", err)
		}
		items = append(items, it)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("checks: iterate check rows: %w", err)
	}
	return items, nil
}

// GetUploadByID implements Repository.
func (r *PostgresRepository) GetUploadByID(ctx context.Context, id int64) (Upload, error) {
	const q = `
		SELECT id, check_id, owner_user_id, storage_key, redacted_storage_key, extracted_text, media_type, byte_size, status, created_at
		FROM private_uploads
		WHERE id = $1`
	var u Upload
	err := r.pool.QueryRow(ctx, q, id).Scan(
		&u.ID, &u.CheckID, &u.OwnerUserID, &u.StorageKey, &u.RedactedStorageKey, &u.ExtractedText, &u.MediaType, &u.ByteSize, &u.Status, &u.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Upload{}, ErrUploadNotFound
		}
		return Upload{}, fmt.Errorf("checks: get upload: %w", err)
	}
	return u, nil
}

// GetUploadByCheckID implements Repository. When several uploads reference the
// same check, the most recently created row wins.
func (r *PostgresRepository) GetUploadByCheckID(ctx context.Context, checkID int64) (Upload, error) {
	const q = `
		SELECT id, check_id, owner_user_id, storage_key, redacted_storage_key, extracted_text, media_type, byte_size, status, created_at
		FROM private_uploads
		WHERE check_id = $1
		ORDER BY created_at DESC, id DESC
		LIMIT 1`
	var u Upload
	err := r.pool.QueryRow(ctx, q, checkID).Scan(
		&u.ID, &u.CheckID, &u.OwnerUserID, &u.StorageKey, &u.RedactedStorageKey, &u.ExtractedText, &u.MediaType, &u.ByteSize, &u.Status, &u.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Upload{}, ErrUploadNotFound
		}
		return Upload{}, fmt.Errorf("checks: get upload by check: %w", err)
	}
	return u, nil
}

// LinkUploadToCheck implements Repository.
func (r *PostgresRepository) LinkUploadToCheck(ctx context.Context, uploadID, checkID int64) error {
	const q = `
		UPDATE private_uploads
		SET check_id = $2
		WHERE id = $1`
	if _, err := r.pool.Exec(ctx, q, uploadID, checkID); err != nil {
		return fmt.Errorf("checks: link upload to check: %w", err)
	}
	return nil
}

// CompleteCheckFromUpload implements Repository.
func (r *PostgresRepository) MarkUploadProcessing(ctx context.Context, uploadID int64) error {
	tag, err := r.pool.Exec(ctx, `UPDATE private_uploads SET status = 'processing' WHERE id = $1`, uploadID)
	if err != nil {
		return fmt.Errorf("checks: mark upload processing: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrUploadNotFound
	}
	return nil
}

func (r *PostgresRepository) CompleteUploadRedaction(ctx context.Context, uploadID int64, extractedText *string, redactedStorageKey string) error {
	tag, err := r.pool.Exec(ctx, `UPDATE private_uploads SET status = 'ready', extracted_text = $2, redacted_storage_key = $3 WHERE id = $1`, uploadID, extractedText, redactedStorageKey)
	if err != nil {
		return fmt.Errorf("checks: complete upload redaction: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrUploadNotFound
	}
	return nil
}

func (r *PostgresRepository) FailUpload(ctx context.Context, uploadID int64) error {
	tag, err := r.pool.Exec(ctx, `UPDATE private_uploads SET status = 'failed' WHERE id = $1`, uploadID)
	if err != nil {
		return fmt.Errorf("checks: fail upload: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrUploadNotFound
	}
	return nil
}

// CompleteCheckFromUpload implements Repository.
func (r *PostgresRepository) CompleteCheckFromUpload(ctx context.Context, checkID int64, extractedText *string, a *Assessment) error {
	// A nil assessment is the "no readable text was recovered" terminal state:
	// both verdict and assessment are stored as SQL NULL so the check surfaces
	// no verdict. JSON-marshal only when an assessment is present.
	var (
		verdict        *string
		assessmentJSON []byte
	)
	if a != nil {
		b, err := json.Marshal(a)
		if err != nil {
			return fmt.Errorf("checks: marshal assessment: %w", err)
		}
		assessmentJSON = b
		verdict = &a.Verdict
	}

	const updCheck = `
		UPDATE private_checks
		SET extracted_text = $2, verdict = $3, assessment = $4, status = 'ready', completed_at = now()
		WHERE id = $1`
	tag, err := r.pool.Exec(ctx, updCheck, checkID, extractedText, verdict, assessmentJSON)
	if err != nil {
		return fmt.Errorf("checks: complete check: %w", err)
	}
	if tag.RowsAffected() == 0 {
		// The check was deleted (e.g. the owner cancelled the task) while the
		// OCR worker was running. Report not-found so the worker discards the
		// redacted blob it just wrote instead of leaving it orphaned.
		return ErrCheckNotFound
	}

	return nil
}

// FailCheck implements Repository.
func (r *PostgresRepository) FailCheck(ctx context.Context, checkID int64) error {
	const updCheck = `UPDATE private_checks SET status = 'failed', completed_at = now() WHERE id = $1`
	if _, err := r.pool.Exec(ctx, updCheck, checkID); err != nil {
		return fmt.Errorf("checks: fail check: %w", err)
	}
	return nil
}

// DeleteCheck implements Repository. It captures the check's linked uploads
// (so their blobs can be purged) and then deletes the check row; the uploads go
// with it via ON DELETE CASCADE. Returns ErrCheckNotFound when the check does
// not exist, so a delete is idempotent from the caller's perspective.
func (r *PostgresRepository) DeleteCheck(ctx context.Context, checkID int64) ([]Upload, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("checks: begin delete check tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	const selUploads = `
		SELECT id, check_id, owner_user_id, storage_key, redacted_storage_key, extracted_text, media_type, byte_size, status, created_at
		FROM private_uploads
		WHERE check_id = $1`
	rows, err := tx.Query(ctx, selUploads, checkID)
	if err != nil {
		return nil, fmt.Errorf("checks: select uploads for delete: %w", err)
	}
	var uploads []Upload
	for rows.Next() {
		var u Upload
		if err := rows.Scan(
			&u.ID, &u.CheckID, &u.OwnerUserID, &u.StorageKey, &u.RedactedStorageKey, &u.ExtractedText, &u.MediaType, &u.ByteSize, &u.Status, &u.CreatedAt,
		); err != nil {
			rows.Close()
			return nil, fmt.Errorf("checks: scan upload for delete: %w", err)
		}
		uploads = append(uploads, u)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("checks: iterate uploads for delete: %w", err)
	}

	const del = `DELETE FROM private_checks WHERE id = $1`
	tag, err := tx.Exec(ctx, del, checkID)
	if err != nil {
		return nil, fmt.Errorf("checks: delete check: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, ErrCheckNotFound
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("checks: commit delete check tx: %w", err)
	}
	return uploads, nil
}

// DeleteUpload implements Repository.
func (r *PostgresRepository) DeleteUpload(ctx context.Context, uploadID int64) (Upload, error) {
	const q = `
		DELETE FROM private_uploads
		WHERE id = $1
		RETURNING id, check_id, owner_user_id, storage_key, redacted_storage_key, extracted_text, media_type, byte_size, status, created_at`
	var u Upload
	err := r.pool.QueryRow(ctx, q, uploadID).Scan(
		&u.ID, &u.CheckID, &u.OwnerUserID, &u.StorageKey, &u.RedactedStorageKey, &u.ExtractedText, &u.MediaType, &u.ByteSize, &u.Status, &u.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Upload{}, ErrUploadNotFound
		}
		return Upload{}, fmt.Errorf("checks: delete upload: %w", err)
	}
	return u, nil
}

// PurgeExpired implements Repository. It runs in a single transaction: it first
// captures the storage keys of every upload that will be removed (those past
// their own expiry, plus any belonging to an expired check), deletes those
// uploads, then deletes the expired checks. The uploads are deleted before the
// checks so no upload is removed by cascade without its keys being captured.
func (r *PostgresRepository) PurgeExpired(ctx context.Context) ([]PurgeKey, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("checks: begin purge tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	const selKeys = `
		SELECT storage_key, redacted_storage_key
		FROM private_uploads
		WHERE expires_at <= now()
		   OR check_id IN (SELECT id FROM private_checks WHERE expires_at <= now())`
	rows, err := tx.Query(ctx, selKeys)
	if err != nil {
		return nil, fmt.Errorf("checks: select expired upload keys: %w", err)
	}
	var keys []PurgeKey
	for rows.Next() {
		var k PurgeKey
		if err := rows.Scan(&k.StorageKey, &k.RedactedStorageKey); err != nil {
			rows.Close()
			return nil, fmt.Errorf("checks: scan expired upload key: %w", err)
		}
		keys = append(keys, k)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("checks: iterate expired upload keys: %w", err)
	}

	const delUploads = `
		DELETE FROM private_uploads
		WHERE expires_at <= now()
		   OR check_id IN (SELECT id FROM private_checks WHERE expires_at <= now())`
	if _, err := tx.Exec(ctx, delUploads); err != nil {
		return nil, fmt.Errorf("checks: purge expired uploads: %w", err)
	}

	const delChecks = `DELETE FROM private_checks WHERE expires_at <= now()`
	if _, err := tx.Exec(ctx, delChecks); err != nil {
		return nil, fmt.Errorf("checks: purge expired checks: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("checks: commit purge tx: %w", err)
	}
	return keys, nil
}

// RecordResourceOpen implements Repository. The schema has no unique index on
// (check_id, resource_id), so idempotency is enforced with a guarded insert
// inside a transaction: a matching row short-circuits the insert. This keeps
// the success-metric count at most one open per (check_id, resource_id).
func (r *PostgresRepository) RecordResourceOpen(ctx context.Context, p ResourceOpenParams) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("checks: begin resource-open tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	// Confirm the resource exists (FK is RESTRICT; give a clean domain error
	// instead of a raw FK violation).
	var exists bool
	const resQ = `SELECT EXISTS (SELECT 1 FROM resources WHERE id = $1)`
	if err := tx.QueryRow(ctx, resQ, p.ResourceID).Scan(&exists); err != nil {
		return fmt.Errorf("checks: check resource exists: %w", err)
	}
	if !exists {
		return ErrResourceNotFound
	}

	// Idempotency guard: only meaningful when a check is linked, since anonymous
	// user-only opens have no natural dedupe key here.
	if p.CheckID != nil {
		var already bool
		const dupQ = `SELECT EXISTS (
			SELECT 1 FROM resource_opens WHERE check_id = $1 AND resource_id = $2
		)`
		if err := tx.QueryRow(ctx, dupQ, *p.CheckID, p.ResourceID).Scan(&already); err != nil {
			return fmt.Errorf("checks: check duplicate resource-open: %w", err)
		}
		if already {
			return tx.Commit(ctx)
		}
	}

	const ins = `
		INSERT INTO resource_opens (user_id, check_id, guidance_id, resource_id)
		VALUES ($1, $2, $3, $4)`
	if _, err := tx.Exec(ctx, ins, p.UserID, p.CheckID, p.GuidanceID, p.ResourceID); err != nil {
		return fmt.Errorf("checks: insert resource-open: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("checks: commit resource-open tx: %w", err)
	}
	return nil
}

// FindSimilarReports implements Repository. It performs a lightweight full-text
// match against public, visible reports and returns safe excerpts only. If the
// query text yields no usable search terms it returns an empty slice. Similarity
// ranking is intentionally simple; the implementation can be swapped behind this
// interface as volume grows.
func (r *PostgresRepository) FindSimilarReports(ctx context.Context, text string, limit int) ([]SimilarReport, error) {
	if limit <= 0 {
		return nil, nil
	}
	// websearch_to_tsquery tolerates arbitrary user text without throwing on
	// punctuation, and 'simple' matches the report search index configuration.
	const q = `
		SELECT id, left(redacted_text, 160) AS excerpt, review_status
		FROM reports
		WHERE deleted_at IS NULL
		  AND review_status NOT IN ('hidden', 'removed')
		  AND to_tsvector('simple', title || ' ' || redacted_text)
		      @@ websearch_to_tsquery('simple', $1)
		ORDER BY created_at DESC, id DESC
		LIMIT $2`

	rows, err := r.pool.Query(ctx, q, text, limit)
	if err != nil {
		return nil, fmt.Errorf("checks: find similar reports: %w", err)
	}
	defer rows.Close()

	var out []SimilarReport
	for rows.Next() {
		var (
			id           int64
			excerpt      string
			reviewStatus string
		)
		if err := rows.Scan(&id, &excerpt, &reviewStatus); err != nil {
			return nil, fmt.Errorf("checks: scan similar report: %w", err)
		}
		out = append(out, SimilarReport{
			ReportID:     encodeID(id),
			Excerpt:      excerpt,
			Rationale:    "Shares wording with a community report.",
			ReviewStatus: reviewStatus,
		})
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("checks: iterate similar reports: %w", err)
	}
	return out, nil
}

// GetPhoneReputation implements PhoneRepository against the phone_reports
// ledger and the phone_classifications table. It counts only reports filed
// within the reputation window (now - reputationWindow, now], so stale reports
// stop influencing a number's reputation — important because scammers spoof or
// cycle numbers. It also reads any classification whose window is still active
// (window_end > now). A number with no in-window reports and no active
// classification returns Found=false.
func (r *PostgresRepository) GetPhoneReputation(ctx context.Context, normalized string, now time.Time) (PhoneReputation, error) {
	windowStart := now.Add(-reputationWindow)

	var reportCount int64
	err := r.pool.QueryRow(ctx,
		`SELECT count(*) FROM phone_reports
		 WHERE phone_number = $1 AND created_at > $2 AND created_at <= $3`,
		normalized, windowStart, now,
	).Scan(&reportCount)
	if err != nil {
		return PhoneReputation{}, fmt.Errorf("checks: count phone reports: %w", err)
	}

	// An active classification applies independently of in-window report count,
	// so a classified number still surfaces its label even if reports have aged
	// out of the window.
	var classification string
	err = r.pool.QueryRow(ctx,
		`SELECT classification FROM phone_classifications
		 WHERE phone_number = $1 AND window_start <= $2 AND window_end > $2`,
		normalized, now,
	).Scan(&classification)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return PhoneReputation{}, fmt.Errorf("checks: read phone classification: %w", err)
	}

	return PhoneReputation{
		Found:          reportCount > 0 || classification != "",
		ReportCount:    reportCount,
		Classification: classification,
	}, nil
}

// InsertPhoneReport appends a community report to the append-only phone_reports
// ledger. The classification system reads this ledger separately to assign a
// windowed classification.
//
// A user may hold at most one live report per phone number: the insert is
// skipped when the reporter already has a report for the same number inside the
// reputation window, and ErrPhoneReportDuplicate is returned instead. Reports
// older than the window have expired — they no longer affect reputation — so the
// user is free to report the number again.
//
// The check runs inside a transaction behind an advisory lock keyed on
// (number, reporter) so concurrent requests from the same user cannot both pass
// the guard and append duplicate rows. The endpoint is always authenticated, so
// reporter is non-nil in practice; the anonymous case (NULL reporter) is left
// undeduplicated because there is no identity to key on.
func (r *PostgresRepository) InsertPhoneReport(ctx context.Context, report PhoneReport, now time.Time) error {
	var reporter *int64
	if report.ReporterUserID > 0 {
		reporter = &report.ReporterUserID
	}
	cutoff := now.Add(-reputationWindow)

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("checks: begin phone report tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	if reporter != nil {
		const lock = `SELECT pg_advisory_xact_lock(hashtextextended($1, 0))`
		// The separator must be a character a normalized number can never
		// contain, so two different (number, reporter) pairs cannot collide on
		// the same key. It must not be a NUL byte: Postgres rejects NUL inside
		// text values. Normalized numbers are digits plus an optional leading
		// '+', so ':' is safe.
		key := report.PhoneNumber + ":" + strconv.FormatInt(*reporter, 10)
		if _, err := tx.Exec(ctx, lock, key); err != nil {
			return fmt.Errorf("checks: lock phone report: %w", err)
		}
	}

	// RETURNING yields no row when the reporter's existing report is still
	// inside the window, which is the duplicate signal.
	const insert = `
		INSERT INTO phone_reports (phone_number, reason, reporter_user_id, created_at)
		SELECT $1, $2, $3, $4
		WHERE NOT EXISTS (
			SELECT 1 FROM phone_reports
			WHERE phone_number = $1
			  AND reporter_user_id = $3
			  AND created_at > $5
		)
		RETURNING id`
	var id int64
	if err := tx.QueryRow(ctx, insert,
		report.PhoneNumber, report.Reason, reporter, now, cutoff,
	).Scan(&id); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrPhoneReportDuplicate
		}
		return fmt.Errorf("checks: insert phone report: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("checks: commit phone report tx: %w", err)
	}
	return nil
}
