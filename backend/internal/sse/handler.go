package sse

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"scamshield/internal/httpx"
)

// Handler serves the public per-post SSE stream.
type Handler struct {
	svc       *Service
	hub       *Hub
	logger    *slog.Logger
	baseCtx   context.Context
	keepalive time.Duration
}

// HandlerOptions configures a Handler. All fields are optional.
type HandlerOptions struct {
	// Logger defaults to slog.Default().
	Logger *slog.Logger
	// BaseContext is cancelled when the server shuts down; every open stream
	// returns as soon as it is done. Nil means only the request context is
	// watched.
	BaseContext context.Context
	// Keepalive overrides DefaultKeepaliveInterval (used by tests).
	Keepalive time.Duration
}

// NewHandler constructs an SSE Handler.
func NewHandler(svc *Service, hub *Hub, opts HandlerOptions) *Handler {
	logger := opts.Logger
	if logger == nil {
		logger = slog.Default()
	}
	keepalive := opts.Keepalive
	if keepalive <= 0 {
		keepalive = DefaultKeepaliveInterval
	}
	return &Handler{
		svc:       svc,
		hub:       hub,
		logger:    logger,
		baseCtx:   opts.BaseContext,
		keepalive: keepalive,
	}
}

// noopMiddleware passes requests through unchanged.
func noopMiddleware(next http.Handler) http.Handler { return next }

// RegisterRoutes registers the SSE endpoint on mux. The stream exposes only
// public data, so it uses optional auth (EventSource cannot set an
// Authorization header) and never a required login.
func (h *Handler) RegisterRoutes(mux *http.ServeMux, optionalAuth, global httpx.Middleware) {
	if optionalAuth == nil {
		optionalAuth = noopMiddleware
	}
	if global == nil {
		global = noopMiddleware
	}
	mux.Handle("GET /api/v1/community/posts/{id}/sse", global(optionalAuth(http.HandlerFunc(h.stream))))
}

// stream validates the post, then holds the connection open, forwarding events
// published to the hub plus periodic keepalives.
func (h *Handler) stream(w http.ResponseWriter, r *http.Request) {
	postID, ok := decodeID(r.PathValue("id"))
	if !ok {
		httpx.NotFound(w, r, "report not found")
		return
	}

	// Validate before any SSE headers are written so an invisible post gets a
	// normal JSON 404 rather than an event stream that immediately closes.
	visible, err := h.svc.PostVisible(r.Context(), postID)
	if err != nil {
		h.logger.Error("sse: visibility check failed", "post_id", postID, "error", err)
		httpx.InternalError(w, r, "")
		return
	}
	if !visible {
		httpx.NotFound(w, r, "report not found")
		return
	}

	var baseDone <-chan struct{}
	if h.baseCtx != nil {
		baseDone = h.baseCtx.Done()
		select {
		case <-baseDone:
			httpx.WriteError(w, r, http.StatusServiceUnavailable, "server_shutting_down", "server is shutting down")
			return
		default:
		}
	}

	events, unsubscribe, ok := h.hub.Subscribe(postID)
	if !ok {
		httpx.WriteError(w, r, http.StatusServiceUnavailable, "stream_unavailable",
			"too many active event streams; try again shortly")
		return
	}
	defer unsubscribe()

	// The global http.Server sets a 60s WriteTimeout for ordinary responses.
	// A long-lived stream must clear its write deadline for this request only;
	// if the writer does not support deadlines, carry on (older wrappers).
	rc := http.NewResponseController(w)
	if err := rc.SetWriteDeadline(time.Time{}); err != nil && !errors.Is(err, http.ErrNotSupported) {
		h.logger.Warn("sse: could not clear write deadline", "post_id", postID, "error", err)
	}

	hdr := w.Header()
	hdr.Set("Content-Type", "text/event-stream")
	hdr.Set("Cache-Control", "no-cache, no-transform")
	hdr.Set("Connection", "keep-alive")
	hdr.Set("X-Accel-Buffering", "no")
	w.WriteHeader(http.StatusOK)

	if _, err := fmt.Fprintf(w, "retry: %d\n\n", RetryMilliseconds); err != nil {
		return
	}
	if !writeEvent(w, Event{Name: EventReady, Data: readyPayload{PostID: encodeID(postID)}}) {
		return
	}
	if err := rc.Flush(); err != nil && !errors.Is(err, http.ErrNotSupported) {
		return
	}

	h.logger.Debug("sse: stream open", "post_id", postID, "subscribers", h.hub.CountForPost(postID))
	defer h.logger.Debug("sse: stream closed", "post_id", postID)

	ticker := time.NewTicker(h.keepalive)
	defer ticker.Stop()

	for {
		select {
		case <-r.Context().Done():
			return
		case <-baseDone:
			return
		case ev, open := <-events:
			if !open {
				// The hub closed the channel: slow subscriber eviction or
				// server shutdown.
				return
			}
			if !writeEvent(w, ev) {
				return
			}
			if err := rc.Flush(); err != nil && !errors.Is(err, http.ErrNotSupported) {
				return
			}
		case <-ticker.C:
			if _, err := io.WriteString(w, ": keepalive\n\n"); err != nil {
				return
			}
			if err := rc.Flush(); err != nil && !errors.Is(err, http.ErrNotSupported) {
				return
			}
		}
	}
}

// writeEvent emits one SSE frame. It reports false when the payload cannot be
// marshalled or the write fails; payload contents are never logged.
func writeEvent(w io.Writer, ev Event) bool {
	data, err := json.Marshal(ev.Data)
	if err != nil {
		return false
	}
	_, err = fmt.Fprintf(w, "event: %s\ndata: %s\n\n", ev.Name, data)
	return err == nil
}

// encodeID serializes a bigint PK as the opaque string the API uses.
func encodeID(id int64) string {
	return strconv.FormatInt(id, 10)
}

// decodeID parses an opaque string ID into a bigint. It matches the other
// handlers: only positive integers are valid.
func decodeID(s string) (int64, bool) {
	id, err := strconv.ParseInt(s, 10, 64)
	if err != nil || id <= 0 {
		return 0, false
	}
	return id, true
}
