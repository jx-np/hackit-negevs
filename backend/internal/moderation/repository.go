package moderation

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const uniqueViolationCode = "23505"

// isUniqueViolation reports whether err is a Postgres unique-constraint
// violation, used to translate duplicate flags into ErrDuplicateFlag.
func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == uniqueViolationCode
	}
	return false
}

// CreateCommentParams carries the fields to insert a comments row.
type CreateCommentParams struct {
	ReportID        int64
	AuthorUserID    int64
	ParentCommentID *int64
	Body            string
}

// Repository is the persistence contract for the moderation domain.
type Repository interface {
	// ListComments returns a page of visible comments for a report, ordered by
	// (created_at, id) ascending, with the author display label joined.
	ListComments(ctx context.Context, reportID int64, limit int, cursor *Cursor) ([]Comment, error)
	// CreateComment inserts a visible comment and returns the hydrated row.
	CreateComment(ctx context.Context, p CreateCommentParams) (Comment, error)
	// GetComment returns a single non-removed comment with author label. Returns
	// ErrCommentNotFound when absent or removed.
	GetComment(ctx context.Context, id int64) (Comment, error)
	// UpdateCommentBody sets a new body (and bumps updated_at) for a non-removed
	// comment. Returns ErrCommentNotFound when absent or removed.
	UpdateCommentBody(ctx context.Context, id int64, body string) (Comment, error)
	// SetCommentStatus sets the status of a comment. Returns ErrCommentNotFound
	// when the row is absent.
	SetCommentStatus(ctx context.Context, id int64, status string) error
	// GetCommentOwnership returns the author id and whether the comment exists
	// and is not removed, for authorization checks.
	GetCommentOwnership(ctx context.Context, id int64) (authorUserID *int64, exists bool, err error)
	// CommentReportID returns the report id a comment belongs to and whether the
	// comment exists (in any status). Used to validate parent linkage.
	CommentReportID(ctx context.Context, id int64) (reportID int64, exists bool, err error)

	// ReportVisible reports whether a report exists and is publicly visible.
	ReportVisible(ctx context.Context, id int64) (bool, error)
	// ReportExists reports whether a report row exists (any status, not
	// soft-deleted). Used by moderator review which may act on hidden reports.
	ReportExists(ctx context.Context, id int64) (bool, error)

	// CreateReportFlag inserts a flag against a report. Returns ErrDuplicateFlag
	// on a unique-constraint violation.
	CreateReportFlag(ctx context.Context, reporterUserID, reportID int64, reason string, details *string) (Flag, error)
	// CreateCommentFlag inserts a flag against a comment. Returns ErrDuplicateFlag
	// on a unique-constraint violation.
	CreateCommentFlag(ctx context.Context, reporterUserID, commentID int64, reason string, details *string) (Flag, error)

	// ListOpenFlags returns a page of open flags oldest-first with a short
	// excerpt of the flagged target, ordered by (created_at, id) ascending.
	ListOpenFlags(ctx context.Context, limit int, cursor *Cursor) ([]QueueItem, error)

	// ReviewReport applies a moderator decision to a report: sets the report's
	// review_status side effect, records a moderation_decisions row, and resolves
	// related open flags — all in one transaction. Returns ErrReportNotFound if
	// the report is absent.
	ReviewReport(ctx context.Context, reportID int64, moderatorUserID int64, decision, reviewStatus string, rationale *string, suggestionID *int64) (Decision, error)
	// ReviewComment applies a moderator decision to a comment: sets the comment's
	// status side effect, records a moderation_decisions row, and resolves
	// related open flags — all in one transaction. Returns ErrCommentNotFound if
	// the comment is absent.
	ReviewComment(ctx context.Context, commentID int64, moderatorUserID int64, decision, commentStatus string, rationale *string) (Decision, error)
}

// PostgresRepository is a pgx-backed Repository.
type PostgresRepository struct {
	pool *pgxpool.Pool
}

// NewPostgresRepository constructs a PostgresRepository.
func NewPostgresRepository(pool *pgxpool.Pool) *PostgresRepository {
	return &PostgresRepository{pool: pool}
}

// commentSelectSQL projects a comment row plus its author display label. The
// label is the users.display_name or the "removed user" fallback when the
// author row was cleared (passed as the last positional arg). Author email/id
// are never selected here.
//
// Callers pass the report/comment id as $1 and the removed-user label as $2,
// then append any further filter args.
const commentSelectSQL = `
	SELECT
		cm.id, cm.report_id, cm.author_user_id, cm.parent_comment_id,
		COALESCE(u.display_name, $2) AS author_label,
		COALESCE(u.is_bot, false) AS is_bot,
		cm.body, cm.status, cm.created_at, cm.updated_at
	FROM comments cm
	LEFT JOIN users u ON u.id = cm.author_user_id`

// scanComment scans a row produced by commentSelectSQL.
func scanComment(row pgx.Row) (Comment, error) {
	var c Comment
	err := row.Scan(
		&c.ID, &c.ReportID, &c.AuthorUserID, &c.ParentCommentID,
		&c.AuthorLabel, &c.IsBot, &c.Body, &c.Status, &c.CreatedAt, &c.UpdatedAt,
	)
	return c, err
}

// ListComments implements Repository.
func (r *PostgresRepository) ListComments(ctx context.Context, reportID int64, limit int, cursor *Cursor) ([]Comment, error) {
	// $1 report id, $2 removed-user label, then optional cursor args, then limit.
	query := commentSelectSQL + "\n\tWHERE cm.report_id = $1 AND cm.status = 'visible'"
	args := []any{reportID, removedUserLabel}
	if cursor != nil {
		args = append(args, cursor.CreatedAt, cursor.ID)
		query += fmt.Sprintf("\n\tAND (cm.created_at, cm.id) > ($%d, $%d)", len(args)-1, len(args))
	}
	args = append(args, limit)
	query += fmt.Sprintf("\n\tORDER BY cm.created_at ASC, cm.id ASC\n\tLIMIT $%d", len(args))

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("moderation: query comments: %w", err)
	}
	defer rows.Close()

	var out []Comment
	for rows.Next() {
		c, err := scanComment(rows)
		if err != nil {
			return nil, fmt.Errorf("moderation: scan comment: %w", err)
		}
		out = append(out, c)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("moderation: iterate comments: %w", err)
	}
	return out, nil
}

// CreateComment implements Repository.
func (r *PostgresRepository) CreateComment(ctx context.Context, p CreateCommentParams) (Comment, error) {
	const ins = `
		INSERT INTO comments (report_id, author_user_id, parent_comment_id, body, status)
		VALUES ($1, $2, $3, $4, 'visible')
		RETURNING id`
	var id int64
	if err := r.pool.QueryRow(ctx, ins,
		p.ReportID, p.AuthorUserID, p.ParentCommentID, p.Body,
	).Scan(&id); err != nil {
		return Comment{}, fmt.Errorf("moderation: insert comment: %w", err)
	}
	return r.GetComment(ctx, id)
}

// GetComment implements Repository.
func (r *PostgresRepository) GetComment(ctx context.Context, id int64) (Comment, error) {
	query := commentSelectSQL + "\n\tWHERE cm.id = $1 AND cm.status <> 'removed'"
	c, err := scanComment(r.pool.QueryRow(ctx, query, id, removedUserLabel))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Comment{}, ErrCommentNotFound
		}
		return Comment{}, fmt.Errorf("moderation: get comment: %w", err)
	}
	return c, nil
}

// UpdateCommentBody implements Repository.
func (r *PostgresRepository) UpdateCommentBody(ctx context.Context, id int64, body string) (Comment, error) {
	const upd = `
		UPDATE comments SET body = $2, updated_at = now()
		WHERE id = $1 AND status <> 'removed'`
	ct, err := r.pool.Exec(ctx, upd, id, body)
	if err != nil {
		return Comment{}, fmt.Errorf("moderation: update comment: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return Comment{}, ErrCommentNotFound
	}
	return r.GetComment(ctx, id)
}

// SetCommentStatus implements Repository.
func (r *PostgresRepository) SetCommentStatus(ctx context.Context, id int64, status string) error {
	const upd = `UPDATE comments SET status = $2, updated_at = now() WHERE id = $1`
	ct, err := r.pool.Exec(ctx, upd, id, status)
	if err != nil {
		return fmt.Errorf("moderation: set comment status: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return ErrCommentNotFound
	}
	return nil
}

// GetCommentOwnership implements Repository.
func (r *PostgresRepository) GetCommentOwnership(ctx context.Context, id int64) (*int64, bool, error) {
	const q = `SELECT author_user_id FROM comments WHERE id = $1 AND status <> 'removed'`
	var author *int64
	err := r.pool.QueryRow(ctx, q, id).Scan(&author)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, false, nil
		}
		return nil, false, fmt.Errorf("moderation: get comment ownership: %w", err)
	}
	return author, true, nil
}

// CommentReportID implements Repository.
func (r *PostgresRepository) CommentReportID(ctx context.Context, id int64) (int64, bool, error) {
	const q = `SELECT report_id FROM comments WHERE id = $1`
	var reportID int64
	err := r.pool.QueryRow(ctx, q, id).Scan(&reportID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, false, nil
		}
		return 0, false, fmt.Errorf("moderation: comment report id: %w", err)
	}
	return reportID, true, nil
}

// ReportVisible implements Repository.
func (r *PostgresRepository) ReportVisible(ctx context.Context, id int64) (bool, error) {
	const q = `
		SELECT EXISTS (
			SELECT 1 FROM reports
			WHERE id = $1 AND deleted_at IS NULL
			  AND review_status NOT IN ('hidden', 'removed')
			  AND category_id IS NOT NULL
		)`
	var ok bool
	if err := r.pool.QueryRow(ctx, q, id).Scan(&ok); err != nil {
		return false, fmt.Errorf("moderation: report visible: %w", err)
	}
	return ok, nil
}

// ReportExists implements Repository.
func (r *PostgresRepository) ReportExists(ctx context.Context, id int64) (bool, error) {
	const q = `SELECT EXISTS (SELECT 1 FROM reports WHERE id = $1 AND deleted_at IS NULL)`
	var ok bool
	if err := r.pool.QueryRow(ctx, q, id).Scan(&ok); err != nil {
		return false, fmt.Errorf("moderation: report exists: %w", err)
	}
	return ok, nil
}

// CreateReportFlag implements Repository.
func (r *PostgresRepository) CreateReportFlag(ctx context.Context, reporterUserID, reportID int64, reason string, details *string) (Flag, error) {
	const ins = `
		INSERT INTO content_flags (reporter_user_id, report_id, comment_id, reason, details, status)
		VALUES ($1, $2, NULL, $3, $4, 'open')
		RETURNING id, reporter_user_id, report_id, comment_id, reason, details, status, created_at, resolved_at`
	return r.insertFlag(ctx, ins, reporterUserID, reportID, reason, details)
}

// CreateCommentFlag implements Repository.
func (r *PostgresRepository) CreateCommentFlag(ctx context.Context, reporterUserID, commentID int64, reason string, details *string) (Flag, error) {
	const ins = `
		INSERT INTO content_flags (reporter_user_id, report_id, comment_id, reason, details, status)
		VALUES ($1, NULL, $2, $3, $4, 'open')
		RETURNING id, reporter_user_id, report_id, comment_id, reason, details, status, created_at, resolved_at`
	return r.insertFlag(ctx, ins, reporterUserID, commentID, reason, details)
}

// insertFlag runs a flag insert statement (which takes reporter, target,
// reason, details in that order) and maps duplicates to ErrDuplicateFlag.
func (r *PostgresRepository) insertFlag(ctx context.Context, ins string, reporterUserID, targetID int64, reason string, details *string) (Flag, error) {
	var f Flag
	err := r.pool.QueryRow(ctx, ins, reporterUserID, targetID, reason, details).Scan(
		&f.ID, &f.ReporterUserID, &f.ReportID, &f.CommentID,
		&f.Reason, &f.Details, &f.Status, &f.CreatedAt, &f.ResolvedAt,
	)
	if err != nil {
		if isUniqueViolation(err) {
			return Flag{}, ErrDuplicateFlag
		}
		return Flag{}, fmt.Errorf("moderation: insert flag: %w", err)
	}
	return f, nil
}

// ListOpenFlags implements Repository. Excerpts are taken from the flagged
// target: redacted_text for reports, body for comments, truncated to 280 chars.
func (r *PostgresRepository) ListOpenFlags(ctx context.Context, limit int, cursor *Cursor) ([]QueueItem, error) {
	query := `
		SELECT
			f.id, f.reason, f.details, f.created_at,
			CASE WHEN f.report_id IS NOT NULL THEN 'post' ELSE 'comment' END AS target_type,
			COALESCE(f.report_id, f.comment_id) AS target_id,
			COALESCE(left(r.redacted_text, 280), left(cm.body, 280), '') AS excerpt
		FROM content_flags f
		LEFT JOIN reports r ON r.id = f.report_id
		LEFT JOIN comments cm ON cm.id = f.comment_id
		WHERE f.status = 'open'`
	args := []any{}
	if cursor != nil {
		args = append(args, cursor.CreatedAt, cursor.ID)
		query += fmt.Sprintf("\n\t\tAND (f.created_at, f.id) > ($%d, $%d)", len(args)-1, len(args))
	}
	args = append(args, limit)
	query += fmt.Sprintf("\n\t\tORDER BY f.created_at ASC, f.id ASC\n\t\tLIMIT $%d", len(args))

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("moderation: query queue: %w", err)
	}
	defer rows.Close()

	var out []QueueItem
	for rows.Next() {
		var q QueueItem
		if err := rows.Scan(
			&q.FlagID, &q.Reason, &q.Details, &q.CreatedAt,
			&q.TargetType, &q.TargetID, &q.Excerpt,
		); err != nil {
			return nil, fmt.Errorf("moderation: scan queue item: %w", err)
		}
		out = append(out, q)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("moderation: iterate queue: %w", err)
	}
	return out, nil
}

// ReviewReport implements Repository.
func (r *PostgresRepository) ReviewReport(ctx context.Context, reportID, moderatorUserID int64, decision, reviewStatus string, rationale *string, suggestionID *int64) (Decision, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return Decision{}, fmt.Errorf("moderation: begin review tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	const upd = `UPDATE reports SET review_status = $2, updated_at = now() WHERE id = $1 AND deleted_at IS NULL`
	ct, err := tx.Exec(ctx, upd, reportID, reviewStatus)
	if err != nil {
		return Decision{}, fmt.Errorf("moderation: update report status: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return Decision{}, ErrReportNotFound
	}

	const insDec = `
		INSERT INTO moderation_decisions (report_id, comment_id, moderator_user_id, decision, rationale, suggestion_id)
		VALUES ($1, NULL, $2, $3, $4, $5)
		RETURNING id, report_id, comment_id, moderator_user_id, decision, rationale, suggestion_id, created_at`
	d, err := scanDecision(tx.QueryRow(ctx, insDec, reportID, moderatorUserID, decision, rationale, suggestionID))
	if err != nil {
		return Decision{}, fmt.Errorf("moderation: insert report decision: %w", err)
	}

	const resolve = `UPDATE content_flags SET status = 'resolved', resolved_at = now() WHERE report_id = $1 AND status = 'open'`
	if _, err := tx.Exec(ctx, resolve, reportID); err != nil {
		return Decision{}, fmt.Errorf("moderation: resolve report flags: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return Decision{}, fmt.Errorf("moderation: commit review tx: %w", err)
	}
	return d, nil
}

// ReviewComment implements Repository.
func (r *PostgresRepository) ReviewComment(ctx context.Context, commentID, moderatorUserID int64, decision, commentStatus string, rationale *string) (Decision, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return Decision{}, fmt.Errorf("moderation: begin review tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	// commentStatus is empty for a plain "reviewed" decision that leaves the
	// comment visible; only touch the row when a new status is requested.
	if commentStatus != "" {
		const upd = `UPDATE comments SET status = $2, updated_at = now() WHERE id = $1`
		ct, err := tx.Exec(ctx, upd, commentID, commentStatus)
		if err != nil {
			return Decision{}, fmt.Errorf("moderation: update comment status: %w", err)
		}
		if ct.RowsAffected() == 0 {
			return Decision{}, ErrCommentNotFound
		}
	} else {
		var exists bool
		if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM comments WHERE id = $1)`, commentID).Scan(&exists); err != nil {
			return Decision{}, fmt.Errorf("moderation: check comment exists: %w", err)
		}
		if !exists {
			return Decision{}, ErrCommentNotFound
		}
	}

	const insDec = `
		INSERT INTO moderation_decisions (report_id, comment_id, moderator_user_id, decision, rationale, suggestion_id)
		VALUES (NULL, $1, $2, $3, $4, NULL)
		RETURNING id, report_id, comment_id, moderator_user_id, decision, rationale, suggestion_id, created_at`
	d, err := scanDecision(tx.QueryRow(ctx, insDec, commentID, moderatorUserID, decision, rationale))
	if err != nil {
		return Decision{}, fmt.Errorf("moderation: insert comment decision: %w", err)
	}

	const resolve = `UPDATE content_flags SET status = 'resolved', resolved_at = now() WHERE comment_id = $1 AND status = 'open'`
	if _, err := tx.Exec(ctx, resolve, commentID); err != nil {
		return Decision{}, fmt.Errorf("moderation: resolve comment flags: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return Decision{}, fmt.Errorf("moderation: commit review tx: %w", err)
	}
	return d, nil
}

// scanDecision scans a moderation_decisions returning row.
func scanDecision(row pgx.Row) (Decision, error) {
	var d Decision
	err := row.Scan(
		&d.ID, &d.ReportID, &d.CommentID, &d.ModeratorUserID,
		&d.Decision, &d.Rationale, &d.SuggestionID, &d.CreatedAt,
	)
	return d, err
}
