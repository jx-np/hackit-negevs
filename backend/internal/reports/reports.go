// Package reports implements the public community feed domain: publishing
// redacted scam posts by explicit consent, browsing and searching the feed
// with cursor pagination and scam-type/tag filters, and up/down reactions.
// In the public API these community submissions are called "posts"; the domain
// and its backing table remain named "reports".
//
// The domain only ever exposes explicitly published, server-scrubbed redacted
// text. It never reads or returns private_checks / private_uploads content, and
// derived counts (comments, reactions) are computed from their source rows
// rather than denormalized.
package reports

import (
	"errors"
	"strconv"
	"time"
)

// review_status values. Mirrors the reports.review_status CHECK constraint.
const (
	ReviewUnverified = "unverified"
	ReviewReviewed   = "reviewed"
	ReviewDisputed   = "disputed"
	ReviewHidden     = "hidden"
	ReviewRemoved    = "removed"
)

// Feed sort modes.
const (
	SortRecent = "recent"
)

// Domain errors surfaced by the service layer and mapped to HTTP statuses by
// the handler.
var (
	// ErrReportNotFound is returned when a report lookup yields no row, or when
	// the report is deleted/hidden/removed and the requester is not privileged.
	ErrReportNotFound = errors.New("reports: report not found")
	// ErrForbidden is returned when the requester may not mutate a report they
	// do not own and are not a moderator/admin for.
	ErrForbidden = errors.New("reports: forbidden")
	// ErrConfirmationRequired is returned when publication is attempted without
	// confirm_publication == true.
	ErrConfirmationRequired = errors.New("reports: publication confirmation required")
	// ErrTitleRequired is returned when a report title is empty.
	ErrTitleRequired = errors.New("reports: title is required")
	// ErrBodyRequired is returned when redacted_text is empty (after scrubbing).
	ErrBodyRequired = errors.New("reports: redacted_text is required")
	// ErrUnknownCategory is returned when the supplied scam_type slug does not
	// resolve to a category.
	ErrUnknownCategory = errors.New("reports: unknown scam_type")
	// ErrUnknownTags is returned when one or more supplied tag slugs do not
	// resolve to existing tags. The offending slugs are carried by the
	// UnknownTagsError type.
	ErrUnknownTags = errors.New("reports: unknown tags")
	// ErrInvalidVote is returned when a reaction vote is not -1 or 1.
	ErrInvalidVote = errors.New("reports: vote must be 1 or -1")
	// ErrInvalidCursor is returned when a pagination cursor cannot be decoded.
	ErrInvalidCursor = errors.New("reports: invalid cursor")
)

// UnknownTagsError carries the specific unknown tag slugs for a field-level 422.
type UnknownTagsError struct {
	Slugs []string
}

func (e *UnknownTagsError) Error() string { return "reports: unknown tags" }

// Unwrap allows errors.Is(err, ErrUnknownTags) to match.
func (e *UnknownTagsError) Unwrap() error { return ErrUnknownTags }

// Category is the internal representation of a categories row.
type Category struct {
	ID             int64
	Slug           string
	NameKey        string
	DescriptionKey *string
}

// Tag is the internal representation of a tags row.
type Tag struct {
	ID      int64
	Slug    string
	NameKey string
}

// Report is the full internal representation of a reports row plus its derived
// counts and requester-scoped flags. Not every field is populated by every
// query; list projections fill the card subset while detail queries fill all.
type Report struct {
	ID                     int64
	AuthorUserID           *int64
	SourceCheckID          *int64
	CategoryID             int64
	Title                  string
	RedactedText           string
	SourceLocale           string
	ReviewStatus           string
	CreatedAt              time.Time
	UpdatedAt              time.Time
	DeletedAt              *time.Time
	PublicationConfirmedAt time.Time

	// Joined category and tags.
	Category Category
	Tags     []Tag

	// Derived counts.
	CommentCount int64
	UpCount      int64
	DownCount    int64

	// Requester-scoped field: MyVote is the requesting user's reaction vote
	// (-1, 0, 1), zero-valued for anonymous requesters.
	MyVote int16
}

// ReportCard is the reduced feed projection. It carries a truncated excerpt of
// the redacted text rather than the full body.
type ReportCard struct {
	ID           int64
	Title        string
	Excerpt      string
	Category     Category
	Tags         []Tag
	ReviewStatus string
	CreatedAt    time.Time
	CommentCount int64
	// TopComments holds up to a few of the most active top-level comments for a
	// preview on the feed card. Ordered most-active first.
	TopComments []TopComment
}

// TopComment is a small preview of a post's comment shown on the feed card. It
// is a read-only projection; the full discussion is fetched from the comments
// endpoint. ReplyCount reflects activity (direct replies to this comment).
type TopComment struct {
	ID          int64
	AuthorLabel string
	Body        string
	ReplyCount  int64
	CreatedAt   time.Time
}

// Cursor is an opaque pagination position over (created_at, id) descending.
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
