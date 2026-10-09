package checks

import (
	"context"
	"encoding/base64"
	"strconv"
	"strings"
	"time"
)

// Pagination bounds for private history listing.
const (
	defaultListLimit = 20
	maxListLimit     = 100

	// defaultLocale is used when a request omits a locale.
	defaultLocale = "en-SG"

	// similarReportsLimit caps how many similar community reports are attached to
	// a ready assessment.
	similarReportsLimit = 5
)

// Service holds checks business logic. It is transport-agnostic.
type Service struct {
	repo   Repository
	phones PhoneRepository
	now    func() time.Time
}

// NewService constructs a checks Service. phones is the phone-number reputation
// source used by the trust-score lookup; it may share the same *pgxpool.Pool
// implementation as repo.
func NewService(repo Repository, phones PhoneRepository) *Service {
	return &Service{repo: repo, phones: phones, now: time.Now}
}

// CreateTextInput carries a synchronous text-check request.
type CreateTextInput struct {
	// OwnerUserID is nil for anonymous checks (owner_user_id stored as NULL).
	OwnerUserID *int64
	Text        string
	Locale      string
}

// CreateUploadInput carries a deferred screenshot-check request.
type CreateUploadInput struct {
	OwnerUserID *int64
	UploadID    int64
	Locale      string
}

// CheckResult is the service-level result of creating or fetching a check. When
// Status is "processing", Assessment and SimilarReports are empty.
type CheckResult struct {
	Check          Check
	SimilarReports []SimilarReport
}

// CreateTextCheck analyzes text synchronously, persists a ready check, and
// returns the result. The analyzer is pure; similarity lookup is best-effort and
// never blocks a successful assessment.
func (s *Service) CreateTextCheck(ctx context.Context, in CreateTextInput) (CheckResult, error) {
	text := strings.TrimSpace(in.Text)
	if text == "" {
		return CheckResult{}, ErrTextRequired
	}
	locale := normalizeLocale(in.Locale)

	assessment := Analyze(text, locale)
	completedAt := s.now().UTC()

	check, err := s.repo.CreateCheck(ctx, CreateCheckParams{
		OwnerUserID: in.OwnerUserID,
		Status:      StatusReady,
		InputText:   &text,
		Locale:      locale,
		Verdict:     &assessment.Verdict,
		Assessment:  &assessment,
		CompletedAt: &completedAt,
	})
	if err != nil {
		return CheckResult{}, err
	}

	// Best-effort similarity enrichment. A failure here must not fail the check;
	// the assessment is already persisted and valid on its own.
	similar, err := s.repo.FindSimilarReports(ctx, text, similarReportsLimit)
	if err != nil {
		similar = nil
	}

	return CheckResult{Check: check, SimilarReports: similar}, nil
}

// CreateUploadCheck starts a deferred screenshot check. It validates upload
// ownership, creates a processing check, links the upload, and returns
// immediately. Actual OCR runs later via ProcessUpload; this call never blocks.
func (s *Service) CreateUploadCheck(ctx context.Context, in CreateUploadInput) (CheckResult, error) {
	upload, err := s.repo.GetUploadByID(ctx, in.UploadID)
	if err != nil {
		return CheckResult{}, err
	}

	// Ownership: an authenticated caller may only attach their own upload; an
	// anonymous caller may only attach an upload with no owner.
	if !ownerMatches(upload.OwnerUserID, in.OwnerUserID) {
		return CheckResult{}, ErrUploadNotFound
	}

	locale := normalizeLocale(in.Locale)
	check, err := s.repo.CreateCheck(ctx, CreateCheckParams{
		OwnerUserID: in.OwnerUserID,
		Status:      StatusProcessing,
		Locale:      locale,
	})
	if err != nil {
		return CheckResult{}, err
	}

	if err := s.repo.LinkUploadToCheck(ctx, upload.ID, check.ID); err != nil {
		return CheckResult{}, err
	}

	return CheckResult{Check: check}, nil
}

// GetCheck returns a check for the requesting principal. Ownership is strict:
// the requester must be the owner. Anonymous checks (no owner) are not
// retrievable by anyone, so they resolve to ErrCheckNotFound. Ownership
// failures are also reported as ErrCheckNotFound to avoid leaking existence.
func (s *Service) GetCheck(ctx context.Context, checkID int64, requesterUserID *int64) (CheckResult, error) {
	check, err := s.repo.GetCheckByID(ctx, checkID)
	if err != nil {
		return CheckResult{}, err
	}

	if check.OwnerUserID == nil || requesterUserID == nil || *check.OwnerUserID != *requesterUserID {
		return CheckResult{}, ErrCheckNotFound
	}

	var similar []SimilarReport
	if check.Status == StatusReady && check.InputText != nil {
		if found, err := s.repo.FindSimilarReports(ctx, *check.InputText, similarReportsLimit); err == nil {
			similar = found
		}
	}
	return CheckResult{Check: check, SimilarReports: similar}, nil
}

// ListPage is a page of the requester's private check history.
type ListPage struct {
	Items      []CheckListItem
	NextCursor string
}

// ListMyChecks returns the authenticated user's checks with cursor pagination.
// limit is clamped to [1, maxListLimit]; a zero or negative value uses the
// default. rawCursor is the opaque next_cursor from a prior page, or "".
func (s *Service) ListMyChecks(ctx context.Context, ownerUserID int64, limit int, rawCursor string) (ListPage, error) {
	limit = clampLimit(limit)

	var cursor *Cursor
	if rawCursor != "" {
		c, ok := decodeCursor(rawCursor)
		if !ok {
			// An unparseable cursor is treated as the first page rather than an
			// error, keeping clients resilient to opaque-token churn.
			cursor = nil
		} else {
			cursor = &c
		}
	}

	// Fetch one extra row to determine whether a further page exists.
	items, err := s.repo.ListChecksByOwner(ctx, ownerUserID, limit+1, cursor)
	if err != nil {
		return ListPage{}, err
	}

	var next string
	if len(items) > limit {
		last := items[limit-1]
		next = encodeCursor(Cursor{CreatedAt: last.CreatedAt, ID: last.ID})
		items = items[:limit]
	}

	return ListPage{Items: items, NextCursor: next}, nil
}

// RecordResourceOpen records the privacy-safe success metric. It requires either
// an authenticated user or a linking check to satisfy the table constraint. It
// never receives or stores message content.
func (s *Service) RecordResourceOpen(ctx context.Context, p ResourceOpenParams) error {
	if p.UserID == nil && p.CheckID == nil {
		return ErrOwnershipRequired
	}
	return s.repo.RecordResourceOpen(ctx, p)
}

// ProcessUpload is the entry point a future asynchronous OCR worker would call
// after CreateUploadCheck has parked a check in "processing". It performs OCR on
// the stored image, redacts sensitive data from the extracted text, runs the
// same rules-first analyzer, and persists a ready assessment (or marks the check
// failed).
//
// It is implemented as a non-blocking stub for now: OCR and redaction adapters
// are not wired in this phase, so it records a failure rather than fabricating a
// result. The signature and flow are stable so the real worker can drop in.
//
// TODO(checks): inject OCR and redaction adapters (behind interfaces) and
// replace the stub body: 1) fetch the image via upload.StorageKey, 2) run OCR,
// 3) redact PII from the extracted text, 4) call Analyze(redactedText, locale),
// 5) persist via repo.CompleteCheckFromUpload. Bound the work with a timeout and
// emit observable failure states. Never log extracted_text.
func (s *Service) ProcessUpload(ctx context.Context, checkID, uploadID int64) error {
	// No OCR adapter is available yet. Mark the check failed so it does not sit
	// in "processing" forever; a real worker will replace this with a completed
	// assessment. This keeps the state machine honest without blocking callers.
	return s.repo.FailCheck(ctx, checkID, &uploadID)
}

// --- helpers ---

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

// ownerMatches reports whether a resource's owner matches the requester. Both
// nil (anonymous resource, anonymous requester) is a match; any mismatch,
// including one nil and one set, is not.
func ownerMatches(resourceOwner, requester *int64) bool {
	if resourceOwner == nil && requester == nil {
		return true
	}
	if resourceOwner == nil || requester == nil {
		return false
	}
	return *resourceOwner == *requester
}

// Cursor encoding: base64url of "createdAtUnixNanos:id". Opaque to clients.
func encodeCursor(c Cursor) string {
	raw := strconv.FormatInt(c.CreatedAt.UTC().UnixNano(), 10) + ":" + strconv.FormatInt(c.ID, 10)
	return base64.RawURLEncoding.EncodeToString([]byte(raw))
}

func decodeCursor(s string) (Cursor, bool) {
	b, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return Cursor{}, false
	}
	parts := strings.SplitN(string(b), ":", 2)
	if len(parts) != 2 {
		return Cursor{}, false
	}
	nanos, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return Cursor{}, false
	}
	id, err := strconv.ParseInt(parts[1], 10, 64)
	if err != nil {
		return Cursor{}, false
	}
	return Cursor{CreatedAt: time.Unix(0, nanos).UTC(), ID: id}, true
}
