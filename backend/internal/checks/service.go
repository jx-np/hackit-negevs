package checks

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"strconv"
	"strings"
	"sync"
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

	// processUploadDelay is the grace period a screenshot worker waits before
	// starting the expensive OCR + PII-removal call. It gives a delete that
	// arrives right after the check is scheduled a chance to cancel the worker
	// before any compute is spent.
	processUploadDelay = 1 * time.Second

	// textClassifyTimeout bounds a synchronous text check's classifier
	// round-trips (including retries) so a stuck AI service cannot hold the
	// request open.
	textClassifyTimeout = 50 * time.Second
)

// Service holds checks business logic. It is transport-agnostic.
type Service struct {
	repo       Repository
	phones     PhoneRepository
	store      storage.Store
	redactor   pii.Redactor
	classifier Classifier
	now        func() time.Time

	// processMu guards processes, the registry of in-flight screenshot
	// pipelines keyed by check ID. It lets a delete cancel a running (or
	// still-waiting) OCR + redaction worker instead of letting it burn compute
	// on a task that no longer exists.
	processMu sync.Mutex
	processes map[int64]*processJob
	// processDelay is the grace period a worker waits before starting the
	// expensive PII-removal call (see processUploadDelay).
	processDelay time.Duration
}

// NewService constructs a checks Service.
//
// phones is the phone-number reputation source used by the trust-score lookup;
// it may share the same *pgxpool.Pool implementation as repo. store persists
// raw screenshot uploads and their redacted derivatives. redactor is the
// go-python PII-removal bridge; when it is a no-op stub (no Python service
// configured), screenshot checks fail cleanly rather than persisting
// un-redacted content. classifier is the scam-assessment seam (the AI service's
// decision model); when nil, detection fails rather than synthesizing a verdict.
func NewService(repo Repository, phones PhoneRepository, store storage.Store, redactor pii.Redactor, classifier Classifier) *Service {
	return &Service{
		repo:         repo,
		phones:       phones,
		store:        store,
		redactor:     redactor,
		classifier:   classifier,
		now:          time.Now,
		processes:    make(map[int64]*processJob),
		processDelay: processUploadDelay,
	}
}

// CreateTextInput carries a synchronous text-check request. OwnerUserID is
// always set: private detection is owner-scoped and never anonymous.
type CreateTextInput struct {
	OwnerUserID int64
	Text        string
	Locale      string
}

// CreateUploadInput carries a deferred screenshot-check request. OwnerUserID is
// always set: private detection is owner-scoped and never anonymous.
type CreateUploadInput struct {
	OwnerUserID int64
	UploadID    int64
	Locale      string
}

// CreateUploadBlobInput carries a raw screenshot to persist as a standalone
// upload. The upload is not yet attached to a check; a later POST /detection
// referencing the returned upload ID starts the OCR + redaction pipeline.
type CreateUploadBlobInput struct {
	// OwnerUserID is always set: uploads are owner-scoped and never anonymous.
	OwnerUserID int64
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

// CreateTextCheck classifies text synchronously via the AI service's decision
// model, persists a ready check, and returns the result. Classifier failure
// fails the check (never a synthesized verdict); similarity lookup is
// best-effort and never blocks a successful assessment.
func (s *Service) CreateTextCheck(ctx context.Context, in CreateTextInput) (CheckResult, error) {
	text := strings.TrimSpace(in.Text)
	if text == "" {
		return CheckResult{}, ErrTextRequired
	}
	locale := normalizeLocale(in.Locale)

	classifyCtx, cancel := context.WithTimeout(ctx, textClassifyTimeout)
	defer cancel()
	assessment, err := s.classify(classifyCtx, text, locale)
	if err != nil {
		return CheckResult{}, err
	}
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

	// Ownership: a caller may only attach their own upload.
	if upload.OwnerUserID != in.OwnerUserID {
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

// CreateUploadAndCheckResult carries the standalone upload plus the processing
// check that was auto-scheduled for it.
type CreateUploadAndCheckResult struct {
	Upload Upload
	Check  Check
}

// CreateUploadAndCheck persists a raw screenshot, immediately parks a
// "processing" check for it, links the two, and launches the OCR + redaction
// pipeline — all in one call. This lets POST /uploads schedule detection
// automatically so clients do not need a separate POST /detection round-trip.
//
// The returned check is in "processing" status; callers poll GET /detection/{id}
// for the ready assessment. The pipeline runs on a detached background context
// via StartProcessUpload and marks the check failed on any error.
//
// PRIVACY: identical posture to CreateUpload and ProcessUpload — raw bytes are
// never logged or served; only the redacted derivative is ever exposed, and
// only to the check's owner.
func (s *Service) CreateUploadAndCheck(ctx context.Context, in CreateUploadBlobInput, locale string) (CreateUploadAndCheckResult, error) {
	upload, err := s.CreateUpload(ctx, in)
	if err != nil {
		return CreateUploadAndCheckResult{}, err
	}

	res, err := s.CreateUploadCheck(ctx, CreateUploadInput{
		OwnerUserID: in.OwnerUserID,
		UploadID:    upload.ID,
		Locale:      locale,
	})
	if err != nil {
		return CreateUploadAndCheckResult{}, err
	}

	// Schedule the OCR + PII-redaction pipeline immediately. It runs detached
	// with its own timeout and persists its own terminal state.
	s.StartProcessUpload(res.Check.ID, upload.ID)

	return CreateUploadAndCheckResult{Upload: upload, Check: res.Check}, nil
}

// GetCheck returns a check for the requesting principal. Ownership is strict:
// the requester must be the owner. Ownership failures are reported as
// ErrCheckNotFound to avoid leaking existence.
func (s *Service) GetCheck(ctx context.Context, checkID int64, requesterUserID *int64) (CheckResult, error) {
	check, err := s.repo.GetCheckByID(ctx, checkID)
	if err != nil {
		return CheckResult{}, err
	}

	if requesterUserID == nil || check.OwnerUserID != *requesterUserID {
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
// GetCheck: the requester must be the check's owner, so any ownership failure
// resolves to ErrCheckNotFound to avoid leaking existence. A check that is not
// ready, has no linked upload, or whose upload has no redacted derivative yet
// also resolves to ErrCheckNotFound.
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
	if requesterUserID == nil || check.OwnerUserID != *requesterUserID {
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
	// The redactor re-encodes the derivative in the upload's format, so the
	// upload's stored media type is the correct content type for the redacted
	// image (the store holds bytes only, not content type).
	return RedactedImage{Body: obj.Body, MediaType: upload.MediaType, Size: obj.Size}, nil
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

// StartProcessUpload launches ProcessUpload in its own goroutine so the
// deferred POST /detection response can return immediately while the OCR +
// PII-redaction pipeline runs. The worker has its own timeout
// (processUploadTimeout) and marks the check failed on any error, so a dropped
// request or caller never leaves a check stuck in "processing".
//
// The worker runs on a cancellable context registered under the check ID, so
// DELETE /detection/{id} (and DELETE /uploads/{id}) can stop it via
// cancelProcess — including during the grace period before any expensive work
// begins (see processUploadDelay).
//
// Errors are intentionally swallowed here: ProcessUpload persists failure state
// itself and must not log raw content, so there is nothing for the caller to do
// with the returned error.
func (s *Service) StartProcessUpload(checkID, uploadID int64) {
	// Register the worker so a delete can cancel it. If a worker is already
	// registered for this check (e.g. a retried schedule), cancel it first so
	// only the newest one runs.
	ctx, cancel := context.WithCancel(context.Background())
	job := &processJob{cancel: cancel}

	s.processMu.Lock()
	if prev := s.processes[checkID]; prev != nil {
		prev.cancel()
	}
	s.processes[checkID] = job
	s.processMu.Unlock()

	go func() {
		defer func() {
			// Deregister only if we are still the current worker, then release
			// the context regardless.
			s.processMu.Lock()
			if s.processes[checkID] == job {
				delete(s.processes, checkID)
			}
			s.processMu.Unlock()
			cancel()
		}()
		_ = s.ProcessUpload(ctx, checkID, uploadID)
	}()
}

// processJob tracks a running screenshot pipeline so it can be cancelled.
type processJob struct {
	cancel context.CancelFunc
}

// cancelProcess stops the in-flight (or still-waiting) screenshot pipeline for a
// check, if any. It is called when a check is deleted so a worker that has not
// yet reached the expensive PII-removal call never spends compute on a task that
// no longer exists.
func (s *Service) cancelProcess(checkID int64) {
	s.processMu.Lock()
	if job := s.processes[checkID]; job != nil {
		job.cancel()
		delete(s.processes, checkID)
	}
	s.processMu.Unlock()
}

// ProcessUpload runs the OCR + PII-redaction pipeline for a screenshot check
// that CreateUploadCheck parked in "processing". It fetches the raw image from
// the blob store, hands it to the go-python redaction bridge, persists the
// redacted image derivative, classifies the redacted text via the AI service's
// decision model, and completes the check with a ready assessment. Any failure
// marks the check (and its upload) failed rather than persisting un-redacted
// content.
//
// When the redactor recovers no readable text, the check completes as 'ready'
// with no extracted text and no assessment: classification is skipped rather
// than fabricating a "likely_safe" verdict from empty input.
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
	// "processing" and no un-redacted content is ever persisted. The update runs
	// on a detached context (ignoring cancellation) so a timed-out or cancelled
	// worker can still record the failure instead of leaving the check parked.
	fail := func(cause error) error {
		failCtx, failCancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
		defer failCancel()
		if ferr := s.repo.FailCheck(failCtx, checkID, &uploadID); ferr != nil {
			return errors.Join(cause, ferr)
		}
		return cause
	}

	// Grace delay: hold off the expensive OCR + PII-removal call briefly so a
	// delete arriving right after the check is scheduled can cancel the worker
	// before any compute is spent. On cancellation the check is being removed,
	// so there is nothing to fail — return without touching the database.
	if s.processDelay > 0 {
		timer := time.NewTimer(s.processDelay)
		select {
		case <-timer.C:
		case <-ctx.Done():
			timer.Stop()
			return ctx.Err()
		}
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

	// No readable text was recovered (OCR rejected everything, e.g. below its
	// confidence floor). Skip classification entirely: do not call the AI-backed
	// classifier, so an unreadable image
	// costs nothing and is never surfaced as a synthetic "likely_safe". The
	// check still completes as 'ready', carrying empty extracted text and no
	// verdict.
	var (
		extractedText *string
		assessment    *Assessment
	)
	if strings.TrimSpace(result.RedactedText) != "" {
		a, err := s.classify(ctx, result.RedactedText, locale)
		if err != nil {
			// No assessment could be produced: drop the redacted blob we just
			// wrote and fail the check rather than persisting an unclassified
			// image.
			_ = s.store.Delete(ctx, redactedKey)
			return fail(err)
		}
		extractedText = &result.RedactedText
		assessment = &a
	}

	if err := s.repo.CompleteCheckFromUpload(ctx, checkID, uploadID, extractedText, redactedKey, assessment); err != nil {
		// The redacted blob is now orphaned; best-effort cleanup, then fail.
		_ = s.store.Delete(ctx, redactedKey)
		return fail(err)
	}

	return nil
}

// DeleteCheck cancels and permanently removes a check together with its linked
// uploads and their stored blobs. Only the owner may delete; ownership failures
// resolve to ErrCheckNotFound so the endpoint never reveals whether a check
// exists. Deleting a check that is still "processing" actively cancels the
// in-flight OCR + PII-removal worker (so it stops before spending more compute);
// any completion update that still races through finds no row and the worker
// discards the redacted blob it wrote (see CompleteCheckFromUpload).
func (s *Service) DeleteCheck(ctx context.Context, checkID int64, requesterUserID *int64) error {
	check, err := s.repo.GetCheckByID(ctx, checkID)
	if err != nil {
		return err
	}
	if requesterUserID == nil || check.OwnerUserID != *requesterUserID {
		return ErrCheckNotFound
	}
	return s.deleteCheck(ctx, checkID)
}

// DeleteUpload cancels an upload. Because POST /uploads schedules detection
// immediately, an upload is normally linked to a check; in that case the whole
// task — the check and its uploads — is removed, exactly as DELETE /detection
// would. A staged, unlinked upload is removed on its own. Only the owner may
// delete; ownership failures resolve to ErrUploadNotFound. Blobs are purged
// best-effort.
func (s *Service) DeleteUpload(ctx context.Context, uploadID int64, requesterUserID *int64) error {
	upload, err := s.repo.GetUploadByID(ctx, uploadID)
	if err != nil {
		return err
	}
	if requesterUserID == nil || upload.OwnerUserID != *requesterUserID {
		return ErrUploadNotFound
	}
	if upload.CheckID != nil {
		return s.deleteCheck(ctx, *upload.CheckID)
	}

	deleted, err := s.repo.DeleteUpload(ctx, uploadID)
	if err != nil {
		return err
	}
	s.purgeBlob(ctx, deleted.StorageKey, deleted.RedactedStorageKey)
	return nil
}

// deleteCheck removes a check row (cascading its uploads) and best-effort
// purges the uploads' raw and redacted blobs. It first cancels any in-flight
// worker for the check so no further compute is spent on the deleted task.
// Callers must have verified ownership.
func (s *Service) deleteCheck(ctx context.Context, checkID int64) error {
	s.cancelProcess(checkID)

	uploads, err := s.repo.DeleteCheck(ctx, checkID)
	if err != nil {
		return err
	}
	for _, u := range uploads {
		s.purgeBlob(ctx, u.StorageKey, u.RedactedStorageKey)
	}
	return nil
}

// PurgeExpired removes a batch of expired private checks and uploads and purges
// their stored blobs. It powers the background retention reaper. The returned
// count is the number of upload blobs scheduled for deletion; blob removal is
// best-effort, so a missed object is an orphaned file, never a privacy leak.
func (s *Service) PurgeExpired(ctx context.Context) (int, error) {
	keys, err := s.repo.PurgeExpired(ctx)
	if err != nil {
		return 0, err
	}
	for _, k := range keys {
		s.purgeBlob(ctx, k.StorageKey, k.RedactedStorageKey)
	}
	return len(keys), nil
}

// purgeBlob best-effort deletes an upload's raw and (optional) redacted blobs.
// Failures are ignored: the row is already gone, so a missed object is only an
// orphaned file. No keys or content are logged.
func (s *Service) purgeBlob(ctx context.Context, storageKey string, redactedKey *string) {
	if s.store == nil {
		return
	}
	if storageKey != "" {
		_ = s.store.Delete(ctx, storageKey)
	}
	if redactedKey != nil && *redactedKey != "" {
		_ = s.store.Delete(ctx, *redactedKey)
	}
}

// --- helpers ---

// classify runs the configured classifier, normalizing any failure (transport,
// status, decode, timeout, or a missing backend) into ErrClassifierUnavailable
// so callers and the handler treat every classifier outage the same way. The
// submitted text is never logged.
func (s *Service) classify(ctx context.Context, text, locale string) (Assessment, error) {
	if s.classifier == nil {
		return Assessment{}, ErrClassifierUnavailable
	}
	a, err := s.classifier.Classify(ctx, text, locale)
	if err != nil {
		if errors.Is(err, ErrClassifierUnavailable) {
			return Assessment{}, err
		}
		return Assessment{}, fmt.Errorf("%w: %v", ErrClassifierUnavailable, err)
	}
	return a, nil
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
