// Package moderation implements the discussion and safety/moderation domain.
// It owns comments (one-level replies on reports), content flags raised by
// residents against reports or comments, and the moderator queue and review
// actions that resolve those flags and adjust report/comment visibility.
//
// These concerns live together because they share the comments, reports and
// content_flags tables: a moderator working the queue needs to hide/remove the
// very comments this package creates, and flags target either a report or a
// comment. As with the rest of the API, bigint ids are serialized as strings,
// comment bodies are server-side scrubbed before persistence, and author
// identity is never exposed beyond a display label.
package moderation

import (
	"errors"
	"strconv"
	"time"
)

// Comment status values. Mirrors the comments.status CHECK constraint.
const (
	CommentVisible = "visible"
	CommentHidden  = "hidden"
	CommentRemoved = "removed"
)

// Content flag reasons. Mirrors the content_flags.reason CHECK constraint.
const (
	ReasonPersonalInformation = "personal_information"
	ReasonHarmful             = "harmful"
	ReasonSpam                = "spam"
	ReasonMisinformation      = "misinformation"
	ReasonOther               = "other"
)

// Content flag status values. Mirrors the content_flags.status CHECK constraint.
const (
	FlagOpen      = "open"
	FlagResolved  = "resolved"
	FlagDismissed = "dismissed"
)

// Moderation decision values. Mirrors the moderation_decisions.decision CHECK
// constraint.
const (
	DecisionReviewed = "reviewed"
	DecisionDisputed = "disputed"
	DecisionHide     = "hide"
	DecisionRemove   = "remove"
	DecisionRestore  = "restore"
)

// Flag target kinds used in the moderation queue projection. "post" matches the
// public API term for a community submission (internally a report row).
const (
	TargetPost    = "post"
	TargetComment = "comment"
)

// validReasons is the set of accepted flag reasons.
var validReasons = map[string]struct{}{
	ReasonPersonalInformation: {},
	ReasonHarmful:             {},
	ReasonSpam:                {},
	ReasonMisinformation:      {},
	ReasonOther:               {},
}

// validReason reports whether reason is an accepted content_flags.reason value.
func validReason(reason string) bool {
	_, ok := validReasons[reason]
	return ok
}

// Domain errors surfaced by the service layer and mapped to HTTP statuses by
// the handler.
var (
	// ErrReportNotFound is returned when the target report is absent or not
	// publicly visible.
	ErrReportNotFound = errors.New("moderation: report not found")
	// ErrCommentNotFound is returned when a comment lookup yields no row, or the
	// comment has been removed.
	ErrCommentNotFound = errors.New("moderation: comment not found")
	// ErrForbidden is returned when the requester may not mutate a comment they
	// do not own and are not a moderator/admin for.
	ErrForbidden = errors.New("moderation: forbidden")
	// ErrBodyRequired is returned when a comment body is empty after scrubbing.
	ErrBodyRequired = errors.New("moderation: body is required")
	// ErrInvalidParent is returned when a supplied parent comment does not belong
	// to the same report (or does not exist).
	ErrInvalidParent = errors.New("moderation: parent comment does not belong to report")
	// ErrInvalidReason is returned when a flag reason is not a known enum value.
	ErrInvalidReason = errors.New("moderation: invalid flag reason")
	// ErrDuplicateFlag is returned when a reporter has already flagged the target.
	ErrDuplicateFlag = errors.New("moderation: already flagged")
	// ErrInvalidDecision is returned when a review decision is not valid for the
	// target kind.
	ErrInvalidDecision = errors.New("moderation: invalid decision")
	// ErrInvalidCursor is returned when a pagination cursor cannot be decoded.
	ErrInvalidCursor = errors.New("moderation: invalid cursor")
)

// removedUserLabel is the display label used when a comment's author row has
// been cleared (author_user_id IS NULL). The API never exposes author email or
// id, only a label.
const removedUserLabel = "removed user"

// Comment is the internal representation of a comments row plus its joined
// author label.
type Comment struct {
	ID              int64
	ReportID        int64
	AuthorUserID    *int64
	ParentCommentID *int64
	AuthorLabel     string
	Body            string
	Status          string
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

// Flag is the internal representation of a content_flags row.
type Flag struct {
	ID             int64
	ReporterUserID int64
	ReportID       *int64
	CommentID      *int64
	Reason         string
	Details        *string
	Status         string
	CreatedAt      time.Time
	ResolvedAt     *time.Time
}

// QueueItem is a moderation-queue projection: an open flag plus a short excerpt
// of the flagged target.
type QueueItem struct {
	FlagID     int64
	Reason     string
	Details    *string
	CreatedAt  time.Time
	TargetType string
	TargetID   int64
	Excerpt    string
}

// Decision is the internal representation of a moderation_decisions row.
type Decision struct {
	ID              int64
	ReportID        *int64
	CommentID       *int64
	ModeratorUserID *int64
	Decision        string
	Rationale       *string
	SuggestionID    *int64
	CreatedAt       time.Time
}

// Cursor is an opaque pagination position over (created_at, id) ascending.
type Cursor struct {
	CreatedAt time.Time
	ID        int64
}

// encodeID serializes a bigint PK as an opaque string for JSON output.
func encodeID(id int64) string {
	return strconv.FormatInt(id, 10)
}

// decodeID parses an opaque string ID into a bigint. Returns false when the
// value is not a valid positive integer.
func decodeID(s string) (int64, bool) {
	id, err := strconv.ParseInt(s, 10, 64)
	if err != nil || id <= 0 {
		return 0, false
	}
	return id, true
}
