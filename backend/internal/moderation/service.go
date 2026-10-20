package moderation

import (
	"context"
	"encoding/base64"
	"strconv"
	"strings"
	"sync"
	"time"

	"scamshield/internal/auth"
	"scamshield/internal/reports"
)

// Pagination bounds.
const (
	defaultListLimit = 20
	maxListLimit     = 100

	// defaultCommentLimit is the page size for listing a post's comments when
	// the client does not specify one.
	defaultCommentLimit = 10
)

// Service holds moderation/discussion business logic. It is transport-agnostic.
type Service struct {
	repo Repository

	// mu guards observer, which is normally set once at startup.
	mu       sync.RWMutex
	observer CommentObserver
}

// NewService constructs a moderation Service.
func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// SetCommentObserver registers an observer that is notified after every
// comment is created (the @help bot uses this to answer @help mentions).
//
// It is normally called once, during startup. Passing nil removes the
// observer, which is always safe. Observers must not block: they are called
// from the request path.
func (s *Service) SetCommentObserver(o CommentObserver) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.observer = o
}

// commentObserver returns the registered observer, or nil when none is set.
func (s *Service) commentObserver() CommentObserver {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.observer
}

// CommentPage is a page of comments with an opaque next cursor.
type CommentPage struct {
	Items      []Comment
	NextCursor string
}

// QueuePage is a page of moderation-queue items with an opaque next cursor.
type QueuePage struct {
	Items      []QueueItem
	NextCursor string
}

// ListComments returns a page of visible comments for a publicly visible report.
func (s *Service) ListComments(ctx context.Context, reportID int64, limit int, rawCursor string) (CommentPage, error) {
	visible, err := s.repo.ReportVisible(ctx, reportID)
	if err != nil {
		return CommentPage{}, err
	}
	if !visible {
		return CommentPage{}, ErrReportNotFound
	}

	limit = clampCommentLimit(limit)
	cursor, err := parseCursor(rawCursor)
	if err != nil {
		return CommentPage{}, err
	}

	items, err := s.repo.ListComments(ctx, reportID, limit+1, cursor)
	if err != nil {
		return CommentPage{}, err
	}

	var next string
	if len(items) > limit {
		last := items[limit-1]
		next = encodeCursor(Cursor{CreatedAt: last.CreatedAt, ID: last.ID})
		items = items[:limit]
	}
	return CommentPage{Items: items, NextCursor: next}, nil
}

// CreateCommentInput carries a comment-post request.
type CreateCommentInput struct {
	ReportID     int64
	AuthorUserID int64
	Body         string
	ParentID     *int64
}

// CreateComment posts a comment on a visible report. The body is re-scrubbed
// server-side. A parent, when supplied, must belong to the same report.
//
// After the comment is stored, the registered observer (if any) is notified so
// that features like the @help bot can react to it. The observer is only
// called for a stored comment, and it must not block.
func (s *Service) CreateComment(ctx context.Context, in CreateCommentInput) (Comment, error) {
	visible, err := s.repo.ReportVisible(ctx, in.ReportID)
	if err != nil {
		return Comment{}, err
	}
	if !visible {
		return Comment{}, ErrReportNotFound
	}

	body := strings.TrimSpace(reports.Scrub(in.Body))
	if body == "" {
		return Comment{}, ErrBodyRequired
	}

	if in.ParentID != nil {
		parentReportID, exists, err := s.repo.CommentReportID(ctx, *in.ParentID)
		if err != nil {
			return Comment{}, err
		}
		if !exists || parentReportID != in.ReportID {
			return Comment{}, ErrInvalidParent
		}
	}

	c, err := s.repo.CreateComment(ctx, CreateCommentParams{
		ReportID:        in.ReportID,
		AuthorUserID:    in.AuthorUserID,
		ParentCommentID: in.ParentID,
		Body:            body,
	})
	if err != nil {
		return Comment{}, err
	}

	if o := s.commentObserver(); o != nil {
		o.CommentCreated(c)
	}
	return c, nil
}

// UpdateComment edits a comment's body. Only the author may edit; the body is
// re-scrubbed.
func (s *Service) UpdateComment(ctx context.Context, commentID int64, requester auth.Principal, rawBody string) (Comment, error) {
	author, exists, err := s.repo.GetCommentOwnership(ctx, commentID)
	if err != nil {
		return Comment{}, err
	}
	if !exists {
		return Comment{}, ErrCommentNotFound
	}
	if author == nil || *author != requester.UserID {
		return Comment{}, ErrForbidden
	}

	body := strings.TrimSpace(reports.Scrub(rawBody))
	if body == "" {
		return Comment{}, ErrBodyRequired
	}
	return s.repo.UpdateCommentBody(ctx, commentID, body)
}

// DeleteComment soft-deletes a comment (status='removed'). The author or a
// moderator/admin may delete.
func (s *Service) DeleteComment(ctx context.Context, commentID int64, requester auth.Principal) error {
	author, exists, err := s.repo.GetCommentOwnership(ctx, commentID)
	if err != nil {
		return err
	}
	if !exists {
		return ErrCommentNotFound
	}
	if !canModerate(author, requester) {
		return ErrForbidden
	}
	return s.repo.SetCommentStatus(ctx, commentID, CommentRemoved)
}

// FlagReport raises a flag against a report.
func (s *Service) FlagReport(ctx context.Context, reporterUserID, reportID int64, reason string, details *string) (Flag, error) {
	if !validReason(reason) {
		return Flag{}, ErrInvalidReason
	}
	visible, err := s.repo.ReportVisible(ctx, reportID)
	if err != nil {
		return Flag{}, err
	}
	if !visible {
		return Flag{}, ErrReportNotFound
	}
	return s.repo.CreateReportFlag(ctx, reporterUserID, reportID, reason, trimDetails(details))
}

// FlagComment raises a flag against a comment.
func (s *Service) FlagComment(ctx context.Context, reporterUserID, commentID int64, reason string, details *string) (Flag, error) {
	if !validReason(reason) {
		return Flag{}, ErrInvalidReason
	}
	if _, err := s.repo.GetComment(ctx, commentID); err != nil {
		return Flag{}, err
	}
	return s.repo.CreateCommentFlag(ctx, reporterUserID, commentID, reason, trimDetails(details))
}

// Queue returns a page of open flags oldest-first.
func (s *Service) Queue(ctx context.Context, limit int, rawCursor string) (QueuePage, error) {
	limit = clampLimit(limit)
	cursor, err := parseCursor(rawCursor)
	if err != nil {
		return QueuePage{}, err
	}
	items, err := s.repo.ListOpenFlags(ctx, limit+1, cursor)
	if err != nil {
		return QueuePage{}, err
	}
	var next string
	if len(items) > limit {
		last := items[limit-1]
		next = encodeCursor(Cursor{CreatedAt: last.CreatedAt, ID: last.FlagID})
		items = items[:limit]
	}
	return QueuePage{Items: items, NextCursor: next}, nil
}

// ReviewReportInput carries a report review request.
type ReviewReportInput struct {
	ReportID        int64
	ModeratorUserID int64
	Decision        string
	Rationale       *string
	SuggestionID    *int64
}

// reportReviewStatus maps a decision to the reports.review_status side effect.
func reportReviewStatus(decision string) (string, bool) {
	switch decision {
	case DecisionReviewed:
		return reports.ReviewReviewed, true
	case DecisionDisputed:
		return reports.ReviewDisputed, true
	case DecisionHide:
		return reports.ReviewHidden, true
	case DecisionRemove:
		return reports.ReviewRemoved, true
	case DecisionRestore:
		return reports.ReviewUnverified, true
	default:
		return "", false
	}
}

// ReviewReport applies a moderator decision to a report.
func (s *Service) ReviewReport(ctx context.Context, in ReviewReportInput) (Decision, error) {
	status, ok := reportReviewStatus(in.Decision)
	if !ok {
		return Decision{}, ErrInvalidDecision
	}
	exists, err := s.repo.ReportExists(ctx, in.ReportID)
	if err != nil {
		return Decision{}, err
	}
	if !exists {
		return Decision{}, ErrReportNotFound
	}
	return s.repo.ReviewReport(ctx, in.ReportID, in.ModeratorUserID, in.Decision, status, trimDetails(in.Rationale), in.SuggestionID)
}

// ReviewCommentInput carries a comment review request.
type ReviewCommentInput struct {
	CommentID       int64
	ModeratorUserID int64
	Decision        string
	Rationale       *string
}

// commentReviewStatus maps a decision to the comments.status side effect. The
// bool ok is false for a decision that is not meaningful for a comment.
// An empty status means "no visible change" (the plain reviewed decision).
func commentReviewStatus(decision string) (status string, ok bool) {
	switch decision {
	case DecisionReviewed:
		return "", true
	case DecisionHide:
		return CommentHidden, true
	case DecisionRemove:
		return CommentRemoved, true
	case DecisionRestore:
		return CommentVisible, true
	default:
		// 'disputed' (and anything else) is not meaningful for a comment.
		return "", false
	}
}

// ReviewComment applies a moderator decision to a comment.
func (s *Service) ReviewComment(ctx context.Context, in ReviewCommentInput) (Decision, error) {
	status, ok := commentReviewStatus(in.Decision)
	if !ok {
		return Decision{}, ErrInvalidDecision
	}
	return s.repo.ReviewComment(ctx, in.CommentID, in.ModeratorUserID, in.Decision, status, trimDetails(in.Rationale))
}

// --- helpers ---

// canModerate reports whether requester may hide/remove a comment authored by
// author: the author themselves, or a moderator/admin.
func canModerate(author *int64, requester auth.Principal) bool {
	if author != nil && *author == requester.UserID {
		return true
	}
	return requester.Role == auth.RoleModerator || requester.Role == auth.RoleAdmin
}

// trimDetails trims whitespace on an optional details/rationale string and
// collapses an empty result to nil so blank strings are stored as NULL.
func trimDetails(s *string) *string {
	if s == nil {
		return nil
	}
	t := strings.TrimSpace(*s)
	if t == "" {
		return nil
	}
	return &t
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

// clampCommentLimit applies the comment-listing default (10) when unspecified,
// capped at maxListLimit.
func clampCommentLimit(limit int) int {
	if limit <= 0 {
		return defaultCommentLimit
	}
	if limit > maxListLimit {
		return maxListLimit
	}
	return limit
}

// Cursor encoding: base64url of "createdAtUnixNanos:id". Opaque to clients.
func encodeCursor(c Cursor) string {
	raw := strconv.FormatInt(c.CreatedAt.UTC().UnixNano(), 10) + ":" + strconv.FormatInt(c.ID, 10)
	return base64.RawURLEncoding.EncodeToString([]byte(raw))
}

// parseCursor decodes an opaque cursor. An empty string yields (nil, nil); a
// malformed value yields ErrInvalidCursor.
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
