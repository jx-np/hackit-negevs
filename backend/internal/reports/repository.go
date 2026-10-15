package reports

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// FeedQuery describes a feed/search page request. Zero-valued optional filters
// are ignored.
type FeedQuery struct {
	// CategorySlug filters by categories.slug when non-empty.
	CategorySlug string
	// TagSlug filters by tags.slug when non-empty.
	TagSlug string
	// Search is a full-text query string; empty means no text filter.
	Search string
	// Limit is the number of rows to fetch (the caller adds +1 to detect more).
	Limit int
	// Cursor is nil for the first page.
	Cursor *Cursor
}

// CreateReportParams carries the fields to insert a reports row.
type CreateReportParams struct {
	AuthorUserID  int64
	SourceCheckID *int64
	// CategoryID is nil when the post is still unclassified by the classifier.
	CategoryID   *int64
	Title        string
	RedactedText string
	SourceLocale string
	TagIDs       []int64
	// RedactedImageKey is the storage key of the post's own redacted image
	// copy, or nil when the post has no image.
	RedactedImageKey *string
}

// UpdateReportParams carries the mutable fields of a report edit. Nil pointers
// leave the corresponding column unchanged. When Tags is non-nil the tag set is
// fully replaced (an empty non-nil slice clears all tags).
type UpdateReportParams struct {
	Title        *string
	RedactedText *string
	Tags         *[]int64
	// ResetReview forces review_status back to 'unverified' (used when sensitive
	// content changed).
	ResetReview bool
}

// Repository is the persistence contract for the reports domain.
type Repository interface {
	// ListFeed returns a page of feed cards matching q, ordered by
	// (created_at, id) descending, excluding deleted/hidden/removed rows.
	// requesterUserID scopes the per-card IsMine flag; nil for anonymous.
	ListFeed(ctx context.Context, q FeedQuery, requesterUserID *int64) ([]ReportCard, error)
	// ListByAuthor returns a page of an author's own reports in any status
	// (excluding soft-deleted rows), ordered by (created_at, id) descending.
	ListByAuthor(ctx context.Context, authorUserID int64, limit int, cursor *Cursor) ([]ReportCard, error)

	// GetReportDetail returns a full report with counts and requester-scoped
	// fields. includeHidden controls whether hidden/removed/deleted rows are
	// returned (true for privileged callers). Returns ErrReportNotFound if the
	// row is absent or excluded.
	GetReportDetail(ctx context.Context, id int64, requesterUserID *int64, includeHidden bool) (Report, error)

	// GetCategoryBySlug resolves a category slug to its row. Returns
	// ErrUnknownCategory if absent.
	GetCategoryBySlug(ctx context.Context, slug string) (Category, error)
	// ListCategories returns all categories ordered by slug.
	ListCategories(ctx context.Context) ([]Category, error)
	// ListTags returns tags optionally filtered by a slug/name_key substring.
	ListTags(ctx context.Context, q string, limit int) ([]Tag, error)
	// ResolveTagSlugs maps slugs to tag rows. Any slug without a match is
	// returned in the unknown slice; found tags are returned in order of input.
	ResolveTagSlugs(ctx context.Context, slugs []string) (found []Tag, unknown []string, err error)

	// CreateReport inserts a report and links its tags in one transaction,
	// returning the new report id.
	CreateReport(ctx context.Context, p CreateReportParams) (int64, error)
	// UpdateReport applies mutable fields and (optionally) replaces tags. Returns
	// ErrReportNotFound if the row is absent or soft-deleted.
	UpdateReport(ctx context.Context, id int64, p UpdateReportParams) error
	// SoftDeleteReport sets deleted_at=now(). Returns ErrReportNotFound if the
	// row is absent or already deleted.
	SoftDeleteReport(ctx context.Context, id int64) error
	// GetReportOwnership returns the author id and whether the report exists and
	// is not soft-deleted, for authorization checks.
	GetReportOwnership(ctx context.Context, id int64) (authorUserID *int64, exists bool, err error)
	// CheckOwnedBy reports whether the given check exists and is owned by the
	// user. Used to validate source_check_id linkage.
	CheckOwnedBy(ctx context.Context, checkID, userID int64) (bool, error)
	// RedactedImageKeyForCheck returns the redacted image storage key of the
	// most recent upload linked to a check that the user owns, if any. ok is
	// false when the user does not own the check, the check has no linked
	// upload, or the upload has no redacted image yet. Used at publish time to
	// locate the source blob to copy into the post's own image.
	RedactedImageKeyForCheck(ctx context.Context, checkID, ownerUserID int64) (key string, ok bool, err error)
	// GetReportImageKey returns the post's redacted image storage key when the
	// post exists and is publicly visible (not deleted/hidden/removed and
	// classified). ok is false when the post is not publicly visible or has no
	// image. Used by the public post-image serve route.
	GetReportImageKey(ctx context.Context, id int64) (key string, ok bool, err error)

	// SetReaction upserts a vote and returns the resulting up/down counts.
	SetReaction(ctx context.Context, reportID, userID int64, vote int16) (up, down int64, err error)
	// RemoveReaction deletes a vote and returns the resulting up/down counts.
	RemoveReaction(ctx context.Context, reportID, userID int64) (up, down int64, err error)

	// ReportVisible reports whether a report exists and is publicly visible
	// (not deleted/hidden/removed). Used to guard reactions.
	ReportVisible(ctx context.Context, id int64) (bool, error)
}

// PostgresRepository is a pgx-backed Repository.
type PostgresRepository struct {
	pool *pgxpool.Pool
}

// NewPostgresRepository constructs a PostgresRepository.
func NewPostgresRepository(pool *pgxpool.Pool) *PostgresRepository {
	return &PostgresRepository{pool: pool}
}

// cardSelectSQL is the shared card projection. comment_count is a derived
// scalar subquery counting only visible comments. is_mine compares the row's
// author against the requester bound to $1 (0 for anonymous callers never
// matches a real author id, so is_mine is false). categories is LEFT JOINed
// because a post stays unclassified until the classifier assigns a category;
// its columns are therefore nullable.
const cardSelectSQL = `
	SELECT
		r.id, r.title, left(r.redacted_text, 280) AS excerpt,
		r.review_status, r.created_at,
		c.id, c.slug, c.name_key, c.description_key,
		(SELECT count(*) FROM comments cm WHERE cm.report_id = r.id AND cm.status = 'visible') AS comment_count,
		(SELECT count(*) FROM report_reactions rx WHERE rx.report_id = r.id AND rx.vote = 1) AS up_count,
		(SELECT count(*) FROM report_reactions rx WHERE rx.report_id = r.id AND rx.vote = -1) AS down_count,
		COALESCE(r.author_user_id = $1, false) AS is_mine,
		COALESCE((SELECT rx.vote FROM report_reactions rx WHERE rx.report_id = r.id AND rx.user_id = $1), 0) AS my_vote
	FROM reports r
	LEFT JOIN categories c ON c.id = r.category_id`

// classifiedOrMine restricts a query to rows other users may see: classified
// posts, plus the requester's own still-unclassified posts. placeholder is the
// bind parameter holding the requester id (0 for anonymous, which matches no
// author row).
func classifiedOrMine(placeholder string) string {
	return fmt.Sprintf("(r.category_id IS NOT NULL OR r.author_user_id = %s)", placeholder)
}

// requesterOrZero returns *id or 0 for scoping my_vote in the detail query.
func requesterOrZero(id *int64) int64 {
	if id == nil {
		return 0
	}
	return *id
}

// categoryFromRow builds a Category from a LEFT JOINed categories row, returning
// nil when the row is absent (post not yet classified).
func categoryFromRow(id *int64, slug, nameKey, descriptionKey *string) *Category {
	if id == nil || slug == nil || nameKey == nil {
		return nil
	}
	return &Category{
		ID:             *id,
		Slug:           *slug,
		NameKey:        *nameKey,
		DescriptionKey: descriptionKey,
	}
}

// ListFeed implements Repository.
func (r *PostgresRepository) ListFeed(ctx context.Context, q FeedQuery, requesterUserID *int64) ([]ReportCard, error) {
	var sb strings.Builder
	sb.WriteString(cardSelectSQL)

	// $1 is always the requester id (scopes is_mine); nil for anonymous.
	args := []any{requesterUserID}

	if q.TagSlug != "" {
		// Join through report_tags to a specific tag slug.
		sb.WriteString("\n\tJOIN report_tags rt ON rt.report_id = r.id")
		sb.WriteString("\n\tJOIN tags t ON t.id = rt.tag_id")
	}

	sb.WriteString("\n\tWHERE r.deleted_at IS NULL AND r.review_status NOT IN ('hidden', 'removed')")
	fmt.Fprintf(&sb, "\n\tAND %s", classifiedOrMine("$1"))

	if q.CategorySlug != "" {
		args = append(args, q.CategorySlug)
		fmt.Fprintf(&sb, "\n\tAND c.slug = $%d", len(args))
	}
	if q.TagSlug != "" {
		args = append(args, q.TagSlug)
		fmt.Fprintf(&sb, "\n\tAND t.slug = $%d", len(args))
	}
	if q.Search != "" {
		args = append(args, q.Search)
		n := len(args)
		fmt.Fprintf(&sb, "\n\tAND to_tsvector('simple', r.title || ' ' || r.redacted_text) @@ plainto_tsquery('simple', $%d)", n)
	}
	if q.Cursor != nil {
		args = append(args, q.Cursor.CreatedAt, q.Cursor.ID)
		fmt.Fprintf(&sb, "\n\tAND (r.created_at, r.id) < ($%d, $%d)", len(args)-1, len(args))
	}

	args = append(args, q.Limit)
	fmt.Fprintf(&sb, "\n\tORDER BY r.created_at DESC, r.id DESC\n\tLIMIT $%d", len(args))

	return r.queryCards(ctx, sb.String(), args)
}

// ListByAuthor implements Repository.
func (r *PostgresRepository) ListByAuthor(ctx context.Context, authorUserID int64, limit int, cursor *Cursor) ([]ReportCard, error) {
	var sb strings.Builder
	sb.WriteString(cardSelectSQL)
	args := []any{authorUserID}

	sb.WriteString("\n\tWHERE r.deleted_at IS NULL AND r.author_user_id = $1")

	if cursor != nil {
		args = append(args, cursor.CreatedAt, cursor.ID)
		fmt.Fprintf(&sb, "\n\tAND (r.created_at, r.id) < ($%d, $%d)", len(args)-1, len(args))
	}
	args = append(args, limit)
	fmt.Fprintf(&sb, "\n\tORDER BY r.created_at DESC, r.id DESC\n\tLIMIT $%d", len(args))

	return r.queryCards(ctx, sb.String(), args)
}

// queryCards runs a card projection query and hydrates tags for each row.
func (r *PostgresRepository) queryCards(ctx context.Context, query string, args []any) ([]ReportCard, error) {
	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("reports: query feed: %w", err)
	}
	defer rows.Close()

	var (
		cards []ReportCard
		ids   []int64
	)
	for rows.Next() {
		var (
			card                      ReportCard
			catID                     *int64
			catSlug, catName, catDesc *string
		)
		if err := rows.Scan(
			&card.ID, &card.Title, &card.Excerpt,
			&card.ReviewStatus, &card.CreatedAt,
			&catID, &catSlug, &catName, &catDesc,
			&card.CommentCount, &card.UpCount, &card.DownCount, &card.IsMine, &card.MyVote,
		); err != nil {
			return nil, fmt.Errorf("reports: scan feed row: %w", err)
		}
		card.Category = categoryFromRow(catID, catSlug, catName, catDesc)
		cards = append(cards, card)
		ids = append(ids, card.ID)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("reports: iterate feed rows: %w", err)
	}

	if len(cards) == 0 {
		return cards, nil
	}

	tagsByReport, err := r.tagsForReports(ctx, ids)
	if err != nil {
		return nil, err
	}
	topByReport, err := r.topCommentsForReports(ctx, ids, feedTopCommentsPerPost)
	if err != nil {
		return nil, err
	}
	for i := range cards {
		cards[i].Tags = tagsByReport[cards[i].ID]
		cards[i].TopComments = topByReport[cards[i].ID]
	}
	return cards, nil
}

// feedTopCommentsPerPost is how many preview comments each feed card carries.
const feedTopCommentsPerPost = 3

// topCommentsForReports fetches up to perPost top-level visible comments for
// each report in one query, ranked by activity (direct reply count) then
// recency, and groups them by report id. Only top-level comments
// (parent_comment_id IS NULL) are considered for the preview.
func (r *PostgresRepository) topCommentsForReports(ctx context.Context, reportIDs []int64, perPost int) (map[int64][]TopComment, error) {
	const q = `
		SELECT report_id, id, author_label, body, reply_count, created_at
		FROM (
			SELECT
				cm.report_id,
				cm.id,
				COALESCE(u.display_name, 'removed user') AS author_label,
				cm.body,
				(SELECT count(*) FROM comments ch
				 WHERE ch.parent_comment_id = cm.id AND ch.status = 'visible') AS reply_count,
				cm.created_at,
				row_number() OVER (
					PARTITION BY cm.report_id
					ORDER BY (SELECT count(*) FROM comments ch
					          WHERE ch.parent_comment_id = cm.id AND ch.status = 'visible') DESC,
					         cm.created_at DESC, cm.id DESC
				) AS rn
			FROM comments cm
			LEFT JOIN users u ON u.id = cm.author_user_id
			WHERE cm.report_id = ANY($1)
			  AND cm.status = 'visible'
			  AND cm.parent_comment_id IS NULL
		) ranked
		WHERE ranked.rn <= $2
		ORDER BY report_id, rn`
	rows, err := r.pool.Query(ctx, q, reportIDs, perPost)
	if err != nil {
		return nil, fmt.Errorf("reports: query top comments: %w", err)
	}
	defer rows.Close()

	out := make(map[int64][]TopComment)
	for rows.Next() {
		var (
			reportID int64
			c        TopComment
		)
		if err := rows.Scan(&reportID, &c.ID, &c.AuthorLabel, &c.Body, &c.ReplyCount, &c.CreatedAt); err != nil {
			return nil, fmt.Errorf("reports: scan top comment: %w", err)
		}
		out[reportID] = append(out[reportID], c)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("reports: iterate top comments: %w", err)
	}
	return out, nil
}

// tagsForReports fetches tags for a set of report ids in a single query and
// groups them by report id.
func (r *PostgresRepository) tagsForReports(ctx context.Context, reportIDs []int64) (map[int64][]Tag, error) {
	const q = `
		SELECT rt.report_id, t.id, t.slug, t.name_key
		FROM report_tags rt
		JOIN tags t ON t.id = rt.tag_id
		WHERE rt.report_id = ANY($1)
		ORDER BY t.slug`
	rows, err := r.pool.Query(ctx, q, reportIDs)
	if err != nil {
		return nil, fmt.Errorf("reports: query tags: %w", err)
	}
	defer rows.Close()

	out := make(map[int64][]Tag)
	for rows.Next() {
		var (
			reportID int64
			t        Tag
		)
		if err := rows.Scan(&reportID, &t.ID, &t.Slug, &t.NameKey); err != nil {
			return nil, fmt.Errorf("reports: scan tag row: %w", err)
		}
		out[reportID] = append(out[reportID], t)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("reports: iterate tag rows: %w", err)
	}
	return out, nil
}

// GetReportDetail implements Repository.
func (r *PostgresRepository) GetReportDetail(ctx context.Context, id int64, requesterUserID *int64, includeHidden bool) (Report, error) {
	requester := requesterOrZero(requesterUserID)

	var sb strings.Builder
	sb.WriteString(`
		SELECT
			r.id, r.author_user_id, r.source_check_id, r.category_id,
			r.title, r.redacted_text, r.source_locale, r.review_status,
			r.publication_confirmed_at, r.created_at, r.updated_at, r.deleted_at,
			r.redacted_image_key,
			c.id, c.slug, c.name_key, c.description_key,
			(SELECT count(*) FROM comments cm WHERE cm.report_id = r.id AND cm.status = 'visible'),
			(SELECT count(*) FROM report_reactions rx WHERE rx.report_id = r.id AND rx.vote = 1),
			(SELECT count(*) FROM report_reactions rx WHERE rx.report_id = r.id AND rx.vote = -1),
			COALESCE((SELECT rx.vote FROM report_reactions rx WHERE rx.report_id = r.id AND rx.user_id = $2), 0)
		FROM reports r
		LEFT JOIN categories c ON c.id = r.category_id
		WHERE r.id = $1`)

	if !includeHidden {
		sb.WriteString("\n\t\t\tAND r.deleted_at IS NULL AND r.review_status NOT IN ('hidden', 'removed')")
		// Unclassified posts are author-only; privileged (moderator) callers use
		// includeHidden and see them. $2 holds the requester id here.
		fmt.Fprintf(&sb, "\n\t\t\tAND %s", classifiedOrMine("$2"))
	}

	var (
		rep                       Report
		catID                     *int64
		catSlug, catName, catDesc *string
	)
	err := r.pool.QueryRow(ctx, sb.String(), id, requester).Scan(
		&rep.ID, &rep.AuthorUserID, &rep.SourceCheckID, &rep.CategoryID,
		&rep.Title, &rep.RedactedText, &rep.SourceLocale, &rep.ReviewStatus,
		&rep.PublicationConfirmedAt, &rep.CreatedAt, &rep.UpdatedAt, &rep.DeletedAt,
		&rep.RedactedImageKey,
		&catID, &catSlug, &catName, &catDesc,
		&rep.CommentCount, &rep.UpCount, &rep.DownCount, &rep.MyVote,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Report{}, ErrReportNotFound
		}
		return Report{}, fmt.Errorf("reports: get report detail: %w", err)
	}
	rep.Category = categoryFromRow(catID, catSlug, catName, catDesc)

	tagsByReport, err := r.tagsForReports(ctx, []int64{rep.ID})
	if err != nil {
		return Report{}, err
	}
	rep.Tags = tagsByReport[rep.ID]
	return rep, nil
}

// GetCategoryBySlug implements Repository.
func (r *PostgresRepository) GetCategoryBySlug(ctx context.Context, slug string) (Category, error) {
	const q = `SELECT id, slug, name_key, description_key FROM categories WHERE slug = $1`
	var c Category
	err := r.pool.QueryRow(ctx, q, slug).Scan(&c.ID, &c.Slug, &c.NameKey, &c.DescriptionKey)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Category{}, ErrUnknownCategory
		}
		return Category{}, fmt.Errorf("reports: get category: %w", err)
	}
	return c, nil
}

// ListCategories implements Repository.
func (r *PostgresRepository) ListCategories(ctx context.Context) ([]Category, error) {
	const q = `SELECT id, slug, name_key, description_key FROM categories ORDER BY slug`
	rows, err := r.pool.Query(ctx, q)
	if err != nil {
		return nil, fmt.Errorf("reports: list categories: %w", err)
	}
	defer rows.Close()

	var out []Category
	for rows.Next() {
		var c Category
		if err := rows.Scan(&c.ID, &c.Slug, &c.NameKey, &c.DescriptionKey); err != nil {
			return nil, fmt.Errorf("reports: scan category: %w", err)
		}
		out = append(out, c)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("reports: iterate categories: %w", err)
	}
	return out, nil
}

// ListTags implements Repository.
func (r *PostgresRepository) ListTags(ctx context.Context, q string, limit int) ([]Tag, error) {
	var rows pgx.Rows
	var err error
	if q == "" {
		const query = `SELECT id, slug, name_key FROM tags ORDER BY slug LIMIT $1`
		rows, err = r.pool.Query(ctx, query, limit)
	} else {
		const query = `
			SELECT id, slug, name_key FROM tags
			WHERE slug ILIKE '%' || $1 || '%' OR name_key ILIKE '%' || $1 || '%'
			ORDER BY slug
			LIMIT $2`
		rows, err = r.pool.Query(ctx, query, q, limit)
	}
	if err != nil {
		return nil, fmt.Errorf("reports: list tags: %w", err)
	}
	defer rows.Close()

	var out []Tag
	for rows.Next() {
		var t Tag
		if err := rows.Scan(&t.ID, &t.Slug, &t.NameKey); err != nil {
			return nil, fmt.Errorf("reports: scan tag: %w", err)
		}
		out = append(out, t)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("reports: iterate tags: %w", err)
	}
	return out, nil
}

// ResolveTagSlugs implements Repository.
func (r *PostgresRepository) ResolveTagSlugs(ctx context.Context, slugs []string) ([]Tag, []string, error) {
	if len(slugs) == 0 {
		return nil, nil, nil
	}
	const q = `SELECT id, slug, name_key FROM tags WHERE slug = ANY($1)`
	rows, err := r.pool.Query(ctx, q, slugs)
	if err != nil {
		return nil, nil, fmt.Errorf("reports: resolve tags: %w", err)
	}
	defer rows.Close()

	bySlug := make(map[string]Tag)
	for rows.Next() {
		var t Tag
		if err := rows.Scan(&t.ID, &t.Slug, &t.NameKey); err != nil {
			return nil, nil, fmt.Errorf("reports: scan resolved tag: %w", err)
		}
		bySlug[t.Slug] = t
	}
	if err := rows.Err(); err != nil {
		return nil, nil, fmt.Errorf("reports: iterate resolved tags: %w", err)
	}

	var (
		found   []Tag
		unknown []string
	)
	seen := make(map[string]struct{}, len(slugs))
	for _, s := range slugs {
		if _, dup := seen[s]; dup {
			continue
		}
		seen[s] = struct{}{}
		if t, ok := bySlug[s]; ok {
			found = append(found, t)
		} else {
			unknown = append(unknown, s)
		}
	}
	return found, unknown, nil
}

// CreateReport implements Repository.
func (r *PostgresRepository) CreateReport(ctx context.Context, p CreateReportParams) (int64, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return 0, fmt.Errorf("reports: begin create tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	const ins = `
		INSERT INTO reports (author_user_id, source_check_id, category_id, title, redacted_text, source_locale, redacted_image_key, review_status, publication_confirmed_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, 'unverified', now())
		RETURNING id`
	var id int64
	if err := tx.QueryRow(ctx, ins,
		p.AuthorUserID, p.SourceCheckID, p.CategoryID, p.Title, p.RedactedText, p.SourceLocale, p.RedactedImageKey,
	).Scan(&id); err != nil {
		return 0, fmt.Errorf("reports: insert report: %w", err)
	}

	if err := insertReportTags(ctx, tx, id, p.TagIDs); err != nil {
		return 0, err
	}

	if err := tx.Commit(ctx); err != nil {
		return 0, fmt.Errorf("reports: commit create tx: %w", err)
	}
	return id, nil
}

// insertReportTags links a report to a set of tag ids inside tx.
func insertReportTags(ctx context.Context, tx pgx.Tx, reportID int64, tagIDs []int64) error {
	for _, tagID := range tagIDs {
		const q = `INSERT INTO report_tags (report_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`
		if _, err := tx.Exec(ctx, q, reportID, tagID); err != nil {
			return fmt.Errorf("reports: link tag: %w", err)
		}
	}
	return nil
}

// UpdateReport implements Repository.
func (r *PostgresRepository) UpdateReport(ctx context.Context, id int64, p UpdateReportParams) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("reports: begin update tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	// Build a dynamic SET list. updated_at is always bumped.
	var (
		sets []string
		args []any
	)
	if p.Title != nil {
		args = append(args, *p.Title)
		sets = append(sets, fmt.Sprintf("title = $%d", len(args)))
	}
	if p.RedactedText != nil {
		args = append(args, *p.RedactedText)
		sets = append(sets, fmt.Sprintf("redacted_text = $%d", len(args)))
	}
	if p.ResetReview {
		sets = append(sets, "review_status = 'unverified'")
	}
	sets = append(sets, "updated_at = now()")

	args = append(args, id)
	query := fmt.Sprintf(
		"UPDATE reports SET %s WHERE id = $%d AND deleted_at IS NULL",
		strings.Join(sets, ", "), len(args),
	)
	ct, err := tx.Exec(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("reports: update report: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return ErrReportNotFound
	}

	if p.Tags != nil {
		const del = `DELETE FROM report_tags WHERE report_id = $1`
		if _, err := tx.Exec(ctx, del, id); err != nil {
			return fmt.Errorf("reports: clear tags: %w", err)
		}
		if err := insertReportTags(ctx, tx, id, *p.Tags); err != nil {
			return err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("reports: commit update tx: %w", err)
	}
	return nil
}

// SoftDeleteReport implements Repository.
func (r *PostgresRepository) SoftDeleteReport(ctx context.Context, id int64) error {
	const q = `UPDATE reports SET deleted_at = now(), updated_at = now() WHERE id = $1 AND deleted_at IS NULL`
	ct, err := r.pool.Exec(ctx, q, id)
	if err != nil {
		return fmt.Errorf("reports: soft delete: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return ErrReportNotFound
	}
	return nil
}

// GetReportOwnership implements Repository.
func (r *PostgresRepository) GetReportOwnership(ctx context.Context, id int64) (*int64, bool, error) {
	const q = `SELECT author_user_id FROM reports WHERE id = $1 AND deleted_at IS NULL`
	var author *int64
	err := r.pool.QueryRow(ctx, q, id).Scan(&author)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, false, nil
		}
		return nil, false, fmt.Errorf("reports: get ownership: %w", err)
	}
	return author, true, nil
}

// CheckOwnedBy implements Repository.
func (r *PostgresRepository) CheckOwnedBy(ctx context.Context, checkID, userID int64) (bool, error) {
	const q = `SELECT EXISTS (SELECT 1 FROM private_checks WHERE id = $1 AND owner_user_id = $2)`
	var ok bool
	if err := r.pool.QueryRow(ctx, q, checkID, userID).Scan(&ok); err != nil {
		return false, fmt.Errorf("reports: check ownership: %w", err)
	}
	return ok, nil
}

// RedactedImageKeyForCheck implements Repository. It returns the redacted image
// storage key of a check owned by the given user, if one exists. The owner scope
// guards against attaching another user's upload to a post.
func (r *PostgresRepository) RedactedImageKeyForCheck(ctx context.Context, checkID, ownerUserID int64) (string, bool, error) {
	const q = `
		SELECT u.redacted_storage_key
		FROM private_uploads u
		JOIN private_checks c ON c.id = u.check_id
		WHERE u.check_id = $1
		  AND c.owner_user_id = $2
		  AND u.redacted_storage_key IS NOT NULL
		ORDER BY u.created_at DESC
		LIMIT 1`
	var key *string
	err := r.pool.QueryRow(ctx, q, checkID, ownerUserID).Scan(&key)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", false, nil
		}
		return "", false, fmt.Errorf("reports: redacted image key for check: %w", err)
	}
	if key == nil || *key == "" {
		return "", false, nil
	}
	return *key, true, nil
}

// GetReportImageKey implements Repository. It returns the post's redacted image
// storage key only when the post is publicly visible, mirroring ReportVisible.
func (r *PostgresRepository) GetReportImageKey(ctx context.Context, id int64) (string, bool, error) {
	const q = `
		SELECT redacted_image_key
		FROM reports
		WHERE id = $1
		  AND deleted_at IS NULL
		  AND review_status NOT IN ('hidden', 'removed')
		  AND category_id IS NOT NULL
		  AND redacted_image_key IS NOT NULL`
	var key *string
	err := r.pool.QueryRow(ctx, q, id).Scan(&key)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", false, nil
		}
		return "", false, fmt.Errorf("reports: get report image key: %w", err)
	}
	if key == nil || *key == "" {
		return "", false, nil
	}
	return *key, true, nil
}

// SetReaction implements Repository.
func (r *PostgresRepository) SetReaction(ctx context.Context, reportID, userID int64, vote int16) (int64, int64, error) {
	const q = `
		INSERT INTO report_reactions (user_id, report_id, vote)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, report_id) DO UPDATE SET vote = EXCLUDED.vote, updated_at = now()`
	if _, err := r.pool.Exec(ctx, q, userID, reportID, vote); err != nil {
		return 0, 0, fmt.Errorf("reports: set reaction: %w", err)
	}
	return r.reactionCounts(ctx, reportID)
}

// RemoveReaction implements Repository.
func (r *PostgresRepository) RemoveReaction(ctx context.Context, reportID, userID int64) (int64, int64, error) {
	const q = `DELETE FROM report_reactions WHERE user_id = $1 AND report_id = $2`
	if _, err := r.pool.Exec(ctx, q, userID, reportID); err != nil {
		return 0, 0, fmt.Errorf("reports: remove reaction: %w", err)
	}
	return r.reactionCounts(ctx, reportID)
}

func (r *PostgresRepository) reactionCounts(ctx context.Context, reportID int64) (int64, int64, error) {
	const q = `
		SELECT
			count(*) FILTER (WHERE vote = 1),
			count(*) FILTER (WHERE vote = -1)
		FROM report_reactions WHERE report_id = $1`
	var up, down int64
	if err := r.pool.QueryRow(ctx, q, reportID).Scan(&up, &down); err != nil {
		return 0, 0, fmt.Errorf("reports: count reactions: %w", err)
	}
	return up, down, nil
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
		return false, fmt.Errorf("reports: report visible: %w", err)
	}
	return ok, nil
}
