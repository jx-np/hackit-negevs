package reports

import (
	"context"
	"encoding/base64"
	"errors"
	"io"
	"strconv"
	"strings"
	"time"

	"scamshield/internal/auth"
	"scamshield/internal/classifier"
	"scamshield/internal/storage"
)

// Pagination and content bounds.
const (
	defaultListLimit = 20
	maxListLimit     = 100

	// defaultTagLimit / maxTagLimit bound the tag lookup endpoint.
	defaultTagLimit = 50
	maxTagLimit     = 100

	// defaultLocale is used when a report omits a source locale.
	defaultLocale = "en-SG"

	// postImageStoragePrefix groups the post-owned redacted image copies in the
	// blob store, kept separate from the private check uploads/redacted objects.
	postImageStoragePrefix = "post-images"
)

// Service holds reports business logic. It is transport-agnostic.
type Service struct {
	repo       Repository
	classifier classifier.Classifier
	store      storage.Store
	now        func() time.Time
}

// NewService constructs a reports Service. The classifier assigns the scam
// category on publish; pass nil to disable classification (every post then
// stays unclassified and author-only). The store holds the post's own redacted
// image copy; pass nil to disable image attachment (posts then publish without
// an image).
func NewService(repo Repository, cl classifier.Classifier, store storage.Store) *Service {
	return &Service{repo: repo, classifier: cl, store: store, now: time.Now}
}

// Page is a page of feed/author cards with an opaque next cursor.
type Page struct {
	Items      []ReportCard
	NextCursor string
}

// FeedInput carries a feed listing request.
type FeedInput struct {
	Sort         string
	CategorySlug string
	TagSlug      string
	RawCursor    string
	Limit        int
	// RequesterUserID scopes the per-card IsMine flag; nil for anonymous.
	RequesterUserID *int64
}

// SearchInput carries a feed search request.
type SearchInput struct {
	Query        string
	CategorySlug string
	RawCursor    string
	Limit        int
	// RequesterUserID scopes the per-card IsMine flag; nil for anonymous.
	RequesterUserID *int64
}

// Feed returns a page of public feed cards. An unparseable cursor is rejected
// with ErrInvalidCursor so clients get a clear 400 rather than silently
// restarting at the first page.
func (s *Service) Feed(ctx context.Context, in FeedInput) (Page, error) {
	limit := clampLimit(in.Limit)
	cursor, err := parseCursor(in.RawCursor)
	if err != nil {
		return Page{}, err
	}

	items, err := s.repo.ListFeed(ctx, FeedQuery{
		CategorySlug: strings.TrimSpace(in.CategorySlug),
		TagSlug:      strings.TrimSpace(in.TagSlug),
		Limit:        limit + 1,
		Cursor:       cursor,
	}, in.RequesterUserID)
	if err != nil {
		return Page{}, err
	}
	return paginate(items, limit), nil
}

// Search returns a page of cards matching a full-text query. An empty query
// falls back to a plain recent listing (the repository's search predicate is
// simply omitted).
func (s *Service) Search(ctx context.Context, in SearchInput) (Page, error) {
	limit := clampLimit(in.Limit)
	cursor, err := parseCursor(in.RawCursor)
	if err != nil {
		return Page{}, err
	}

	items, err := s.repo.ListFeed(ctx, FeedQuery{
		Search:       strings.TrimSpace(in.Query),
		CategorySlug: strings.TrimSpace(in.CategorySlug),
		Limit:        limit + 1,
		Cursor:       cursor,
	}, in.RequesterUserID)
	if err != nil {
		return Page{}, err
	}
	return paginate(items, limit), nil
}

// ListMyReports returns the author's own reports in any status.
func (s *Service) ListMyReports(ctx context.Context, authorUserID int64, limit int, rawCursor string) (Page, error) {
	limit = clampLimit(limit)
	cursor, err := parseCursor(rawCursor)
	if err != nil {
		return Page{}, err
	}

	items, err := s.repo.ListByAuthor(ctx, authorUserID, limit+1, cursor)
	if err != nil {
		return Page{}, err
	}
	return paginate(items, limit), nil
}

// GetReport returns a report detail for the requester. Non-privileged callers
// cannot see deleted/hidden/removed reports (resolved as ErrReportNotFound).
func (s *Service) GetReport(ctx context.Context, id int64, requester *auth.Principal) (Report, error) {
	includeHidden := isPrivileged(requester)
	var requesterID *int64
	if requester != nil {
		uid := requester.UserID
		requesterID = &uid
	}
	return s.repo.GetReportDetail(ctx, id, requesterID, includeHidden)
}

// ListCategories returns all scam-type categories.
func (s *Service) ListCategories(ctx context.Context) ([]Category, error) {
	return s.repo.ListCategories(ctx)
}

// ListTags returns tags filtered by an optional query substring.
func (s *Service) ListTags(ctx context.Context, q string, limit int) ([]Tag, error) {
	if limit <= 0 {
		limit = defaultTagLimit
	}
	if limit > maxTagLimit {
		limit = maxTagLimit
	}
	return s.repo.ListTags(ctx, strings.TrimSpace(q), limit)
}

// CreateInput carries a publish request. The scam category and tags are
// assigned by the classifier, never by the client.
type CreateInput struct {
	AuthorUserID int64
	CheckID      *int64
	Title        string
	RedactedText string
	// UploadIDs are the caller's own uploads whose PII redaction has completed.
	// Each is resolved owner-scoped and its redacted image is copied into a
	// fresh, post-owned object. An upload that is not owned by the caller or
	// whose redaction has not finished is rejected with ErrUploadNotUsable.
	UploadIDs          []int64
	ConfirmPublication bool
	SourceLocale       string
}

// Create publishes a new report. It enforces explicit confirmation, re-scrubs
// the body server-side, asks the classifier for the scam category and tags, and
// links a source check only when the caller owns it. When classification fails
// or yields no category the post is still created but stays unclassified, i.e.
// visible only to its author until it is classified.
func (s *Service) Create(ctx context.Context, in CreateInput) (Report, error) {
	if !in.ConfirmPublication {
		return Report{}, ErrConfirmationRequired
	}

	title := strings.TrimSpace(in.Title)
	if title == "" {
		return Report{}, ErrTitleRequired
	}

	// Server-side re-scrub: never trust the client's redaction.
	body := strings.TrimSpace(Scrub(in.RedactedText))
	if body == "" {
		return Report{}, ErrBodyRequired
	}

	locale := normalizeLocale(in.SourceLocale)

	// Classification runs on the scrubbed body only and yields both the scam
	// category and the post's tags. Failure is not fatal: the post is stored
	// unclassified/untagged and hidden from other users.
	categoryID, tagIDs := s.classify(ctx, body, locale)

	// Only link the source check when the caller actually owns it; otherwise
	// store NULL rather than leaking a reference to another user's check.
	var sourceCheckID *int64
	if in.CheckID != nil {
		owned, err := s.repo.CheckOwnedBy(ctx, *in.CheckID, in.AuthorUserID)
		if err != nil {
			return Report{}, err
		}
		if owned {
			sourceCheckID = in.CheckID
		}
	}

	// Resolve and copy each referenced upload's redacted image into a fresh,
	// post-owned object so the published post keeps its images even after the
	// private uploads expire. Each upload must be owned by the author and have a
	// completed redaction; otherwise the publish is rejected. Only the redacted
	// derivative is ever copied; the raw upload is never read.
	images, err := s.copyUploadImages(ctx, in.UploadIDs, in.AuthorUserID)
	if err != nil {
		return Report{}, err
	}

	id, err := s.repo.CreateReport(ctx, CreateReportParams{
		AuthorUserID:  in.AuthorUserID,
		SourceCheckID: sourceCheckID,
		CategoryID:    categoryID,
		Title:         title,
		RedactedText:  body,
		SourceLocale:  locale,
		TagIDs:        tagIDs,
		Images:        images,
	})
	if err != nil {
		// Clean up the post-owned image copies we just created; the report row
		// (and its would-be report_images rows) never persisted.
		s.cleanupImages(ctx, images)
		return Report{}, err
	}

	requesterID := in.AuthorUserID
	return s.repo.GetReportDetail(ctx, id, &requesterID, true)
}

// classify asks the classifier for a category and tags and resolves both to
// internal ids. The category is nil when there is no classifier, when the
// classifier fails, or when the predicted slug does not exist — in all of those
// cases the post remains unclassified rather than the publish failing. Predicted
// tags that are unknown or blank are silently dropped. Only the scrubbed text is
// passed on, and no result is logged.
func (s *Service) classify(ctx context.Context, scrubbedBody, locale string) (*int64, []int64) {
	if s.classifier == nil {
		return nil, nil
	}
	res, err := s.classifier.Classify(ctx, scrubbedBody, locale)
	if err != nil {
		return nil, nil
	}

	var categoryID *int64
	if res.Classified() {
		if cat, err := s.repo.GetCategoryBySlug(ctx, res.Slug); err == nil {
			categoryID = &cat.ID
		}
		// An unknown predicted slug leaves the post unclassified.
	}

	return categoryID, s.resolvePredictedTags(ctx, res.Tags)
}

// resolvePredictedTags maps classifier-predicted tag slugs to tag ids. Unlike
// client-supplied tags, an unknown, blank, or duplicate slug is silently dropped
// rather than failing the publish: a bad prediction must never block a post.
func (s *Service) resolvePredictedTags(ctx context.Context, slugs []string) []int64 {
	cleaned := make([]string, 0, len(slugs))
	seen := make(map[string]bool, len(slugs))
	for _, sl := range slugs {
		sl = strings.TrimSpace(sl)
		if sl == "" || seen[sl] {
			continue
		}
		seen[sl] = true
		cleaned = append(cleaned, sl)
	}
	if len(cleaned) == 0 {
		return nil
	}

	found, _, err := s.repo.ResolveTagSlugs(ctx, cleaned)
	if err != nil {
		return nil
	}
	ids := make([]int64, 0, len(found))
	for _, t := range found {
		ids = append(ids, t.ID)
	}
	return ids
}

// copyUploadImages resolves each referenced upload to its redacted image and
// copies it into a fresh, post-owned storage object. Every upload must be owned
// by the author and have a completed redaction (status 'ready' with a redacted
// copy); any upload that is missing, not owned, or not yet redacted causes the
// whole publish to be rejected with ErrUploadNotUsable. Only the redacted
// derivative is ever copied; the raw upload is never read. On any failure the
// copies already made in this call are cleaned up before returning the error,
// so no orphan post-image objects are left behind.
func (s *Service) copyUploadImages(ctx context.Context, uploadIDs []int64, ownerUserID int64) ([]ReportImageParam, error) {
	if len(uploadIDs) == 0 {
		return nil, nil
	}
	// An image attachment was requested but there is nowhere to copy it to.
	if s.store == nil {
		return nil, ErrUploadNotUsable
	}

	images := make([]ReportImageParam, 0, len(uploadIDs))
	for _, uploadID := range uploadIDs {
		srcKey, mediaType, ok, err := s.repo.RedactedImageForUpload(ctx, uploadID, ownerUserID)
		if err != nil {
			s.cleanupImages(ctx, images)
			return nil, err
		}
		if !ok {
			// Not owned, nonexistent, or redaction not finished: reject.
			s.cleanupImages(ctx, images)
			return nil, ErrUploadNotUsable
		}
		newKey, err := s.copyRedactedBlob(ctx, srcKey, mediaType)
		if err != nil {
			s.cleanupImages(ctx, images)
			return nil, err
		}
		images = append(images, ReportImageParam{StorageKey: newKey, MediaType: mediaType})
	}
	return images, nil
}

// copyRedactedBlob copies an already-redacted blob into a fresh, post-owned
// storage object and returns the new key. The media type is carried over from
// the source upload. Only the redacted derivative is read; the raw upload is
// never touched.
func (s *Service) copyRedactedBlob(ctx context.Context, srcKey, mediaType string) (string, error) {
	obj, err := s.store.Get(ctx, srcKey)
	if err != nil {
		return "", err
	}
	defer obj.Body.Close()
	return s.store.Put(ctx, postImageStoragePrefix, mediaType, obj.Body)
}

// cleanupImages best-effort deletes post-owned image copies. Used to roll back
// partially-copied images when a publish fails after some copies succeeded.
func (s *Service) cleanupImages(ctx context.Context, images []ReportImageParam) {
	if s.store == nil {
		return
	}
	for _, img := range images {
		_ = s.store.Delete(ctx, img.StorageKey)
	}
}

// PostImage is a published post's redacted image ready to stream to a client.
// The caller must close Body.
type PostImage struct {
	Body      io.ReadCloser
	MediaType string
	Size      int64
}

// OpenPostImageAt opens one of a publicly visible post's redacted images by its
// 0-based display position for streaming. Missing posts, posts that are not
// publicly visible, and out-of-range positions all resolve to ErrReportNotFound
// so the route never reveals which posts exist or how many images they carry.
// Only the redacted copy is served; the raw upload is never read.
func (s *Service) OpenPostImageAt(ctx context.Context, reportID int64, position int) (PostImage, error) {
	if s.store == nil {
		return PostImage{}, ErrReportNotFound
	}
	if position < 0 {
		return PostImage{}, ErrReportNotFound
	}
	images, err := s.repo.ListReportImages(ctx, reportID)
	if err != nil {
		return PostImage{}, err
	}
	// ListReportImages already enforces public visibility, so an empty result
	// means the post is not visible or has no images: not found either way.
	var match *ReportImage
	for i := range images {
		if images[i].Position == position {
			match = &images[i]
			break
		}
	}
	if match == nil {
		return PostImage{}, ErrReportNotFound
	}
	obj, err := s.store.Get(ctx, match.StorageKey)
	if err != nil {
		if errors.Is(err, storage.ErrNotFound) {
			return PostImage{}, ErrReportNotFound
		}
		return PostImage{}, err
	}
	// The content type comes from the database (report_images.media_type);
	// the store persists bytes only.
	return PostImage{Body: obj.Body, MediaType: match.MediaType, Size: obj.Size}, nil
}

// UpdateInput carries an edit request. Nil pointers leave a field unchanged.
type UpdateInput struct {
	ReportID     int64
	Requester    auth.Principal
	Title        *string
	RedactedText *string
}

// Update edits a report. Only the author or a moderator/admin may edit. When
// redacted_text changes it is re-scrubbed and the report re-enters moderation
// (review_status reset to unverified).
func (s *Service) Update(ctx context.Context, in UpdateInput) (Report, error) {
	author, exists, err := s.repo.GetReportOwnership(ctx, in.ReportID)
	if err != nil {
		return Report{}, err
	}
	if !exists {
		return Report{}, ErrReportNotFound
	}
	if !canMutate(author, in.Requester) {
		return Report{}, ErrForbidden
	}

	params := UpdateReportParams{}

	if in.Title != nil {
		title := strings.TrimSpace(*in.Title)
		if title == "" {
			return Report{}, ErrTitleRequired
		}
		params.Title = &title
	}

	if in.RedactedText != nil {
		body := strings.TrimSpace(Scrub(*in.RedactedText))
		if body == "" {
			return Report{}, ErrBodyRequired
		}
		params.RedactedText = &body
		// Sensitive content changed: re-enter moderation.
		params.ResetReview = true
	}

	if err := s.repo.UpdateReport(ctx, in.ReportID, params); err != nil {
		return Report{}, err
	}

	requesterID := in.Requester.UserID
	return s.repo.GetReportDetail(ctx, in.ReportID, &requesterID, true)
}

// Delete soft-deletes a report. Only the author or a moderator/admin may delete.
func (s *Service) Delete(ctx context.Context, reportID int64, requester auth.Principal) error {
	author, exists, err := s.repo.GetReportOwnership(ctx, reportID)
	if err != nil {
		return err
	}
	if !exists {
		return ErrReportNotFound
	}
	if !canMutate(author, requester) {
		return ErrForbidden
	}
	return s.repo.SoftDeleteReport(ctx, reportID)
}

// ReactionResult is the response to a reaction change.
type ReactionResult struct {
	UpCount   int64
	DownCount int64
	MyVote    int16
}

// SetReaction upserts the user's vote (1 or -1).
func (s *Service) SetReaction(ctx context.Context, reportID, userID int64, vote int16) (ReactionResult, error) {
	if vote != 1 && vote != -1 {
		return ReactionResult{}, ErrInvalidVote
	}
	if err := s.ensureVisible(ctx, reportID); err != nil {
		return ReactionResult{}, err
	}
	up, down, err := s.repo.SetReaction(ctx, reportID, userID, vote)
	if err != nil {
		return ReactionResult{}, err
	}
	return ReactionResult{UpCount: up, DownCount: down, MyVote: vote}, nil
}

// RemoveReaction removes the user's vote.
func (s *Service) RemoveReaction(ctx context.Context, reportID, userID int64) (ReactionResult, error) {
	if err := s.ensureVisible(ctx, reportID); err != nil {
		return ReactionResult{}, err
	}
	up, down, err := s.repo.RemoveReaction(ctx, reportID, userID)
	if err != nil {
		return ReactionResult{}, err
	}
	return ReactionResult{UpCount: up, DownCount: down, MyVote: 0}, nil
}

// ensureVisible returns ErrReportNotFound unless the report is publicly visible.
func (s *Service) ensureVisible(ctx context.Context, reportID int64) error {
	ok, err := s.repo.ReportVisible(ctx, reportID)
	if err != nil {
		return err
	}
	if !ok {
		return ErrReportNotFound
	}
	return nil
}

// --- helpers ---

// isPrivileged reports whether the principal may view moderated-away content.
func isPrivileged(p *auth.Principal) bool {
	if p == nil {
		return false
	}
	return p.Role == auth.RoleModerator || p.Role == auth.RoleAdmin
}

// canMutate reports whether the requester may edit/delete a report authored by
// author. The author themselves, or a moderator/admin, may mutate.
func canMutate(author *int64, requester auth.Principal) bool {
	if author != nil && *author == requester.UserID {
		return true
	}
	return requester.Role == auth.RoleModerator || requester.Role == auth.RoleAdmin
}

func normalizeLocale(locale string) string {
	l := strings.TrimSpace(locale)
	if l == "" {
		return defaultLocale
	}
	return l
}

func clampLimit(limit int) int {
	if limit <= 0 {
		return defaultListLimit
	}
	if limit > maxListLimit {
		return maxListLimit
	}
	return limit
}

// paginate trims an over-fetched slice to limit and computes the next cursor.
func paginate(items []ReportCard, limit int) Page {
	var next string
	if len(items) > limit {
		last := items[limit-1]
		next = encodeCursor(Cursor{CreatedAt: last.CreatedAt, ID: last.ID})
		items = items[:limit]
	}
	return Page{Items: items, NextCursor: next}
}

// Cursor encoding: base64url of "createdAtUnixNanos:id". Opaque to clients.
func encodeCursor(c Cursor) string {
	raw := strconv.FormatInt(c.CreatedAt.UTC().UnixNano(), 10) + ":" + strconv.FormatInt(c.ID, 10)
	return base64.RawURLEncoding.EncodeToString([]byte(raw))
}

// parseCursor decodes an opaque next_cursor. An empty string yields (nil, nil);
// a malformed value yields ErrInvalidCursor.
func parseCursor(s string) (*Cursor, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, nil
	}
	b, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return nil, ErrInvalidCursor
	}
	parts := strings.SplitN(string(b), ":", 2)
	if len(parts) != 2 {
		return nil, ErrInvalidCursor
	}
	nanos, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return nil, ErrInvalidCursor
	}
	id, err := strconv.ParseInt(parts[1], 10, 64)
	if err != nil {
		return nil, ErrInvalidCursor
	}
	return &Cursor{CreatedAt: time.Unix(0, nanos).UTC(), ID: id}, nil
}
