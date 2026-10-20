// Package sse implements the in-memory Server-Sent Events hub and endpoint that
// push community discussion activity (new comments and @help bot progress) to
// browsers and mobile clients without polling.
//
// The hub is deliberately process-local: it works for a single API instance.
// A multi-instance deployment would need a shared bus (Redis pub/sub, or
// Postgres LISTEN/NOTIFY) feeding each instance's hub.
//
// Privacy: events only ever carry already-public, server-scrubbed data —
// comment DTOs (never private checks/uploads), post ids and bot progress ids.
// Payloads are never logged.
package sse

import (
	"sync"
	"time"

	"scamshield/internal/moderation"
)

// Event names carried in the SSE `event:` field.
const (
	EventReady          = "ready"
	EventCommentCreated = "comment_created"
	EventGrokThinking    = "grok_thinking"
	EventGrokReplied     = "grok_replied"
	EventGrokFailed      = "grok_failed"
)

// Connection and buffer limits. Beyond these the endpoint answers 503 rather
// than letting a reconnect storm exhaust memory.
const (
	// MaxConnections caps concurrent SSE connections across all posts.
	MaxConnections = 1000
	// MaxConnectionsPerPost caps concurrent SSE connections for one post.
	MaxConnectionsPerPost = 200
	// SubscriberBuffer is the per-connection event buffer. A subscriber that
	// falls further behind is dropped (its channel is closed) rather than
	// blocking publishers.
	SubscriberBuffer = 32

	// DefaultKeepaliveInterval is how often a `: keepalive` comment line is
	// written to keep proxies and mobile radios from timing the stream out.
	DefaultKeepaliveInterval = 15 * time.Second
	// RetryMilliseconds tells EventSource how long to wait before reconnecting.
	RetryMilliseconds = 3000
)

// Event is one transport-agnostic SSE message: a name plus a JSON-marshalable
// payload (snake_case, opaque string ids).
type Event struct {
	Name string
	Data any
}

// Payload shapes. They are unexported because only this package builds them.

type readyPayload struct {
	PostID string `json:"post_id"`
}

type grokThinkingPayload struct {
	PostID           string `json:"post_id"`
	TriggerCommentID string `json:"trigger_comment_id"`
}

type grokRepliedPayload struct {
	PostID           string                 `json:"post_id"`
	TriggerCommentID string                 `json:"trigger_comment_id"`
	ReplyCommentID   string                 `json:"reply_comment_id"`
	Fallback         bool                   `json:"fallback"`
	Comment          *moderation.CommentDTO `json:"comment,omitempty"`
}

type grokFailedPayload struct {
	PostID           string `json:"post_id"`
	TriggerCommentID string `json:"trigger_comment_id"`
	Reason           string `json:"reason"`
}

// subscriber is one connected client's bounded event queue.
type subscriber struct {
	ch chan Event
}

// Hub is a concurrency-safe, in-memory pub/sub keyed by post id.
//
// Publish never blocks: when a subscriber's buffer is full that subscriber is
// dropped and its channel is closed so a slow client can never stall comment
// creation or the bot.
type Hub struct {
	mu     sync.Mutex
	byPost map[int64]map[*subscriber]struct{}
	total  int
	closed bool
}

// NewHub constructs an empty Hub.
func NewHub() *Hub {
	return &Hub{byPost: make(map[int64]map[*subscriber]struct{})}
}

// Subscribe registers a listener for postID. It returns a receive-only channel,
// an idempotent unsubscribe function, and whether a slot was available. ok is
// false when the hub is closed or a connection cap is reached; callers should
// answer 503 in that case.
func (h *Hub) Subscribe(postID int64) (events <-chan Event, unsubscribe func(), ok bool) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.closed {
		return nil, nil, false
	}
	if h.total >= MaxConnections || len(h.byPost[postID]) >= MaxConnectionsPerPost {
		return nil, nil, false
	}

	sub := &subscriber{ch: make(chan Event, SubscriberBuffer)}
	if h.byPost[postID] == nil {
		h.byPost[postID] = make(map[*subscriber]struct{})
	}
	h.byPost[postID][sub] = struct{}{}
	h.total++

	return sub.ch, func() { h.remove(postID, sub) }, true
}

// Publish delivers ev to every subscriber of postID without blocking. A
// subscriber whose buffer is full is removed and its channel closed.
func (h *Hub) Publish(postID int64, ev Event) {
	h.mu.Lock()
	defer h.mu.Unlock()

	for sub := range h.byPost[postID] {
		select {
		case sub.ch <- ev:
		default:
			h.removeLocked(postID, sub)
		}
	}
}

// Close drops every subscriber and closes their channels. Handlers see the
// closed channel and return. It is safe to call more than once; the hub cannot
// be reused afterwards.
func (h *Hub) Close() {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.closed {
		return
	}
	h.closed = true
	for postID, subs := range h.byPost {
		for sub := range subs {
			close(sub.ch)
		}
		delete(h.byPost, postID)
	}
	h.total = 0
}

// Count reports the number of active subscribers (all posts).
func (h *Hub) Count() int {
	h.mu.Lock()
	defer h.mu.Unlock()
	return h.total
}

// CountForPost reports the number of active subscribers for one post.
func (h *Hub) CountForPost(postID int64) int {
	h.mu.Lock()
	defer h.mu.Unlock()
	return len(h.byPost[postID])
}

func (h *Hub) remove(postID int64, sub *subscriber) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.removeLocked(postID, sub)
}

// removeLocked removes sub and closes its channel. The caller must hold h.mu.
// Removing an already-dropped subscriber is a no-op, which keeps unsubscribe
// safe to call after Publish has evicted the subscriber.
func (h *Hub) removeLocked(postID int64, sub *subscriber) {
	subs, ok := h.byPost[postID]
	if !ok {
		return
	}
	if _, exists := subs[sub]; !exists {
		return
	}
	delete(subs, sub)
	if len(subs) == 0 {
		delete(h.byPost, postID)
	}
	h.total--
	close(sub.ch)
}
