package checks

import (
	"errors"
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

	// Anonymous checks are allowed; attach a principal opportunistically.
	mux.Handle("POST /api/v1/detection", global(optionalAuth(http.HandlerFunc(h.createCheck))))
	// Retrieval and history are owner-scoped and require authentication.
	mux.Handle("GET /api/v1/detection/{id}", global(requireAuth(http.HandlerFunc(h.getCheck))))
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
}

// --- handlers ---

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
		PhoneNumber: res.PhoneNumber,
		TrustScore:  res.TrustScore,
		Rating:      res.Rating,
		ReportCount: res.ReportCount,
		Known:       res.Known,
	})
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
	case errors.Is(err, ErrResourceNotFound):
		httpx.NotFound(w, r, "resource not found")
	case errors.Is(err, ErrOwnershipRequired):
		httpx.Unprocessable(w, r, "a user session or check reference is required", nil)
	default:
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
