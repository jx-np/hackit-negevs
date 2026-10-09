package resources

import (
	"errors"
	"net/http"
	"strings"
	"time"

	"scamshield/internal/httpx"
)

// Handler exposes the resources/guidance HTTP endpoints.
type Handler struct {
	svc *Service
}

// NewHandler constructs a resources Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// noopMiddleware passes requests through unchanged. Used when a caller supplies
// a nil middleware.
func noopMiddleware(next http.Handler) http.Handler { return next }

// RegisterRoutes registers the resources routes on mux.
//
//   - optionalAuth attaches a principal opportunistically for the public
//     guidance/resources reads without rejecting anonymous callers.
//   - requireAdmin is the chain the caller builds as RequireAuth followed by
//     RequireRole(admin); it guards all /admin endpoints.
//   - global is applied outermost to every route (e.g. logging, rate limiting).
//
// A nil middleware is treated as a no-op. Composition order is
// global(auth(handler)) so cross-cutting concerns wrap the auth layer.
func (h *Handler) RegisterRoutes(mux *http.ServeMux, optionalAuth, requireAdmin, global httpx.Middleware) {
	if optionalAuth == nil {
		optionalAuth = noopMiddleware
	}
	if requireAdmin == nil {
		requireAdmin = noopMiddleware
	}
	if global == nil {
		global = noopMiddleware
	}

	// Public help / taxonomy.
	mux.Handle("GET /api/v1/guidance", global(optionalAuth(http.HandlerFunc(h.listGuidance))))
	mux.Handle("GET /api/v1/guidance/resources", global(optionalAuth(http.HandlerFunc(h.listResources))))

	// Admin catalog (admin only).
	mux.Handle("POST /api/v1/admin/resources", global(requireAdmin(http.HandlerFunc(h.createResource))))
	mux.Handle("PATCH /api/v1/admin/resources/{id}", global(requireAdmin(http.HandlerFunc(h.updateResource))))
	mux.Handle("POST /api/v1/admin/resources/{id}/archive", global(requireAdmin(http.HandlerFunc(h.archiveResource))))
}

// --- DTOs ---

type resourceDTO struct {
	ID                  string `json:"id"`
	Slug                string `json:"slug"`
	CountryCode         string `json:"country_code"`
	URL                 string `json:"url,omitempty"`
	ContactInstructions string `json:"contact_instructions,omitempty"`
	Name                string `json:"name"`
	Description         string `json:"description,omitempty"`
	VerifiedAt          string `json:"verified_at"`
	OwnerName           string `json:"owner_name"`
}

type guidanceDTO struct {
	ID        string        `json:"id"`
	Scenario  string        `json:"scenario"`
	Urgency   string        `json:"urgency"`
	Title     string        `json:"title"`
	Body      string        `json:"body"`
	Resources []resourceDTO `json:"resources"`
}

type guidanceResponse struct {
	Items []guidanceDTO `json:"items"`
}

type resourcesResponse struct {
	Items []resourceDTO `json:"items"`
}

type translationRequest struct {
	Locale      string `json:"locale"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type createResourceRequest struct {
	Slug                string               `json:"slug"`
	CountryCode         string               `json:"country_code"`
	URL                 string               `json:"url"`
	ContactInstructions string               `json:"contact_instructions"`
	OwnerName           string               `json:"owner_name"`
	VerifiedAt          string               `json:"verified_at"`
	Translations        []translationRequest `json:"translations"`
}

// updateResourceRequest uses pointers so absent fields stay unchanged while an
// explicit value (including empty string) is applied.
type updateResourceRequest struct {
	CountryCode         *string              `json:"country_code"`
	URL                 *string              `json:"url"`
	ContactInstructions *string              `json:"contact_instructions"`
	OwnerName           *string              `json:"owner_name"`
	VerifiedAt          *string              `json:"verified_at"`
	Translations        []translationRequest `json:"translations"`
}

// --- public handlers ---

func (h *Handler) listGuidance(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	items, err := h.svc.ListGuidance(r.Context(), q.Get("scenario"), q.Get("locale"))
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	out := make([]guidanceDTO, 0, len(items))
	for _, g := range items {
		out = append(out, toGuidanceDTO(g))
	}
	httpx.WriteJSON(w, http.StatusOK, guidanceResponse{Items: out})
}

func (h *Handler) listResources(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	items, err := h.svc.ListResources(r.Context(), q.Get("country"), q.Get("scenario"), q.Get("locale"))
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	out := make([]resourceDTO, 0, len(items))
	for _, res := range items {
		out = append(out, toResourceDTO(res))
	}
	httpx.WriteJSON(w, http.StatusOK, resourcesResponse{Items: out})
}

// --- admin handlers ---

func (h *Handler) createResource(w http.ResponseWriter, r *http.Request) {
	var req createResourceRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	verifiedAt, verifiedSet, ok := parseVerifiedAt(w, r, req.VerifiedAt)
	if !ok {
		return
	}

	res, err := h.svc.CreateResource(r.Context(), CreateResourceInput{
		Slug:                req.Slug,
		CountryCode:         req.CountryCode,
		URL:                 optionalString(req.URL),
		ContactInstructions: optionalString(req.ContactInstructions),
		OwnerName:           req.OwnerName,
		VerifiedAt:          verifiedAt,
		VerifiedAtSet:       verifiedSet,
		Translations:        toTranslations(req.Translations),
	})
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, toResourceDTO(res))
}

func (h *Handler) updateResource(w http.ResponseWriter, r *http.Request) {
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "resource not found")
		return
	}
	var req updateResourceRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	in := UpdateResourceInput{
		ID:                  id,
		CountryCode:         req.CountryCode,
		URL:                 req.URL,
		ContactInstructions: req.ContactInstructions,
		OwnerName:           req.OwnerName,
		Translations:        toTranslations(req.Translations),
	}
	if req.VerifiedAt != nil {
		t, err := time.Parse(time.RFC3339, strings.TrimSpace(*req.VerifiedAt))
		if err != nil {
			httpx.Unprocessable(w, r, "invalid verified_at", map[string]string{"verified_at": "must be an RFC3339 timestamp"})
			return
		}
		in.VerifiedAt = &t
	}

	res, err := h.svc.UpdateResource(r.Context(), in)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toResourceDTO(res))
}

func (h *Handler) archiveResource(w http.ResponseWriter, r *http.Request) {
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "resource not found")
		return
	}
	if err := h.svc.ArchiveResource(r.Context(), id); err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- mapping ---

func toResourceDTO(res Resource) resourceDTO {
	dto := resourceDTO{
		ID:          encodeID(res.ID),
		Slug:        res.Slug,
		CountryCode: res.CountryCode,
		Name:        res.Name,
		VerifiedAt:  res.VerifiedAt.UTC().Format(time.RFC3339),
		OwnerName:   res.OwnerName,
	}
	if res.URL != nil {
		dto.URL = *res.URL
	}
	if res.ContactInstructions != nil {
		dto.ContactInstructions = *res.ContactInstructions
	}
	if res.Description != nil {
		dto.Description = *res.Description
	}
	return dto
}

func toGuidanceDTO(g Guidance) guidanceDTO {
	res := make([]resourceDTO, 0, len(g.Resources))
	for _, r := range g.Resources {
		res = append(res, toResourceDTO(r))
	}
	return guidanceDTO{
		ID:        encodeID(g.ID),
		Scenario:  g.Scenario,
		Urgency:   g.Urgency,
		Title:     g.Title,
		Body:      g.Body,
		Resources: res,
	}
}

func toTranslations(in []translationRequest) []Translation {
	out := make([]Translation, 0, len(in))
	for _, t := range in {
		out = append(out, Translation{
			Locale:      t.Locale,
			Name:        t.Name,
			Description: optionalString(t.Description),
		})
	}
	return out
}

// --- request parsing & error mapping ---

// parseVerifiedAt parses the required verified_at RFC3339 timestamp. A blank
// value yields set=false (the service rejects it); an unparseable value writes a
// 422 and returns ok=false.
func parseVerifiedAt(w http.ResponseWriter, r *http.Request, raw string) (t time.Time, set, ok bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return time.Time{}, false, true
	}
	parsed, err := time.Parse(time.RFC3339, raw)
	if err != nil {
		httpx.Unprocessable(w, r, "invalid verified_at", map[string]string{"verified_at": "must be an RFC3339 timestamp"})
		return time.Time{}, false, false
	}
	return parsed, true, true
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
	case errors.Is(err, ErrResourceNotFound):
		httpx.NotFound(w, r, "resource not found")
	case errors.Is(err, ErrSlugRequired):
		httpx.Unprocessable(w, r, "slug is required", map[string]string{"slug": "must not be empty"})
	case errors.Is(err, ErrOwnerRequired):
		httpx.Unprocessable(w, r, "owner_name is required", map[string]string{"owner_name": "must not be empty"})
	case errors.Is(err, ErrContactRequired):
		httpx.Unprocessable(w, r, "url or contact_instructions is required", map[string]string{
			"url":                  "provide url or contact_instructions",
			"contact_instructions": "provide url or contact_instructions",
		})
	case errors.Is(err, ErrVerifiedAtRequired):
		httpx.Unprocessable(w, r, "verified_at is required", map[string]string{"verified_at": "must be an RFC3339 timestamp"})
	case errors.Is(err, ErrTranslationsRequired):
		httpx.Unprocessable(w, r, "at least one translation is required", map[string]string{"translations": "must not be empty"})
	case errors.Is(err, ErrInvalidTranslation):
		httpx.Unprocessable(w, r, "invalid translation", map[string]string{"translations": "each translation needs a locale and name"})
	case errors.Is(err, ErrSlugTaken):
		httpx.Conflict(w, r, "a resource with this slug already exists")
	default:
		httpx.InternalError(w, r, "")
	}
}
