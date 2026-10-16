package reports

import (
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"scamshield/internal/auth"
	"scamshield/internal/httpx"
)

// Handler exposes the community post HTTP endpoints. In the public API these
// community submissions are called "posts"; internally the domain and its
// backing table are still named "reports".
type Handler struct {
	svc *Service
}

// NewHandler constructs a posts Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// noopMiddleware passes requests through unchanged. Used when a caller supplies
// a nil middleware.
func noopMiddleware(next http.Handler) http.Handler { return next }

// RegisterRoutes registers the community post routes on mux.
//
//   - requireAuth wraps endpoints that need an authenticated principal
//     (publishing, editing, reactions, private history).
//   - optionalAuth attaches a principal when a valid token is present but allows
//     anonymous access (public feed/detail/search so my_vote can be filled for
//     logged-in callers).
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

	// Feed / discovery (public; principal attached opportunistically).
	mux.Handle("GET /api/v1/community/feed", global(optionalAuth(http.HandlerFunc(h.listFeed))))
	mux.Handle("GET /api/v1/community/feed/search", global(optionalAuth(http.HandlerFunc(h.searchFeed))))
	mux.Handle("GET /api/v1/community/posts/{id}", global(optionalAuth(http.HandlerFunc(h.getPost))))
	mux.Handle("GET /api/v1/community/posts/{id}/images/{n}", global(http.HandlerFunc(h.getPostImageAt)))
	mux.Handle("GET /api/v1/community/scam-types", global(http.HandlerFunc(h.listCategories)))
	mux.Handle("GET /api/v1/community/tags", global(http.HandlerFunc(h.listTags)))

	// Publish and manage (authenticated).
	mux.Handle("POST /api/v1/community/posts", global(requireAuth(http.HandlerFunc(h.createPost))))
	mux.Handle("PATCH /api/v1/community/posts/{id}", global(requireAuth(http.HandlerFunc(h.updatePost))))
	mux.Handle("DELETE /api/v1/community/posts/{id}", global(requireAuth(http.HandlerFunc(h.deletePost))))
	mux.Handle("GET /api/v1/me/posts", global(requireAuth(http.HandlerFunc(h.listMyPosts))))

	// Reactions (authenticated up/down vote, one per user per post).
	mux.Handle("PUT /api/v1/community/posts/{id}/reaction", global(requireAuth(http.HandlerFunc(h.setReaction))))
	mux.Handle("DELETE /api/v1/community/posts/{id}/reaction", global(requireAuth(http.HandlerFunc(h.removeReaction))))
}

// --- DTOs ---

type categoryDTO struct {
	Slug           string `json:"slug"`
	NameKey        string `json:"name_key"`
	DescriptionKey string `json:"description_key,omitempty"`
}

type tagDTO struct {
	Slug    string `json:"slug"`
	NameKey string `json:"name_key"`
}

type topCommentDTO struct {
	CommentID   string `json:"comment_id"`
	AuthorLabel string `json:"author_label"`
	Body        string `json:"body"`
	ReplyCount  int64  `json:"reply_count"`
	CreatedAt   string `json:"created_at"`
}

type postCardDTO struct {
	PostID          string `json:"post_id"`
	Title           string `json:"title"`
	RedactedExcerpt string `json:"redacted_excerpt"`
	// Category is null until the classifier assigns one. Unclassified posts are
	// only ever returned to their own author.
	Category     *categoryDTO      `json:"category"`
	Tags         []tagDTO          `json:"tags"`
	ReviewStatus string            `json:"review_status"`
	CreatedAt    string            `json:"created_at"`
	CommentCount int64             `json:"comment_count"`
	Reactions    reactionCountsDTO `json:"reactions"`
	MyVote       int16             `json:"my_vote"`
	IsMine       bool              `json:"is_mine"`
	TopComments  []topCommentDTO   `json:"top_comments"`
}

type reactionCountsDTO struct {
	Up   int64 `json:"up"`
	Down int64 `json:"down"`
}

type postDetailDTO struct {
	PostID       string `json:"post_id"`
	Title        string `json:"title"`
	RedactedText string `json:"redacted_text"`
	// Category is null until the classifier assigns one.
	Category     *categoryDTO      `json:"category"`
	Tags         []tagDTO          `json:"tags"`
	ReviewStatus string            `json:"review_status"`
	CreatedAt    string            `json:"created_at"`
	UpdatedAt    string            `json:"updated_at"`
	CommentCount int64             `json:"comment_count"`
	Reactions    reactionCountsDTO `json:"reactions"`
	MyVote       int16             `json:"my_vote"`
	// RedactedImageURLs lists every attached redacted image in display order.
	// Each entry is a public API path, not a storage location. Absent when the
	// post has no images.
	RedactedImageURLs []string `json:"redacted_image_urls,omitempty"`
}

type feedResponse struct {
	Items      []postCardDTO `json:"items"`
	NextCursor string        `json:"next_cursor,omitempty"`
}

type categoriesResponse struct {
	Items []categoryDTO `json:"items"`
}

type tagsResponse struct {
	Items []tagDTO `json:"items"`
}

type createPostRequest struct {
	CheckID string `json:"check_id"`
	// UploadIDs lists the caller's own uploads (from POST /uploads) whose PII
	// redaction has completed. Each is resolved owner-scoped and its redacted
	// image is copied into a fresh post-owned object, in list order. An upload
	// the caller does not own, or whose redaction has not finished, rejects the
	// whole publish with 422.
	UploadIDs          []string `json:"upload_ids"`
	Title              string   `json:"title"`
	RedactedText       string   `json:"redacted_text"`
	ConfirmPublication bool     `json:"confirm_publication"`
	Locale             string   `json:"locale"`
}

// updatePostRequest uses pointers so absent fields are distinguishable from
// explicit empty values ("leave unchanged" vs "set empty").
type updatePostRequest struct {
	Title        *string `json:"title"`
	RedactedText *string `json:"redacted_text"`
}

type reactionRequest struct {
	Vote int16 `json:"vote"`
}

type reactionResponse struct {
	UpCount   int64 `json:"up_count"`
	DownCount int64 `json:"down_count"`
	MyVote    int16 `json:"my_vote"`
}

// --- feed / discovery handlers ---

func (h *Handler) listFeed(w http.ResponseWriter, r *http.Request) {
	limit, ok := parseLimit(w, r)
	if !ok {
		return
	}
	q := r.URL.Query()
	page, err := h.svc.Feed(r.Context(), FeedInput{
		Sort:            q.Get("sort"),
		CategorySlug:    q.Get("scam_type"),
		TagSlug:         q.Get("tag"),
		RawCursor:       q.Get("cursor"),
		Limit:           limit,
		RequesterUserID: principalUserID(r),
	})
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toFeedResponse(page))
}

func (h *Handler) searchFeed(w http.ResponseWriter, r *http.Request) {
	limit, ok := parseLimit(w, r)
	if !ok {
		return
	}
	q := r.URL.Query()
	page, err := h.svc.Search(r.Context(), SearchInput{
		Query:           q.Get("q"),
		CategorySlug:    q.Get("scam_type"),
		RawCursor:       q.Get("cursor"),
		Limit:           limit,
		RequesterUserID: principalUserID(r),
	})
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toFeedResponse(page))
}

func (h *Handler) getPost(w http.ResponseWriter, r *http.Request) {
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "post not found")
		return
	}
	rep, err := h.svc.GetReport(r.Context(), id, principal(r))
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toDetailResponse(rep))
}

// getPostImageAt streams one image of a published post, selected by its 0-based
// position in the post's ordered image list. Each image is a redacted
// (PII-removed) copy made at publish time, so it is safe to serve publicly.
// Posts that are hidden/removed/deleted, or an out-of-range position, resolve
// to 404 so existence is never leaked.
func (h *Handler) getPostImageAt(w http.ResponseWriter, r *http.Request) {
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "post not found")
		return
	}
	position, err := strconv.Atoi(r.PathValue("n"))
	if err != nil || position < 0 {
		httpx.NotFound(w, r, "post not found")
		return
	}
	img, err := h.svc.OpenPostImageAt(r.Context(), id, position)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	defer img.Body.Close()

	w.Header().Set("Content-Type", img.MediaType)
	if img.Size > 0 {
		w.Header().Set("Content-Length", strconv.FormatInt(img.Size, 10))
	}
	// Published post images are public and immutable, so they can be cached.
	w.Header().Set("Cache-Control", "public, max-age=86400")
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, img.Body)
}

func (h *Handler) listCategories(w http.ResponseWriter, r *http.Request) {
	cats, err := h.svc.ListCategories(r.Context())
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	items := make([]categoryDTO, 0, len(cats))
	for i := range cats {
		items = append(items, *toCategoryDTO(&cats[i]))
	}
	httpx.WriteJSON(w, http.StatusOK, categoriesResponse{Items: items})
}

func (h *Handler) listTags(w http.ResponseWriter, r *http.Request) {
	limit := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil {
			httpx.Unprocessable(w, r, "invalid limit", map[string]string{"limit": "must be an integer"})
			return
		}
		limit = n
	}
	tags, err := h.svc.ListTags(r.Context(), r.URL.Query().Get("q"), limit)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	items := make([]tagDTO, 0, len(tags))
	for _, t := range tags {
		items = append(items, toTagDTO(t))
	}
	httpx.WriteJSON(w, http.StatusOK, tagsResponse{Items: items})
}

// --- publish / manage handlers ---

func (h *Handler) createPost(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}

	var req createPostRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	if !req.ConfirmPublication {
		httpx.Unprocessable(w, r, "publication must be explicitly confirmed", map[string]string{
			"confirm_publication": "must be true",
		})
		return
	}

	in := CreateInput{
		AuthorUserID:       p.UserID,
		Title:              req.Title,
		RedactedText:       req.RedactedText,
		ConfirmPublication: req.ConfirmPublication,
		SourceLocale:       req.Locale,
	}
	if raw := strings.TrimSpace(req.CheckID); raw != "" {
		checkID, ok := decodeID(raw)
		if !ok {
			httpx.Unprocessable(w, r, "invalid check_id", map[string]string{"check_id": "must be a valid id"})
			return
		}
		in.CheckID = &checkID
	}
	if len(req.UploadIDs) > 0 {
		uploadIDs := make([]int64, 0, len(req.UploadIDs))
		for _, raw := range req.UploadIDs {
			uploadID, ok := decodeID(strings.TrimSpace(raw))
			if !ok {
				httpx.Unprocessable(w, r, "invalid upload_ids", map[string]string{"upload_ids": "must be valid ids"})
				return
			}
			uploadIDs = append(uploadIDs, uploadID)
		}
		in.UploadIDs = uploadIDs
	}

	rep, err := h.svc.Create(r.Context(), in)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, toDetailResponse(rep))
}

func (h *Handler) updatePost(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "post not found")
		return
	}

	var req updatePostRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	rep, err := h.svc.Update(r.Context(), UpdateInput{
		ReportID:     id,
		Requester:    p,
		Title:        req.Title,
		RedactedText: req.RedactedText,
	})
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toDetailResponse(rep))
}

func (h *Handler) deletePost(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "post not found")
		return
	}

	if err := h.svc.Delete(r.Context(), id, p); err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) listMyPosts(w http.ResponseWriter, r *http.Request) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}
	limit, ok := parseLimit(w, r)
	if !ok {
		return
	}
	page, err := h.svc.ListMyReports(r.Context(), p.UserID, limit, r.URL.Query().Get("cursor"))
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toFeedResponse(page))
}

// --- reaction handlers ---

func (h *Handler) setReaction(w http.ResponseWriter, r *http.Request) {
	p, id, ok := h.authAndID(w, r)
	if !ok {
		return
	}
	var req reactionRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}
	res, err := h.svc.SetReaction(r.Context(), id, p.UserID, req.Vote)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, reactionResponse{UpCount: res.UpCount, DownCount: res.DownCount, MyVote: res.MyVote})
}

func (h *Handler) removeReaction(w http.ResponseWriter, r *http.Request) {
	p, id, ok := h.authAndID(w, r)
	if !ok {
		return
	}
	res, err := h.svc.RemoveReaction(r.Context(), id, p.UserID)
	if err != nil {
		h.writeServiceError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, reactionResponse{UpCount: res.UpCount, DownCount: res.DownCount, MyVote: res.MyVote})
}

// authAndID extracts the authenticated principal and the {id} path value,
// writing the appropriate error response and returning ok=false on failure.
func (h *Handler) authAndID(w http.ResponseWriter, r *http.Request) (auth.Principal, int64, bool) {
	p, ok := auth.PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return auth.Principal{}, 0, false
	}
	id, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "post not found")
		return auth.Principal{}, 0, false
	}
	return p, id, true
}

// --- mapping ---

func toCategoryDTO(c *Category) *categoryDTO {
	if c == nil {
		return nil
	}
	dto := &categoryDTO{Slug: c.Slug, NameKey: c.NameKey}
	if c.DescriptionKey != nil {
		dto.DescriptionKey = *c.DescriptionKey
	}
	return dto
}

func toTagDTO(t Tag) tagDTO {
	return tagDTO{Slug: t.Slug, NameKey: t.NameKey}
}

func toTagDTOs(tags []Tag) []tagDTO {
	out := make([]tagDTO, 0, len(tags))
	for _, t := range tags {
		out = append(out, toTagDTO(t))
	}
	return out
}

func toCardDTO(c ReportCard) postCardDTO {
	top := make([]topCommentDTO, 0, len(c.TopComments))
	for _, tc := range c.TopComments {
		top = append(top, topCommentDTO{
			CommentID:   encodeID(tc.ID),
			AuthorLabel: tc.AuthorLabel,
			Body:        tc.Body,
			ReplyCount:  tc.ReplyCount,
			CreatedAt:   tc.CreatedAt.UTC().Format(time.RFC3339),
		})
	}
	return postCardDTO{
		PostID:          encodeID(c.ID),
		Title:           c.Title,
		RedactedExcerpt: c.Excerpt,
		Category:        toCategoryDTO(c.Category),
		Tags:            toTagDTOs(c.Tags),
		ReviewStatus:    c.ReviewStatus,
		CreatedAt:       c.CreatedAt.UTC().Format(time.RFC3339),
		CommentCount:    c.CommentCount,
		Reactions:       reactionCountsDTO{Up: c.UpCount, Down: c.DownCount},
		MyVote:          c.MyVote,
		IsMine:          c.IsMine,
		TopComments:     top,
	}
}

func toFeedResponse(page Page) feedResponse {
	items := make([]postCardDTO, 0, len(page.Items))
	for _, c := range page.Items {
		items = append(items, toCardDTO(c))
	}
	return feedResponse{Items: items, NextCursor: page.NextCursor}
}

func toDetailResponse(rep Report) postDetailDTO {
	dto := postDetailDTO{
		PostID:       encodeID(rep.ID),
		Title:        rep.Title,
		RedactedText: rep.RedactedText,
		Category:     toCategoryDTO(rep.Category),
		Tags:         toTagDTOs(rep.Tags),
		ReviewStatus: rep.ReviewStatus,
		CreatedAt:    rep.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:    rep.UpdatedAt.UTC().Format(time.RFC3339),
		CommentCount: rep.CommentCount,
		Reactions:    reactionCountsDTO{Up: rep.UpCount, Down: rep.DownCount},
		MyVote:       rep.MyVote,
	}
	if len(rep.Images) > 0 {
		urls := make([]string, 0, len(rep.Images))
		for _, img := range rep.Images {
			urls = append(urls, "/api/v1/community/posts/"+dto.PostID+"/images/"+strconv.Itoa(img.Position))
		}
		dto.RedactedImageURLs = urls
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

// writeServiceError maps domain errors to stable HTTP responses.
func (h *Handler) writeServiceError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrReportNotFound):
		httpx.NotFound(w, r, "post not found")
	case errors.Is(err, ErrForbidden):
		httpx.Forbidden(w, r, "you may not modify this post")
	case errors.Is(err, ErrConfirmationRequired):
		httpx.Unprocessable(w, r, "publication must be explicitly confirmed", map[string]string{
			"confirm_publication": "must be true",
		})
	case errors.Is(err, ErrTitleRequired):
		httpx.Unprocessable(w, r, "title is required", map[string]string{"title": "must not be empty"})
	case errors.Is(err, ErrBodyRequired):
		httpx.Unprocessable(w, r, "redacted_text is required", map[string]string{"redacted_text": "must not be empty"})
	case errors.Is(err, ErrUnknownCategory):
		// No longer client-supplied (the classifier assigns it), so this is a
		// server-side resolution failure.
		httpx.InternalError(w, r, "post category could not be resolved")
	case errors.Is(err, ErrUploadNotUsable):
		httpx.Unprocessable(w, r, "one or more uploads cannot be attached", map[string]string{
			"upload_ids": "each must be your own upload whose detection has finished redacting",
		})
	case errors.Is(err, ErrInvalidVote):
		httpx.Unprocessable(w, r, "invalid vote", map[string]string{"vote": "must be 1 or -1"})
	case errors.Is(err, ErrInvalidCursor):
		httpx.BadRequest(w, r, "invalid cursor")
	default:
		httpx.InternalError(w, r, "")
	}
}

// principal returns a pointer to the authenticated principal, or nil for
// anonymous requests.
func principal(r *http.Request) *auth.Principal {
	if p, ok := auth.PrincipalFromContext(r.Context()); ok {
		return &p
	}
	return nil
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
