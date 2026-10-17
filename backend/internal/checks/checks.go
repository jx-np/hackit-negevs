// Package checks implements the private scam-check domain: text analysis via the
// AI service's decision model, deferred screenshot (OCR) processing, per-user
// private history, and the privacy-safe resource-open success metric.
//
// The domain never exposes submitted message content in list responses, URLs,
// or logs. Submitted text is stored only in the private_checks row and is
// returned solely to the check's owner.
package checks

import (
	"errors"
	"strconv"
	"time"
)

// Check status values. Mirrors the private_checks.status CHECK constraint.
const (
	StatusProcessing = "processing"
	StatusReady      = "ready"
	StatusFailed     = "failed"
)

// Verdict values. Mirrors the private_checks.verdict CHECK constraint.
const (
	VerdictSuspicious = "suspicious"
	VerdictUnclear    = "unclear"
	VerdictLikelySafe = "likely_safe"
)

// Upload status values. Mirrors the private_uploads.status CHECK constraint.
const (
	UploadStatusUploaded   = "uploaded"
	UploadStatusProcessing = "processing"
	UploadStatusReady      = "ready"
	UploadStatusFailed     = "failed"
)

// Recommended-action urgency values. Mirrors the guidance.urgency CHECK
// constraint so client rendering is consistent across domains.
const (
	UrgencyNormal    = "normal"
	UrgencyUrgent    = "urgent"
	UrgencyEmergency = "emergency"
)

// Domain errors surfaced by the service layer and mapped to HTTP statuses by
// the handler.
var (
	// ErrCheckNotFound is returned when a check lookup yields no row, or when the
	// requester is not the owner (ownership failures are reported as not-found to
	// avoid leaking existence of another user's check).
	ErrCheckNotFound = errors.New("checks: check not found")
	// ErrUploadNotFound is returned when a referenced upload does not exist or is
	// not owned by the requester.
	ErrUploadNotFound = errors.New("checks: upload not found")
	ErrUploadNotReady = errors.New("checks: upload not ready")
	// ErrResourceNotFound is returned when a resource-open references an unknown
	// resource.
	ErrResourceNotFound = errors.New("checks: resource not found")
	// ErrTextRequired is returned when neither text nor an upload reference is
	// supplied.
	ErrTextRequired = errors.New("checks: text or upload_id is required")
	// ErrOwnershipRequired is returned when an anonymous request omits both a
	// user identity and a linking check for a resource-open (violates the
	// resource_opens CHECK(user_id IS NOT NULL OR check_id IS NOT NULL)).
	ErrOwnershipRequired = errors.New("checks: user or check reference required")
	// ErrPhoneNumberRequired is returned when a phone-number report omits a
	// number or supplies one that normalizes to empty (no usable digits).
	ErrPhoneNumberRequired = errors.New("checks: phone_number is required")
	// ErrReasonRequired is returned when a phone-number report omits a reason or
	// supplies one that is empty after trimming.
	ErrReasonRequired = errors.New("checks: reason is required")
	// ErrReasonTooLong is returned when a report reason exceeds the allowed
	// length (maxReasonLength characters).
	ErrReasonTooLong = errors.New("checks: reason is too long")
	// ErrPhoneReportDuplicate is returned when the same user already reported the
	// same phone number inside the current reputation window. Reports older than
	// the window no longer count, so the user may report the number again once
	// its earlier report has aged out.
	ErrPhoneReportDuplicate = errors.New("checks: phone number already reported by this user")
	// ErrImageRequired is returned when an upload request carries no image data.
	ErrImageRequired = errors.New("checks: image is required")
	// ErrUnsupportedMediaType is returned when an uploaded image is not one of
	// the accepted formats (image/jpeg, image/png, image/webp).
	ErrUnsupportedMediaType = errors.New("checks: unsupported media type")
	// ErrImageTooLarge is returned when an uploaded image exceeds the maximum
	// accepted byte size.
	ErrImageTooLarge = errors.New("checks: image is too large")
	// ErrClassifierUnavailable is returned when the scam-assessment classifier
	// cannot be reached or returns an unusable response. Detection then fails
	// (HTTP 503 for text checks) rather than returning a synthesized verdict, so
	// an AI outage is never mistaken for a clean result.
	ErrClassifierUnavailable = errors.New("checks: classifier unavailable")
)

// Accepted upload media types. Mirrors the private_uploads.media_type CHECK
// constraint.
const (
	MediaTypeJPEG = "image/jpeg"
	MediaTypePNG  = "image/png"
	MediaTypeWebP = "image/webp"
)

// MaxUploadBytes caps a single uploaded image. Screenshots are small; this
// bound protects storage and the OCR worker from oversized inputs.
const MaxUploadBytes = 10 << 20 // 10 MiB

// SupportedUploadMediaType reports whether the given media type is an accepted
// upload format.
func SupportedUploadMediaType(mediaType string) bool {
	switch mediaType {
	case MediaTypeJPEG, MediaTypePNG, MediaTypeWebP:
		return true
	default:
		return false
	}
}

// Check is the internal representation of a private_checks row.
type Check struct {
	ID            int64
	OwnerUserID   int64
	Status        string
	InputText     *string
	ExtractedText *string
	Locale        string
	Verdict       *string
	Assessment    *Assessment
	CreatedAt     time.Time
	CompletedAt   *time.Time
}

// Upload is the internal representation of a private_uploads row.
type Upload struct {
	ID                 int64
	CheckID            *int64
	OwnerUserID        int64
	StorageKey         string
	RedactedStorageKey *string
	ExtractedText      *string
	MediaType          string
	ByteSize           int64
	Status             string
	CreatedAt          time.Time
}

// Signal is a single detected warning sign with human-readable evidence and
// explanation. evidence_excerpt is truncated and lightly masked; it never
// contains a clickable URL (links are reduced to their host).
type Signal struct {
	Code            string `json:"code"`
	EvidenceExcerpt string `json:"evidence_excerpt"`
	Explanation     string `json:"explanation"`
}

// RecommendedAction is a structured, situation-specific next step keyed to what
// the classifier detected.
type RecommendedAction struct {
	Scenario string `json:"scenario"`
	Title    string `json:"title"`
	Urgency  string `json:"urgency"`
}

// SimilarReport is a safe reference to a public report resembling the checked
// text. Populated by the repository's similarity hook; may be empty.
type SimilarReport struct {
	ReportID     string `json:"report_id"`
	Excerpt      string `json:"excerpt"`
	Rationale    string `json:"rationale"`
	ReviewStatus string `json:"review_status"`
}

// Assessment is the explainable result of analyzing a check. It is marshaled to
// the private_checks.assessment jsonb column and returned to the owner.
type Assessment struct {
	Verdict            string              `json:"verdict"`
	Signals            []Signal            `json:"signals"`
	Uncertainty        string              `json:"uncertainty"`
	Limitations        string              `json:"limitations"`
	RecommendedActions []RecommendedAction `json:"recommended_actions"`
	SuggestedTags      []string            `json:"suggested_tags"`
}

// encodeID serializes a bigint PK as an opaque string for JSON output, matching
// the convention used elsewhere in the API.
func encodeID(id int64) string {
	return strconv.FormatInt(id, 10)
}

// decodeID parses an opaque string ID back into a bigint. It returns false when
// the value is not a valid positive integer.
func decodeID(s string) (int64, bool) {
	id, err := strconv.ParseInt(s, 10, 64)
	if err != nil || id <= 0 {
		return 0, false
	}
	return id, true
}
