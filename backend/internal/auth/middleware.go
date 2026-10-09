package auth

import (
	"context"
	"net/http"
	"strconv"
	"strings"

	"scamshield/internal/httpx"
)

type contextKey int

const principalKey contextKey = iota

// WithPrincipal returns a copy of ctx carrying the given principal.
func WithPrincipal(ctx context.Context, p Principal) context.Context {
	return context.WithValue(ctx, principalKey, p)
}

// PrincipalFromContext returns the authenticated principal, or false if absent.
func PrincipalFromContext(ctx context.Context) (Principal, bool) {
	p, ok := ctx.Value(principalKey).(Principal)
	return p, ok
}

// RequireAuth returns middleware that requires a valid Bearer access token and
// attaches the resulting principal to the request context. On failure it
// responds 401.
func RequireAuth(ts *TokenService) httpx.Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			p, ok := principalFromRequest(ts, r)
			if !ok {
				httpx.Unauthorized(w, r, "missing or invalid access token")
				return
			}
			next.ServeHTTP(w, r.WithContext(WithPrincipal(r.Context(), p)))
		})
	}
}

// OptionalAuth returns middleware that attaches a principal if a valid token is
// present but never rejects the request.
func OptionalAuth(ts *TokenService) httpx.Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if p, ok := principalFromRequest(ts, r); ok {
				r = r.WithContext(WithPrincipal(r.Context(), p))
			}
			next.ServeHTTP(w, r)
		})
	}
}

// RequireRole returns middleware that responds 403 unless the context
// principal's role is in the allowed set. RequireAuth must run first.
func RequireRole(roles ...string) httpx.Middleware {
	allowed := make(map[string]struct{}, len(roles))
	for _, role := range roles {
		allowed[role] = struct{}{}
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			p, ok := PrincipalFromContext(r.Context())
			if !ok {
				httpx.Unauthorized(w, r, "authentication required")
				return
			}
			if _, allow := allowed[p.Role]; !allow {
				httpx.Forbidden(w, r, "insufficient role")
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func principalFromRequest(ts *TokenService, r *http.Request) (Principal, bool) {
	header := r.Header.Get("Authorization")
	if header == "" {
		return Principal{}, false
	}
	const prefix = "Bearer "
	if !strings.HasPrefix(header, prefix) {
		return Principal{}, false
	}
	raw := strings.TrimSpace(strings.TrimPrefix(header, prefix))
	if raw == "" {
		return Principal{}, false
	}

	claims, err := ts.Parse(raw)
	if err != nil {
		return Principal{}, false
	}
	userID, err := strconv.ParseInt(claims.Subject, 10, 64)
	if err != nil {
		return Principal{}, false
	}
	return Principal{UserID: userID, Role: claims.Role}, true
}
