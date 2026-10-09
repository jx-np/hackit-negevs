package moderation

import (
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"scamshield/internal/auth"
	"scamshield/internal/httpx"
)

// Handler exposes the moderation/discussion HTTP endpoints.
type Handler struct {
	svc *Service
}

// NewHandler constructs a moderation Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// noopMiddleware passes requests through unchanged. Used when a caller supplies
// a nil middleware.
func noopMiddleware(next http.Handler) http.Handler { return next }

// RegisterRoutes registers the moderation routes on mux.
//
//   - requireAuth wraps endpoints needing an authenticated principal (posting,
//     editing and deleting comments, raising flags).
//   - optionalAuth attaches a principal opportunistically for public reads
//     (listing comments) without rejecting anonymous callers.
//   - requireModerator is the chain the caller builds as RequireAuth followed by
//     RequireRole(moderator, admin); it guards all /moderation endpoints.
//   - global is applied outermost to every route (e.g. logging, rate limiting).
//
// A nil middleware is treated as a no-op. Composition order is
// global(auth(handler)) so cross-cutting concerns wrap the auth layer.
func (h *Handler) RegisterRoutes(mux *http.ServeMux, requireAuth, optionalAuth, requireModerator, global httpx.Middleware) {
	if requireAuth == nil {
		requireAuth = noopMiddleware
	}
	if optionalAuth == nil {
		optionalAuth = noopMiddleware
	}
	if requireModerator == nil {
		requireModerator = noopMiddleware
	}
	if global == nil {
		global = noopMiddleware
	}

	// Discussion (comments on community posts).
	mux.Handle("GET /api/v1/community/discussion/posts/{id}/comments", global(optionalAuth(http.HandlerFunc(h.listComments))))
	mux.Handle("POST /api/v1/community/discussion/posts/{id}/comments", global(requireAuth(http.HandlerFunc(h.createComment))))
	mux.Handle("PATCH /api/v1/community/discussion/comments/{id}", global(requireAuth(http.HandlerFunc(h.updateComment))))
	mux.Handle("DELETE /api/v1/community/discussion/comments/{id}", global(requireAuth(http.HandlerFunc(h.deleteComment))))

	// Flagging content for moderator review (e.g. a public post that still
	// contains personal information, or harmful/spam content).
	mux.Handle("POST /api/v1/community/posts/{id}/flag", global(requireAuth(http.HandlerFunc(h.flagPost))))
	mux.Handle("POST /api/v1/community/discussion/comments/{id}/flag", global(requireAuth(http.HandlerFunc(h.flagComment))))

	// Moderation (moderator/admin only).
	mux.Handle("GET /api/v1/moderation/queue", global(requireModerator(http.HandlerFunc(h.queue))))
	mux.Handle("POST /api/v1/moderation/posts/{id}/review", global(requireModerator(http.HandlerFunc(h.reviewReport))))
	mux.Handle("POST /api/v1/moderation/comments/{id}/review", global(requireModerator(http.HandlerFunc(h.reviewComment))))
}

// --- DTOs ---

type commentDTO struct {
	CommentID   string `json:"comment_id"`
	ParentID    string `json:"parent_id,omitempty"`
	AuthorID    string `json:"author_id,omitempty"`
	AuthorLabel string `json:"author_label"`
	Body        string `json:"body"`
	Status      string `json:"status"`
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}

type commentsResponse struct {
	Items      []commentDTO `json:"items"`
	NextCursor string       `json:"next_cursor,omitempty"`
}

type createCommentRequest struct {
	Body     string `json:"body"`
	ParentID string `json:"parent_id"`
}

type updateCommentRequest struct {
	Body string `json:"body"`
}

type flagRequest struct {
	Reason  string `json:"reason"`
	Details string `json:"details"`
}

type flagResponse struct {
	FlagID string `json:"flag_id"`
	Status string `json:"status"`
}

type queueItemDTO struct {
	FlagID     string `json:"flag_id"`
	Reason     string `json:"reason"`
	Details    string `json:"details,omitempty"`
	CreatedAt  string `json:"created_at"`
	TargetType string `json:"target_type"`
	TargetID   string `json:"target_id"`
	Excerpt    string `json:"excerpt"`
}

type queueResponse struct {
	Items      []queueItemDTO `json:"items"`
	NextCursor string         `json:"next_cursor,omitempty"`
}

type reviewReportRequest struct {
	Decision     string `json:"decision"`
	Rationale    string `json:"rationale"`
	SuggestionID string `json:"suggestion_id"`
}

type reviewCommentRequest struct {
	Decision  string `json:"decision"`
	Rationale string `json:"rationale"`
}

type decisionDTO struct {
	DecisionID string `json:"decision_id"`
	PostID     string `json:"post_id,omitempty"`
	CommentID  string `json:"comment_id,omitempty"`
	Decision   string `json:"decision"`
	Rationale  string `json:"rationale,omitempty"`
	CreatedAt  string `json:"created_at"`
}

// --- discussion handlers ---

func (h *Handler) listComments(w http.ResponseWriter, r *http.Request) {
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "report not found")
		return
	}
	limit, ok := parseLimit(w, r)
	if !ok {
		return
	}
	page, err := h.svc.ListComments(r.Context(), id, limit, r.URL.Query().Get("cursor"))
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	items := make([]commentDTO, 0, len(page.Items))
	for _, c := range page.Items {
		items = append(items, toCommentDTO(c))
	}
	httpx.WriteJSON(w, http.StatusOK, commentsResponse{Items: items, NextCursor: page.NextCursor})
}

func (h *Handler) createComment(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	reportID, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "report not found")
		return
	}

	var req createCommentRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	in := CreateCommentInput{
		ReportID:     reportID,
		AuthorUserID: p.UserID,
		Body:         req.Body,
	}
	if raw := strings.TrimSpace(req.ParentID); raw != "" {
		parentID, ok := decodeID(raw)
		if !ok {
			httpx.Unprocessable(w, r, "invalid parent_id", map[string]string{"parent_id": "must be a valid id"})
			return
		}
		in.ParentID = &parentID
	}

	c, err := h.svc.CreateComment(r.Context(), in)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, toCommentDTO(c))
}

func (h *Handler) updateComment(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "comment not found")
		return
	}

	var req updateCommentRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	c, err := h.svc.UpdateComment(r.Context(), id, p, req.Body)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toCommentDTO(c))
}

func (h *Handler) deleteComment(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "comment not found")
		return
	}
	if err := h.svc.DeleteComment(r.Context(), id, p); err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- flag handlers ---

func (h *Handler) flagPost(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "report not found")
		return
	}
	var req flagRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}
	f, err := h.svc.FlagReport(r.Context(), p.UserID, id, strings.TrimSpace(req.Reason), optionalString(req.Details))
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, flagResponse{FlagID: encodeID(f.ID), Status: f.Status})
}

func (h *Handler) flagComment(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "comment not found")
		return
	}
	var req flagRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}
	f, err := h.svc.FlagComment(r.Context(), p.UserID, id, strings.TrimSpace(req.Reason), optionalString(req.Details))
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, flagResponse{FlagID: encodeID(f.ID), Status: f.Status})
}

// --- moderation handlers ---

func (h *Handler) queue(w http.ResponseWriter, r *http.Request) {
	limit, ok := parseLimit(w, r)
	if !ok {
		return
	}
	page, err := h.svc.Queue(r.Context(), limit, r.URL.Query().Get("cursor"))
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	items := make([]queueItemDTO, 0, len(page.Items))
	for _, q := range page.Items {
		items = append(items, toQueueItemDTO(q))
	}
	httpx.WriteJSON(w, http.StatusOK, queueResponse{Items: items, NextCursor: page.NextCursor})
}

func (h *Handler) reviewReport(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "report not found")
		return
	}
	var req reviewReportRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	in := ReviewReportInput{
		ReportID:        id,
		ModeratorUserID: p.UserID,
		Decision:        strings.TrimSpace(req.Decision),
		Rationale:       optionalString(req.Rationale),
	}
	if raw := strings.TrimSpace(req.SuggestionID); raw != "" {
		suggestionID, ok := decodeID(raw)
		if !ok {
			httpx.Unprocessable(w, r, "invalid suggestion_id", map[string]string{"suggestion_id": "must be a valid id"})
			return
		}
		in.SuggestionID = &suggestionID
	}

	d, err := h.svc.ReviewReport(r.Context(), in)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toDecisionDTO(d))
}

func (h *Handler) reviewComment(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "comment not found")
		return
	}
	var req reviewCommentRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	d, err := h.svc.ReviewComment(r.Context(), ReviewCommentInput{
		CommentID:       id,
		ModeratorUserID: p.UserID,
		Decision:        strings.TrimSpace(req.Decision),
		Rationale:       optionalString(req.Rationale),
	})
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toDecisionDTO(d))
}

// --- mapping ---

func toCommentDTO(c Comment) commentDTO {
	dto := commentDTO{
		CommentID:   encodeID(c.ID),
		AuthorLabel: c.AuthorLabel,
		Body:        c.Body,
		Status:      c.Status,
		CreatedAt:   c.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:   c.UpdatedAt.UTC().Format(time.RFC3339),
	}
	if c.ParentCommentID != nil {
		dto.ParentID = encodeID(*c.ParentCommentID)
	}
	// author_id is a non-identifying opaque string; email is never exposed.
	if c.AuthorUserID != nil {
		dto.AuthorID = encodeID(*c.AuthorUserID)
	}
	return dto
}

func toQueueItemDTO(q QueueItem) queueItemDTO {
	dto := queueItemDTO{
		FlagID:     encodeID(q.FlagID),
		Reason:     q.Reason,
		CreatedAt:  q.CreatedAt.UTC().Format(time.RFC3339),
		TargetType: q.TargetType,
		TargetID:   encodeID(q.TargetID),
		Excerpt:    q.Excerpt,
	}
	if q.Details != nil {
		dto.Details = *q.Details
	}
	return dto
}

func toDecisionDTO(d Decision) decisionDTO {
	dto := decisionDTO{
		DecisionID: encodeID(d.ID),
		Decision:   d.Decision,
		CreatedAt:  d.CreatedAt.UTC().Format(time.RFC3339),
	}
	if d.ReportID != nil {
		dto.PostID = encodeID(*d.ReportID)
	}
	if d.CommentID != nil {
		dto.CommentID = encodeID(*d.CommentID)
	}
	if d.Rationale != nil {
		dto.Rationale = *d.Rationale
	}
	return dto
}

// --- request parsing & error mapping ---

// parseLimit reads an optional ?limit= query parameter. A missing value yields
// 0 (the service applies the default). An invalid value writes a 422 and
// returns ok=false.
func parseLimit(w http.ResponseWriter, r *http.Request) (int, bool) {
	raw := strings.TrimSpace(r.URL.Query().Get("limit"))
	if raw == "" {
		return 0, true
	}
	n, err := strconv.Atoi(raw)
	if err != nil {
		httpx.Unprocessable(w, r, "invalid limit", map[string]string{"limit": "must be an integer"})
		return 0, false
	}
	return n, true
}

// optionalString returns a pointer to a trimmed non-empty string, or nil.
func optionalString(s string) *string {
	t := strings.TrimSpace(s)
	if t == "" {
		return nil
	}
	return &t
}

// writeServiceError maps domain errors to stable HTTP responses.
func (h *Handler) writeServiceError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrReportNotFound):
		httpx.NotFound(w, r, "report not found")
	case errors.Is(err, ErrCommentNotFound):
		httpx.NotFound(w, r, "comment not found")
	case errors.Is(err, ErrForbidden):
		httpx.Forbidden(w, r, "you may not modify this comment")
	case errors.Is(err, ErrBodyRequired):
		httpx.Unprocessable(w, r, "body is required", map[string]string{"body": "must not be empty"})
	case errors.Is(err, ErrInvalidParent):
		httpx.Unprocessable(w, r, "parent comment does not belong to this report", map[string]string{"parent_id": "must reference a comment on this report"})
	case errors.Is(err, ErrInvalidReason):
		httpx.Unprocessable(w, r, "invalid flag reason", map[string]string{"reason": "must be one of personal_information, harmful, spam, misinformation, other"})
	case errors.Is(err, ErrDuplicateFlag):
		httpx.Conflict(w, r, "you have already flagged this content")
	case errors.Is(err, ErrInvalidDecision):
		httpx.Unprocessable(w, r, "invalid decision", map[string]string{"decision": "not a valid decision for this target"})
	case errors.Is(err, ErrInvalidCursor):
		httpx.BadRequest(w, r, "invalid cursor")
	default:
		httpx.InternalError(w, r, "")
	}
}
