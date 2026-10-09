package checks

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// CreateCheckParams carries the fields needed to insert a private_checks row.
// A nil Assessment stores SQL NULL (used for deferred/processing checks).
type CreateCheckParams struct {
	OwnerUserID *int64
	Status      string
	InputText   *string
	Locale      string
	Verdict     *string
	Assessment  *Assessment
	CompletedAt *time.Time
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

	// GetUploadByID returns an upload by primary key. Returns ErrUploadNotFound
	// if absent.
	GetUploadByID(ctx context.Context, id int64) (Upload, error)
	// LinkUploadToCheck sets private_uploads.check_id and marks the upload
	// processing, in a single statement.
	LinkUploadToCheck(ctx context.Context, uploadID, checkID int64) error

	// CompleteCheckFromUpload stores an assessment produced by the (future) OCR
	// worker: it sets extracted_text, verdict, assessment, status='ready', and
	// completed_at, and marks the upload ready. Used by ProcessUpload.
	CompleteCheckFromUpload(ctx context.Context, checkID, uploadID int64, extractedText string, a Assessment) error
	// FailCheck marks a check (and optionally its upload) failed.
	FailCheck(ctx context.Context, checkID int64, uploadID *int64) error

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
		SELECT id, check_id, owner_user_id, storage_key, media_type, byte_size, status, created_at
		FROM private_uploads
		WHERE id = $1`
	var u Upload
	err := r.pool.QueryRow(ctx, q, id).Scan(
		&u.ID, &u.CheckID, &u.OwnerUserID, &u.StorageKey, &u.MediaType, &u.ByteSize, &u.Status, &u.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Upload{}, ErrUploadNotFound
		}
		return Upload{}, fmt.Errorf("checks: get upload: %w", err)
	}
	return u, nil
}

// LinkUploadToCheck implements Repository.
func (r *PostgresRepository) LinkUploadToCheck(ctx context.Context, uploadID, checkID int64) error {
	const q = `
		UPDATE private_uploads
		SET check_id = $2, status = 'processing'
		WHERE id = $1`
	if _, err := r.pool.Exec(ctx, q, uploadID, checkID); err != nil {
		return fmt.Errorf("checks: link upload to check: %w", err)
	}
	return nil
}

// CompleteCheckFromUpload implements Repository.
func (r *PostgresRepository) CompleteCheckFromUpload(ctx context.Context, checkID, uploadID int64, extractedText string, a Assessment) error {
	assessmentJSON, err := json.Marshal(a)
	if err != nil {
		return fmt.Errorf("checks: marshal assessment: %w", err)
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("checks: begin complete tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	const updCheck = `
		UPDATE private_checks
		SET extracted_text = $2, verdict = $3, assessment = $4, status = 'ready', completed_at = now()
		WHERE id = $1`
	if _, err := tx.Exec(ctx, updCheck, checkID, extractedText, a.Verdict, assessmentJSON); err != nil {
		return fmt.Errorf("checks: complete check: %w", err)
	}

	const updUpload = `UPDATE private_uploads SET status = 'ready' WHERE id = $1`
	if _, err := tx.Exec(ctx, updUpload, uploadID); err != nil {
		return fmt.Errorf("checks: mark upload ready: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("checks: commit complete tx: %w", err)
	}
	return nil
}

// FailCheck implements Repository.
func (r *PostgresRepository) FailCheck(ctx context.Context, checkID int64, uploadID *int64) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("checks: begin fail tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	const updCheck = `UPDATE private_checks SET status = 'failed', completed_at = now() WHERE id = $1`
	if _, err := tx.Exec(ctx, updCheck, checkID); err != nil {
		return fmt.Errorf("checks: fail check: %w", err)
	}
	if uploadID != nil {
		const updUpload = `UPDATE private_uploads SET status = 'failed' WHERE id = $1`
		if _, err := tx.Exec(ctx, updUpload, *uploadID); err != nil {
			return fmt.Errorf("checks: fail upload: %w", err)
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("checks: commit fail tx: %w", err)
	}
	return nil
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

// GetPhoneReputation implements PhoneRepository as a stub. The phone-number
// scam database is owned by the data team and not yet wired, so every lookup
// currently reports the number as unseen (Found=false), which the service maps
// to the neutral DefaultTrustScore. This satisfies the interface and lets the
// endpoint work end to end today.
//
// TODO(checks): replace the stub body with a real query against the phone
// reputation table once the data team provides it, e.g.:
//
//	SELECT trust_score, report_count FROM phone_reputations WHERE phone_e164 = $1
//
// returning Found=true with the stored score/count, and Found=false on no row.
// Keep the normalized (E.164-style) number as the lookup key.
func (r *PostgresRepository) GetPhoneReputation(ctx context.Context, normalized string) (PhoneReputation, error) {
	_ = ctx
	_ = normalized
	return PhoneReputation{Found: false}, nil
}
