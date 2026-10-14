package checks

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"io"
	"strconv"
	"strings"
	"time"

	"scamshield/internal/pii"
	"scamshield/internal/storage"
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

	// uploadStoragePrefix namespaces raw screenshot uploads within the store.
	uploadStoragePrefix = "uploads"
	// redactedStoragePrefix namespaces PII-redacted image derivatives.
	redactedStoragePrefix = "redacted"

	// processUploadTimeout bounds the OCR + redaction + analysis work so a
	// stuck Python backend cannot leave a check in "processing" forever.
	processUploadTimeout = 60 * time.Second
)

// Service holds checks business logic. It is transport-agnostic.
type Service struct {
	repo     Repository
	phones   PhoneRepository
	store    storage.Store
	redactor pii.Redactor
	now      func() time.Time
}

// NewService constructs a checks Service.
//
// phones is the phone-number reputation source used by the trust-score lookup;
// it may share the same *pgxpool.Pool implementation as repo. store persists
// raw screenshot uploads and their redacted derivatives. redactor is the
// go-python PII-removal bridge; when it is a no-op stub (no Python service
// configured), screenshot checks fail cleanly rather than persisting
// un-redacted content.
func NewService(repo Repository, phones PhoneRepository, store storage.Store, redactor pii.Redactor) *Service {
	return &Service{repo: repo, phones: phones, store: store, redactor: redactor, now: time.Now}
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

// CreateUploadBlobInput carries a raw screenshot to persist as a standalone
// upload. The upload is not yet attached to a check; a later POST /detection
// referencing the returned upload ID starts the OCR + redaction pipeline.
type CreateUploadBlobInput struct {
	// OwnerUserID is nil for anonymous uploads (owner_user_id stored as NULL).
	OwnerUserID *int64
	// MediaType is the declared image content type; it must be one of the
	// supported screenshot types.
	MediaType string
	// Body streams the raw image bytes. The service enforces a hard size cap
	// while reading; callers should also bound the request body.
	Body io.Reader
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

// CreateUpload persists a raw screenshot as a standalone upload and returns it.
// It validates the declared media type, streams the body to the blob store
// while enforcing a hard size cap, and records a private_uploads row in
// "uploaded" status. The upload is not yet attached to a check; the caller
// obtains the upload ID and later references it from POST /detection, which
// starts the OCR + redaction pipeline via CreateUploadCheck.
//
// PRIVACY: the stored object may contain raw, un-redacted screenshot bytes.
// The returned Upload exposes only the opaque storage key; raw bytes are never
// logged here and never served publicly.
func (s *Service) CreateUpload(ctx context.Context, in CreateUploadBlobInput) (Upload, error) {
	if s.store == nil {
		// No blob store configured; uploads cannot be accepted.
		return Upload{}, ErrUploadNotFound
	}
	if !SupportedUploadMediaType(in.MediaType) {
		return Upload{}, ErrUnsupportedMediaType
	}
	if in.Body == nil {
		return Upload{}, ErrImageRequired
	}

	// Enforce the hard size cap while reading. Read one extra byte so an image
	// exactly at the limit passes while anything larger is rejected without
	// buffering the whole oversized payload.
	limited := io.LimitReader(in.Body, MaxUploadBytes+1)
	data, err := io.ReadAll(limited)
	if err != nil {
		return Upload{}, err
	}
	if len(data) == 0 {
		return Upload{}, ErrImageRequired
	}
	if int64(len(data)) > MaxUploadBytes {
		return Upload{}, ErrImageTooLarge
	}

	key, err := s.store.Put(ctx, uploadStoragePrefix, in.MediaType, bytes.NewReader(data))
	if err != nil {
		return Upload{}, err
	}

	upload, err := s.repo.CreateUpload(ctx, CreateUploadParams{
		OwnerUserID: in.OwnerUserID,
		StorageKey:  key,
		MediaType:   in.MediaType,
		ByteSize:    int64(len(data)),
	})
	if err != nil {
		// Best-effort cleanup of the orphaned blob; the row never persisted.
		_ = s.store.Delete(ctx, key)
		return Upload{}, err
	}

	return upload, nil
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

// RedactedImage is a check's PII-redacted screenshot derivative, ready to be
// streamed to its owner. Body must be closed by the caller.
type RedactedImage struct {
	Body      io.ReadCloser
	MediaType string
	Size      int64
}

// OpenRedactedImage returns the redacted screenshot derivative for a check, for
// streaming to the requesting principal. Ownership is strict and mirrors
// GetCheck: the requester must be the check's owner, and anonymous checks are
// never retrievable, so any ownership failure resolves to ErrCheckNotFound to
// avoid leaking existence. A check that is not ready, has no linked upload, or
// whose upload has no redacted derivative yet also resolves to ErrCheckNotFound.
//
// Only the redacted derivative is ever served; the raw upload is never exposed.
func (s *Service) OpenRedactedImage(ctx context.Context, checkID int64, requesterUserID *int64) (RedactedImage, error) {
	if s.store == nil {
		return RedactedImage{}, ErrCheckNotFound
	}

	check, err := s.repo.GetCheckByID(ctx, checkID)
	if err != nil {
		return RedactedImage{}, err
	}
	if check.OwnerUserID == nil || requesterUserID == nil || *check.OwnerUserID != *requesterUserID {
		return RedactedImage{}, ErrCheckNotFound
	}

	upload, err := s.repo.GetUploadByCheckID(ctx, checkID)
	if err != nil {
		return RedactedImage{}, err
	}
	if upload.RedactedStorageKey == nil || *upload.RedactedStorageKey == "" {
		return RedactedImage{}, ErrCheckNotFound
	}

	obj, err := s.store.Get(ctx, *upload.RedactedStorageKey)
	if err != nil {
		if errors.Is(err, storage.ErrNotFound) {
			return RedactedImage{}, ErrCheckNotFound
		}
		return RedactedImage{}, err
	}
	return RedactedImage{Body: obj.Body, MediaType: obj.MediaType, Size: obj.Size}, nil
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

// StartProcessUpload launches ProcessUpload in its own goroutine on a detached
// background context so the deferred POST /detection response can return
// immediately while the OCR + PII-redaction pipeline runs. The worker has its
// own timeout (processUploadTimeout) and marks the check failed on any error,
// so a dropped request or caller never leaves a check stuck in "processing".
//
// Errors are intentionally swallowed here: ProcessUpload persists failure state
// itself and must not log raw content, so there is nothing for the caller to do
// with the returned error.
func (s *Service) StartProcessUpload(checkID, uploadID int64) {
	go func() {
		_ = s.ProcessUpload(context.Background(), checkID, uploadID)
	}()
}

// ProcessUpload runs the OCR + PII-redaction pipeline for a screenshot check
// that CreateUploadCheck parked in "processing". It fetches the raw image from
// the blob store, hands it to the go-python redaction bridge, persists the
// redacted image derivative, runs the same rules-first analyzer over the
// redacted text, and completes the check with a ready assessment. Any failure
// marks the check (and its upload) failed rather than persisting un-redacted
// content.
//
// It is designed to run in its own goroutine with a background context; the
// work is bounded by processUploadTimeout so a stuck Python backend cannot leave
// a check in "processing" forever.
//
// PRIVACY: this method handles raw screenshot bytes and extracted text. It must
// never log image bytes, OCR text, or any raw message content. Only
// non-content metadata (region counts, statuses) is observable.
func (s *Service) ProcessUpload(ctx context.Context, checkID, uploadID int64) error {
	ctx, cancel := context.WithTimeout(ctx, processUploadTimeout)
	defer cancel()

	// On any error path we mark the check failed so it never sits in
	// "processing" and no un-redacted content is ever persisted.
	fail := func(cause error) error {
		if ferr := s.repo.FailCheck(ctx, checkID, &uploadID); ferr != nil {
			return errors.Join(cause, ferr)
		}
		return cause
	}

	if s.store == nil || s.redactor == nil {
		// No pipeline configured (e.g. stub redactor / missing store): fail
		// cleanly rather than completing with un-redacted content.
		return fail(pii.ErrUnavailable)
	}

	upload, err := s.repo.GetUploadByID(ctx, uploadID)
	if err != nil {
		return fail(err)
	}

	// Fetch the raw image bytes. The reader is closed before any further work.
	obj, err := s.store.Get(ctx, upload.StorageKey)
	if err != nil {
		return fail(err)
	}
	imageData, err := io.ReadAll(obj.Body)
	closeErr := obj.Body.Close()
	if err != nil {
		return fail(err)
	}
	if closeErr != nil {
		return fail(closeErr)
	}

	// Resolve the locale from the parked check so analysis matches the request.
	locale := defaultLocale
	if check, err := s.repo.GetCheckByID(ctx, checkID); err == nil {
		locale = normalizeLocale(check.Locale)
	}

	// Hand the raw image to the go-python redaction bridge. On ErrUnavailable
	// (or any error) we fail the check: never persist un-redacted content.
	result, err := s.redactor.Redact(ctx, pii.Input{
		Image:     imageData,
		MediaType: upload.MediaType,
		Locale:    locale,
	})
	if err != nil {
		return fail(err)
	}

	// Persist the redacted image derivative. Its media type comes from the
	// redactor; fall back to the original upload type if unset.
	redactedMediaType := result.RedactedImageMediaType
	if redactedMediaType == "" {
		redactedMediaType = upload.MediaType
	}
	redactedKey, err := s.store.Put(ctx, redactedStoragePrefix, redactedMediaType, bytes.NewReader(result.RedactedImage))
	if err != nil {
		return fail(err)
	}

	// Run the pure rules-first analyzer over the redacted (PII-free) text.
	assessment := Analyze(result.RedactedText, locale)

	if err := s.repo.CompleteCheckFromUpload(ctx, checkID, uploadID, result.RedactedText, redactedKey, assessment); err != nil {
		// The redacted blob is now orphaned; best-effort cleanup, then fail.
		_ = s.store.Delete(ctx, redactedKey)
		return fail(err)
	}

	return nil
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
