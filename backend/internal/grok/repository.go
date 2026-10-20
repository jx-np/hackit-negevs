package grok

import (
	"context"
	"errors"
	"fmt"

	"scamshield/internal/moderation"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// removedUserLabel mirrors moderation's fallback label for a comment whose
// author row has been cleared (author_user_id IS NULL). Author identity is never
// exposed beyond a display label.
const removedUserLabel = "removed user"

// CommentSummary is a compact view of a public comment used as model context.
type CommentSummary struct {
	AuthorLabel string
	Body        string
}

// PostContext is the publicly visible post data given to the model. It carries
// the post title, the server-scrubbed redacted text and the assigned category
// slug (empty when the post has no resolvable category). The title is only
// trimmed, not scrubbed, at publish time, so callers must scrub it themselves
// before it reaches the model.
type PostContext struct {
	Title        string
	RedactedText string
	CategorySlug string
}

// ImageRef points at one of a public post's already-published PII-redacted
// images (a report_images row). The raw upload it was derived from is never
// referenced or read.
type ImageRef struct {
	StorageKey string
	MediaType  string
	Position   int
}

// BotReply is a request to insert a bot-authored reply comment.
type BotReply struct {
	ReportID     int64
	AuthorUserID int64
	// ParentCommentID keeps replies one level deep: the triggering comment id
	// when the trigger is top-level, otherwise the trigger's parent.
	ParentCommentID *int64
	// TriggerCommentID is the comment that mentioned the bot. The insert only
	// happens while it is still visible.
	TriggerCommentID int64
	Body             string
}

// Repository is the persistence contract for the bot. It is deliberately small
// so the service is unit-testable with a fake.
type Repository interface {
	// BotUserID returns the id of the seeded bot user. found is false when no
	// bot user exists; the bot never creates one.
	BotUserID(ctx context.Context) (id int64, found bool, err error)
	// PostContext returns the public context for a post, using the same
	// "publicly visible" predicate as the moderation domain. found is false when
	// the post is missing or no longer publicly visible.
	PostContext(ctx context.Context, reportID int64) (PostContext, bool, error)
	// PostImages returns the post's published PII-redacted images in display
	// order, using the same "publicly visible" predicate. Only report_images
	// rows are returned; raw uploads are never touched.
	PostImages(ctx context.Context, reportID int64) ([]ImageRef, error)
	// RecentComments returns up to limit of a post's most recent visible
	// comments in chronological order, author label joined.
	RecentComments(ctx context.Context, reportID int64, limit int) ([]CommentSummary, error)
	// InsertBotReply inserts a visible bot comment, but only when the post is
	// still publicly visible and the triggering comment is still visible.
	// inserted is false when either guard fails.
	InsertBotReply(ctx context.Context, r BotReply) (id int64, inserted bool, err error)
	// GetComment returns a stored, non-removed comment with its author label,
	// used to hydrate the terminal reply event. Returns the moderation
	// not-found error when the comment is absent or removed.
	GetComment(ctx context.Context, id int64) (moderation.Comment, error)
}

// PostgresRepository is a pgx-backed Repository.
type PostgresRepository struct {
	pool *pgxpool.Pool
}

// NewPostgresRepository constructs a PostgresRepository.
func NewPostgresRepository(pool *pgxpool.Pool) *PostgresRepository {
	return &PostgresRepository{pool: pool}
}

// BotUserID implements Repository.
func (r *PostgresRepository) BotUserID(ctx context.Context) (int64, bool, error) {
	const q = `SELECT id FROM users WHERE is_bot ORDER BY id LIMIT 1`
	var id int64
	err := r.pool.QueryRow(ctx, q).Scan(&id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, false, nil
		}
		return 0, false, fmt.Errorf("grok: lookup bot user: %w", err)
	}
	return id, true, nil
}

// PostContext implements Repository. The visibility predicate matches
// moderation.PostgresRepository.ReportVisible exactly: not deleted, not hidden
// or removed, and classified (category_id IS NOT NULL). Unclassified posts are
// author- and moderator-only, so the bot must not read them.
func (r *PostgresRepository) PostContext(ctx context.Context, reportID int64) (PostContext, bool, error) {
	const q = `
		SELECT r.title, r.redacted_text, COALESCE(c.slug, '')
		FROM reports r
		LEFT JOIN categories c ON c.id = r.category_id
		WHERE r.id = $1 AND r.deleted_at IS NULL
		  AND r.review_status NOT IN ('hidden', 'removed')
		  AND r.category_id IS NOT NULL`
	var p PostContext
	err := r.pool.QueryRow(ctx, q, reportID).Scan(&p.Title, &p.RedactedText, &p.CategorySlug)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return PostContext{}, false, nil
		}
		return PostContext{}, false, fmt.Errorf("grok: load post context: %w", err)
	}
	return p, true, nil
}

// PostImages implements Repository. The visibility predicate matches
// reports.PostgresRepository.ListReportImages exactly: only images belonging to
// a post that is not deleted/hidden/removed and is classified are returned,
// ordered by display position. Only the PII-redacted derivatives stored in
// report_images are ever read; private_uploads and raw uploads are never
// referenced.
func (r *PostgresRepository) PostImages(ctx context.Context, reportID int64) ([]ImageRef, error) {
	const q = `
		SELECT ri.storage_key, ri.media_type, ri.position
		FROM report_images ri
		JOIN reports r ON r.id = ri.report_id
		WHERE ri.report_id = $1
		  AND r.deleted_at IS NULL
		  AND r.review_status NOT IN ('hidden', 'removed')
		  AND r.category_id IS NOT NULL
		ORDER BY ri.position, ri.id`
	rows, err := r.pool.Query(ctx, q, reportID)
	if err != nil {
		return nil, fmt.Errorf("grok: list post images: %w", err)
	}
	defer rows.Close()

	var out []ImageRef
	for rows.Next() {
		var ref ImageRef
		if err := rows.Scan(&ref.StorageKey, &ref.MediaType, &ref.Position); err != nil {
			return nil, fmt.Errorf("grok: scan post image: %w", err)
		}
		out = append(out, ref)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("grok: iterate post images: %w", err)
	}
	return out, nil
}

// RecentComments implements Repository. It picks the newest `limit` visible
// comments and returns them oldest-first so the prompt reads chronologically.
func (r *PostgresRepository) RecentComments(ctx context.Context, reportID int64, limit int) ([]CommentSummary, error) {
	if limit <= 0 {
		return nil, nil
	}
	const q = `
		SELECT COALESCE(u.display_name, $2) AS author_label, cm.body
		FROM comments cm
		LEFT JOIN users u ON u.id = cm.author_user_id
		WHERE cm.id IN (
			SELECT id FROM comments
			WHERE report_id = $1 AND status = 'visible'
			ORDER BY created_at DESC, id DESC
			LIMIT $3
		)
		ORDER BY cm.created_at ASC, cm.id ASC`
	rows, err := r.pool.Query(ctx, q, reportID, removedUserLabel, limit)
	if err != nil {
		return nil, fmt.Errorf("grok: query recent comments: %w", err)
	}
	defer rows.Close()

	var out []CommentSummary
	for rows.Next() {
		var c CommentSummary
		if err := rows.Scan(&c.AuthorLabel, &c.Body); err != nil {
			return nil, fmt.Errorf("grok: scan recent comment: %w", err)
		}
		out = append(out, c)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("grok: iterate recent comments: %w", err)
	}
	return out, nil
}

// InsertBotReply implements Repository. The insert is a single INSERT ... SELECT
// guarded by two EXISTS checks so it is atomic with the visibility test: either
// both the post and the triggering comment are still visible and the row is
// written, or no row is written at all.
func (r *PostgresRepository) InsertBotReply(ctx context.Context, br BotReply) (int64, bool, error) {
	const ins = `
		INSERT INTO comments (report_id, author_user_id, parent_comment_id, body, status)
		SELECT $1, $2, $3, $4, 'visible'
		WHERE EXISTS (
			SELECT 1 FROM reports r
			WHERE r.id = $1 AND r.deleted_at IS NULL
			  AND r.review_status NOT IN ('hidden', 'removed')
			  AND r.category_id IS NOT NULL
		)
		AND EXISTS (
			SELECT 1 FROM comments tc
			WHERE tc.id = $5 AND tc.report_id = $1 AND tc.status = 'visible'
		)
		RETURNING id`
	var id int64
	err := r.pool.QueryRow(ctx, ins,
		br.ReportID, br.AuthorUserID, br.ParentCommentID, br.Body, br.TriggerCommentID,
	).Scan(&id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, false, nil
		}
		return 0, false, fmt.Errorf("grok: insert bot reply: %w", err)
	}
	return id, true, nil
}

// GetComment implements Repository. It mirrors the moderation domain's comment
// projection (display label joined, is_bot flag) so the SSE event carries the
// exact shape the comments endpoint returns. Email and other identity fields are
// never selected.
func (r *PostgresRepository) GetComment(ctx context.Context, id int64) (moderation.Comment, error) {
	const q = `
		SELECT
			cm.id, cm.report_id, cm.author_user_id, cm.parent_comment_id,
			COALESCE(u.display_name, $2) AS author_label,
			COALESCE(u.is_bot, false) AS is_bot,
			cm.body, cm.status, cm.created_at, cm.updated_at
		FROM comments cm
		LEFT JOIN users u ON u.id = cm.author_user_id
		WHERE cm.id = $1 AND cm.status <> 'removed'`
	var c moderation.Comment
	err := r.pool.QueryRow(ctx, q, id, removedUserLabel).Scan(
		&c.ID, &c.ReportID, &c.AuthorUserID, &c.ParentCommentID,
		&c.AuthorLabel, &c.IsBot, &c.Body, &c.Status, &c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return moderation.Comment{}, moderation.ErrCommentNotFound
		}
		return moderation.Comment{}, fmt.Errorf("grok: get comment: %w", err)
	}
	return c, nil
}
