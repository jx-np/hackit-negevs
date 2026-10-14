package checks

import (
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"time"

	"scamshield/internal/auth"
	"scamshield/internal/httpx"
)

// Handler exposes the checks HTTP endpoints.
type Handler struct {
	svc *Service
}

// NewHandler constructs a checks Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// noopMiddleware passes requests through unchanged. Used when a caller supplies
// a nil middleware.
func noopMiddleware(next http.Handler) http.Handler { return next }

// RegisterRoutes registers the checks routes on mux.
//
//   - requireAuth wraps endpoints that need an authenticated principal.
//   - optionalAuth attaches a principal when a valid token is present but allows
//     anonymous requests (used for creating and opening resources on checks).
//   - global is applied outermost to every route (e.g. logging, rate limiting);
//     nil is treated as a no-op.
//
// Composition order is global(auth(handler)) so cross-cutting concerns wrap the
// auth layer.
func (h *Handler) RegisterRoutes(mux *http.ServeMux, requireAuth, optionalAuth, global httpx.Middleware) {
	if requireAuth == nil {
		requireAuth = noopMiddleware
	}
	if optionalAuth == nil {
		optionalAuth = noopMiddleware
	}
	if global == nil {
		global = noopMiddleware
	}

	// Phone-number trust lookup is a public read (anonymous allowed).
	mux.Handle("GET /api/v1/detection/phone-number/trust-score", global(optionalAuth(http.HandlerFunc(h.phoneTrustScore))))
	// Reporting a phone number requires an authenticated principal.
	mux.Handle("POST /api/v1/detection/phone-number/report", global(requireAuth(http.HandlerFunc(h.reportPhoneNumber))))

	// Screenshot uploads: multipart image stored for later OCR + redaction.
	// Anonymous uploads are permitted (owner attached opportunistically) so the
	// same flow serves logged-out users running a quick private check.
	mux.Handle("POST /api/v1/uploads", global(optionalAuth(http.HandlerFunc(h.createUpload))))

	// Anonymous checks are allowed; attach a principal opportunistically.
	mux.Handle("POST /api/v1/detection", global(optionalAuth(http.HandlerFunc(h.createCheck))))
	// Retrieval and history are owner-scoped and require authentication.
	mux.Handle("GET /api/v1/detection/{id}", global(requireAuth(http.HandlerFunc(h.getCheck))))
	// Redacted screenshot derivative for a check; owner-scoped, raw upload is
	// never exposed. Requires authentication so ownership can be enforced.
	mux.Handle("GET /api/v1/detection/{id}/redacted-image", global(requireAuth(http.HandlerFunc(h.getRedactedImage))))
	mux.Handle("GET /api/v1/me/detection", global(requireAuth(http.HandlerFunc(h.listMyChecks))))
	// Resource-open metric permits anonymous callers when a check links the row.
	mux.Handle("POST /api/v1/detection/{id}/resource-opens", global(optionalAuth(http.HandlerFunc(h.recordResourceOpen))))
}

// --- DTOs ---

type createCheckRequest struct {
	Text     string `json:"text"`
	UploadID string `json:"upload_id"`
	Locale   string `json:"locale"`
}

type uploadResponse struct {
	UploadID  string `json:"upload_id"`
	Status    string `json:"status"`
	MediaType string `json:"media_type"`
}

type signalDTO struct {
	Code            string `json:"code"`
	EvidenceExcerpt string `json:"evidence_excerpt"`
	Explanation     string `json:"explanation"`
}

type recommendedActionDTO struct {
	Scenario string `json:"scenario"`
	Title    string `json:"title"`
	Urgency  string `json:"urgency"`
}

type similarReportDTO struct {
	ReportID     string `json:"report_id"`
	Excerpt      string `json:"excerpt"`
	Rationale    string `json:"rationale"`
	ReviewStatus string `json:"review_status"`
}

// assessmentDTO mirrors the client-facing assessment envelope (minus verdict,
// which sits at the top level of the check response).
type assessmentDTO struct {
	Limitations string `json:"limitations"`
}

// checkResponse is the full ready-check response. Optional fields are omitted
// while a check is still processing.
type checkResponse struct {
	CheckID            string                 `json:"check_id"`
	Status             string                 `json:"status"`
	Verdict            string                 `json:"verdict,omitempty"`
	Assessment         *assessmentDTO         `json:"assessment,omitempty"`
	Signals            []signalDTO            `json:"signals,omitempty"`
	Uncertainty        string                 `json:"uncertainty,omitempty"`
	RecommendedActions []recommendedActionDTO `json:"recommended_actions,omitempty"`
	SimilarReports     []similarReportDTO     `json:"similar_reports,omitempty"`
	SuggestedTags      []string               `json:"suggested_tags,omitempty"`
}

type checkListItemDTO struct {
	CheckID   string `json:"check_id"`
	Status    string `json:"status"`
	Verdict   string `json:"verdict,omitempty"`
	CreatedAt string `json:"created_at"`
}

type listChecksResponse struct {
	Items      []checkListItemDTO `json:"items"`
	NextCursor string             `json:"next_cursor,omitempty"`
}

type resourceOpenRequest struct {
	ResourceID string `json:"resource_id"`
	GuidanceID string `json:"guidance_id"`
}

type phoneTrustResponse struct {
	PhoneNumber string `json:"phone_number"`
	TrustScore  int    `json:"trust_score"`
	Rating      string `json:"rating"`
	ReportCount int64  `json:"report_count"`
	Known       bool   `json:"known"`
	// Classification is the label from the (separate) classification system for
	// the number's current reporting window, or an empty string when none
	// applies. Always present so clients can rely on the field.
	Classification string `json:"classification"`
}

type reportPhoneRequest struct {
	PhoneNumber string `json:"phone_number"`
	Reason      string `json:"reason"`
}

// --- handlers ---

// createUpload accepts a multipart/form-data screenshot upload, stores the raw
// bytes behind the blob store, and returns an opaque upload_id the caller then
// passes to POST /detection to start the OCR + PII-redaction pipeline.
//
// The raw image is never logged, never returned, and never exposed publicly;
// only the redacted derivative produced by the worker is retrievable, and only
// by the owner of the resulting check.
func (h *Handler) createUpload(w http.ResponseWriter, r *http.Request) {
	// Cap the whole request body so an oversized or malicious upload cannot
	// exhaust memory. A small slack above MaxUploadBytes covers multipart
	// framing overhead; the service re-checks the decoded image size exactly.
	r.Body = http.MaxBytesReader(w, r.Body, MaxUploadBytes+(1<<20))

	file, header, err := r.FormFile("image")
	if err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			httpx.PayloadTooLarge(w, r, "image is too large")
			return
		}
		httpx.Unprocessable(w, r, "image file is required", map[string]string{
			"image": "must be provided as a multipart form field named 'image'",
		})
		return
	}
	defer file.Close()

	// Resolve the media type. Prefer the part's declared Content-Type; fall back
	// to sniffing is intentionally avoided here because the service validates the
	// declared type against the supported set and the OCR service re-validates.
	mediaType := ""
	if header.Header != nil {
		mediaType = strings.TrimSpace(header.Header.Get("Content-Type"))
	}
	// Content-Type may carry parameters (e.g. "image/jpeg; charset=binary").
	if i := strings.IndexByte(mediaType, ';'); i >= 0 {
		mediaType = strings.TrimSpace(mediaType[:i])
	}

	upload, err := h.svc.CreateUpload(r.Context(), CreateUploadBlobInput{
		OwnerUserID: principalUserID(r),
		MediaType:   mediaType,
		Body:        file,
	})
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}

	httpx.WriteJSON(w, http.StatusCreated, uploadResponse{
		UploadID:  encodeID(upload.ID),
		Status:    upload.Status,
		MediaType: upload.MediaType,
	})
}

// getRedactedImage streams the PII-redacted screenshot derivative for a check.
// Ownership is enforced strictly in the service: anonymous callers, non-owners,
// and checks without a ready redacted image all resolve to not_found so the
// endpoint never reveals whether a given check exists.
func (h *Handler) getRedactedImage(w http.ResponseWriter, r *http.Request) {
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "check not found")
		return
	}

	img, err := h.svc.OpenRedactedImage(r.Context(), id, principalUserID(r))
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	defer img.Body.Close()

	w.Header().Set("Content-Type", img.MediaType)
	if img.Size > 0 {
		w.Header().Set("Content-Length", strconv.FormatInt(img.Size, 10))
	}
	// Redacted screenshots are owner-private; forbid shared/proxy caching.
	w.Header().Set("Cache-Control", "private, no-store")
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, img.Body)
}

func (h *Handler) createCheck(w http.ResponseWriter, r *http.Request) {
	var req createCheckRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	ownerID := principalUserID(r)
	locale := req.Locale
	text := strings.TrimSpace(req.Text)

	// Text takes precedence: synchronous analysis.
	if text != "" {
		res, err := h.svc.CreateTextCheck(r.Context(), CreateTextInput{
			OwnerUserID: ownerID,
			Text:        text,
			Locale:      locale,
		})
		if err != nil {
			h.writeServiceError(w, r, err)
			return
		}
		httpx.WriteJSON(w, http.StatusCreated, toCheckResponse(res))
		return
	}

	// Deferred screenshot check.
	if strings.TrimSpace(req.UploadID) != "" {
		uploadID, ok := decodeID(strings.TrimSpace(req.UploadID))
		if !ok {
			httpx.Unprocessable(w, r, "invalid upload_id", map[string]string{"upload_id": "must be a valid id"})
			return
		}
		res, err := h.svc.CreateUploadCheck(r.Context(), CreateUploadInput{
			OwnerUserID: ownerID,
			UploadID:    uploadID,
			Locale:      locale,
		})
		if err != nil {
			h.writeServiceError(w, r, err)
			return
		}
		// Kick the OCR + PII-redaction pipeline asynchronously. It runs on a
		// background context (detached from the request) with its own timeout so
		// the deferred response returns immediately and the worker survives the
		// request lifetime. ProcessUpload marks the check failed on any error.
		h.svc.StartProcessUpload(res.Check.ID, uploadID)
		// Deferred: no synchronous result.
		httpx.WriteJSON(w, http.StatusAccepted, checkResponse{
			CheckID: encodeID(res.Check.ID),
			Status:  res.Check.Status,
		})
		return
	}

	httpx.Unprocessable(w, r, "text or upload_id is required", map[string]string{
		"text": "required unless upload_id is provided",
	})
}

func (h *Handler) phoneTrustScore(w http.ResponseWriter, r *http.Request) {
	phoneNumber := strings.TrimSpace(r.URL.Query().Get("phone_number"))
	if phoneNumber == "" {
		httpx.Unprocessable(w, r, "phone_number is required", map[string]string{
			"phone_number": "must be provided as a query parameter",
		})
		return
	}

	res, err := h.svc.LookupPhoneTrust(r.Context(), phoneNumber)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, phoneTrustResponse{
		PhoneNumber:    res.PhoneNumber,
		TrustScore:     res.TrustScore,
		Rating:         res.Rating,
		ReportCount:    res.ReportCount,
		Known:          res.Known,
		Classification: res.Classification,
	})
}

func (h *Handler) reportPhoneNumber(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}

	var req reportPhoneRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	// Deliberately no logging of the reported number here.
	err := h.svc.ReportPhoneNumber(r.Context(), PhoneReport{
		PhoneNumber:    req.PhoneNumber,
		Reason:         req.Reason,
		ReporterUserID: p.UserID,
	})
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusAccepted)
}

func (h *Handler) getCheck(w http.ResponseWriter, r *http.Request) {
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "check not found")
		return
	}
	requester := principalUserID(r)

	res, err := h.svc.GetCheck(r.Context(), id, requester)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toCheckResponse(res))
}

func (h *Handler) listMyChecks(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}

	limit := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil {
			httpx.Unprocessable(w, r, "invalid limit", map[string]string{"limit": "must be an integer"})
			return
		}
		limit = n
	}
	cursor := strings.TrimSpace(r.URL.Query().Get("cursor"))

	page, err := h.svc.ListMyChecks(r.Context(), p.UserID, limit, cursor)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}

	items := make([]checkListItemDTO, 0, len(page.Items))
	for _, it := range page.Items {
		dto := checkListItemDTO{
			CheckID:   encodeID(it.ID),
			Status:    it.Status,
			CreatedAt: it.CreatedAt.UTC().Format(time.RFC3339),
		}
		if it.Verdict != nil {
			dto.Verdict = *it.Verdict
		}
		items = append(items, dto)
	}

	httpx.WriteJSON(w, http.StatusOK, listChecksResponse{
		Items:      items,
		NextCursor: page.NextCursor,
	})
}

func (h *Handler) recordResourceOpen(w http.ResponseWriter, r *http.Request) {
	checkID, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "check not found")
		return
	}

	var req resourceOpenRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}
	resourceID, ok := decodeID(strings.TrimSpace(req.ResourceID))
	if !ok {
		httpx.Unprocessable(w, r, "resource_id is required", map[string]string{"resource_id": "must be a valid id"})
		return
	}

	params := ResourceOpenParams{
		UserID:     principalUserID(r),
		CheckID:    &checkID,
		ResourceID: resourceID,
	}
	if g := strings.TrimSpace(req.GuidanceID); g != "" {
		guidanceID, ok := decodeID(g)
		if !ok {
			httpx.Unprocessable(w, r, "invalid guidance_id", map[string]string{"guidance_id": "must be a valid id"})
			return
		}
		params.GuidanceID = &guidanceID
	}

	// Deliberately no logging of any request content here.
	if err := h.svc.RecordResourceOpen(r.Context(), params); err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- mapping & errors ---

func toCheckResponse(res CheckResult) checkResponse {
	c := res.Check
	resp := checkResponse{
		CheckID: encodeID(c.ID),
		Status:  c.Status,
	}
	if c.Status != StatusReady || c.Assessment == nil {
		return resp
	}

	a := c.Assessment
	resp.Verdict = a.Verdict
	resp.Uncertainty = a.Uncertainty
	resp.Assessment = &assessmentDTO{Limitations: a.Limitations}

	resp.Signals = make([]signalDTO, 0, len(a.Signals))
	for _, s := range a.Signals {
		resp.Signals = append(resp.Signals, signalDTO{
			Code:            s.Code,
			EvidenceExcerpt: s.EvidenceExcerpt,
			Explanation:     s.Explanation,
		})
	}

	resp.RecommendedActions = make([]recommendedActionDTO, 0, len(a.RecommendedActions))
	for _, ra := range a.RecommendedActions {
		resp.RecommendedActions = append(resp.RecommendedActions, recommendedActionDTO{
			Scenario: ra.Scenario,
			Title:    ra.Title,
			Urgency:  ra.Urgency,
		})
	}

	resp.SuggestedTags = a.SuggestedTags

	resp.SimilarReports = make([]similarReportDTO, 0, len(res.SimilarReports))
	for _, sr := range res.SimilarReports {
		resp.SimilarReports = append(resp.SimilarReports, similarReportDTO{
			ReportID:     sr.ReportID,
			Excerpt:      sr.Excerpt,
			Rationale:    sr.Rationale,
			ReviewStatus: sr.ReviewStatus,
		})
	}
	return resp
}

// writeServiceError maps domain errors to stable HTTP responses.
func (h *Handler) writeServiceError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrTextRequired):
		httpx.Unprocessable(w, r, "text or upload_id is required", map[string]string{
			"text": "required unless upload_id is provided",
		})
	case errors.Is(err, ErrCheckNotFound):
		httpx.NotFound(w, r, "check not found")
	case errors.Is(err, ErrUploadNotFound):
		httpx.NotFound(w, r, "upload not found")
	case errors.Is(err, ErrImageRequired):
		httpx.Unprocessable(w, r, "image is required", map[string]string{
			"image": "must be provided as a multipart form field named 'image'",
		})
	case errors.Is(err, ErrUnsupportedMediaType):
		httpx.Unprocessable(w, r, "unsupported image type", map[string]string{
			"image": "must be one of image/jpeg, image/png, image/webp",
		})
	case errors.Is(err, ErrImageTooLarge):
		httpx.PayloadTooLarge(w, r, "image is too large")
	case errors.Is(err, ErrResourceNotFound):
		httpx.NotFound(w, r, "resource not found")
	case errors.Is(err, ErrOwnershipRequired):
		httpx.Unprocessable(w, r, "a user session or check reference is required", nil)
	case errors.Is(err, ErrPhoneNumberRequired):
		httpx.Unprocessable(w, r, "phone_number is required", map[string]string{
			"phone_number": "must contain at least one digit",
		})
	case errors.Is(err, ErrReasonRequired):
		httpx.Unprocessable(w, r, "reason is required", map[string]string{
			"reason": "must be provided",
		})
	case errors.Is(err, ErrReasonTooLong):
		httpx.Unprocessable(w, r, "reason is too long", map[string]string{
			"reason": "must be at most 32 characters",
		})
	case errors.Is(err, ErrPhoneReportDuplicate):
		httpx.Conflict(w, r, "you have already reported this phone number")
	default:
		// Unexpected: the client gets a generic 500, but the cause is logged
		// server-side so failures are diagnosable. Postgres errors carry the
		// failing statement and constraint name, never bound parameter values,
		// so this cannot log the reported number or any message content.
		slog.Error("checks: unhandled service error",
			"error", err,
			"path", r.URL.Path,
			"request_id", httpx.RequestIDFromContext(r.Context()),
		)
		httpx.InternalError(w, r, "")
	}
}

// principalUserID returns a pointer to the authenticated user's ID, or nil for
// anonymous requests.
func principalUserID(r *http.Request) *int64 {
	if p, ok := auth.PrincipalFromContext(r.Context()); ok {
		id := p.UserID
		return &id
	}
	return nil
}
