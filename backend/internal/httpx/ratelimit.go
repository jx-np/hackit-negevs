package httpx

import (
	"net"
	"net/http"
	"sync"
	"time"
)

// KeyFunc derives a rate-limit bucket key from a request. The default keys by
// client IP.
type KeyFunc func(r *http.Request) string

// RateLimiter is a simple in-memory token-bucket limiter keyed by an arbitrary
// string (client IP by default). It is safe for concurrent use and intended
// for single-instance pilot deployments.
type RateLimiter struct {
	rate   float64 // tokens added per second
	burst  float64 // maximum tokens
	keyFn  KeyFunc
	mu     sync.Mutex
	bucket map[string]*tokenBucket
	stop   chan struct{}
}

type tokenBucket struct {
	tokens   float64
	lastSeen time.Time
}

// NewRateLimiter creates a limiter allowing rate tokens per second with the
// given burst. If keyFn is nil, requests are keyed by client IP. A background
// goroutine periodically evicts idle buckets; call Close to stop it.
func NewRateLimiter(rate, burst float64, keyFn KeyFunc) *RateLimiter {
	if keyFn == nil {
		keyFn = clientIPKey
	}
	rl := &RateLimiter{
		rate:   rate,
		burst:  burst,
		keyFn:  keyFn,
		bucket: make(map[string]*tokenBucket),
		stop:   make(chan struct{}),
	}
	go rl.cleanupLoop()
	return rl
}

// Close stops the background cleanup goroutine.
func (rl *RateLimiter) Close() {
	close(rl.stop)
}

// Middleware returns the limiter as HTTP middleware.
func (rl *RateLimiter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !rl.allow(rl.keyFn(r)) {
			TooManyRequests(w, r, "rate limit exceeded")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (rl *RateLimiter) allow(key string) bool {
	now := time.Now()

	rl.mu.Lock()
	defer rl.mu.Unlock()

	b, ok := rl.bucket[key]
	if !ok {
		rl.bucket[key] = &tokenBucket{tokens: rl.burst - 1, lastSeen: now}
		return true
	}

	elapsed := now.Sub(b.lastSeen).Seconds()
	b.tokens = min(rl.burst, b.tokens+elapsed*rl.rate)
	b.lastSeen = now

	if b.tokens < 1 {
		return false
	}
	b.tokens--
	return true
}

func (rl *RateLimiter) cleanupLoop() {
	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()
	for {
		select {
		case <-rl.stop:
			return
		case <-ticker.C:
			rl.cleanup()
		}
	}
}

func (rl *RateLimiter) cleanup() {
	cutoff := time.Now().Add(-10 * time.Minute)
	rl.mu.Lock()
	defer rl.mu.Unlock()
	for k, b := range rl.bucket {
		if b.lastSeen.Before(cutoff) {
			delete(rl.bucket, k)
		}
	}
}

func clientIPKey(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}
