package news

import (
	"net/http"

	"scamshield/internal/httpx"
)

// Handler exposes the public news HTTP endpoints.
type Handler struct {
	svc *Service
}

// NewHandler constructs a news Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// noopMiddleware passes requests through unchanged. Used when a caller supplies
// a nil middleware.
func noopMiddleware(next http.Handler) http.Handler { return next }

// RegisterRoutes registers the news routes on mux.
//
// optionalAuth attaches a principal opportunistically without rejecting
// anonymous callers. global is applied outermost to every route (e.g. logging,
// rate limiting). A nil middleware is treated as a no-op. Composition order is
// global(auth(handler)).
func (h *Handler) RegisterRoutes(mux *http.ServeMux, optionalAuth, global httpx.Middleware) {
	if optionalAuth == nil {
		optionalAuth = noopMiddleware
	}
	if global == nil {
		global = noopMiddleware
	}
	mux.Handle("GET /api/v1/news", global(optionalAuth(http.HandlerFunc(h.listArticles))))
}

// --- DTOs ---

type articleDTO struct {
	ID    string            `json:"id"`
	Icon  string            `json:"icon"`
	Title map[string]string `json:"title"`
	Text  map[string]string `json:"text"`
}

type articlesResponse struct {
	Articles []articleDTO `json:"articles"`
}

// listArticles returns every active article with all of its translations. The
// client selects the locale; unknown locales are simply absent from the maps.
func (h *Handler) listArticles(w http.ResponseWriter, r *http.Request) {
	articles, err := h.svc.ListArticles(r.Context())
	if err != nil {
		httpx.InternalError(w, r, "")
		return
	}
	out := make([]articleDTO, 0, len(articles))
	for _, a := range articles {
		out = append(out, toArticleDTO(a))
	}
	httpx.WriteJSON(w, http.StatusOK, articlesResponse{Articles: out})
}

// --- mapping ---

func toArticleDTO(a Article) articleDTO {
	titles := make(map[string]string, len(a.Translations))
	texts := make(map[string]string, len(a.Translations))
	for locale, tr := range a.Translations {
		titles[locale] = tr.Title
		texts[locale] = tr.Body
	}
	return articleDTO{
		// The slug is the stable public identifier (e.g. "news-1").
		ID:    a.Slug,
		Icon:  a.Icon,
		Title: titles,
		Text:  texts,
	}
}
