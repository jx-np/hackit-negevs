package auth

import (
	"errors"
	"net/http"
	"regexp"
	"strings"
	"time"

	"scamshield/internal/httpx"
)

var (
	// emailRe is the canonical address shape: local part of allowed characters,
	// then @, then dot-separated labels ending in a 2+ character TLD.
	emailRe = regexp.MustCompile(`^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$`)
	// displayNameRe allows plain letters, digits and at most one interior space.
	// No leading/trailing spaces, no punctuation or non-ASCII characters.
	displayNameRe = regexp.MustCompile(`^[A-Za-z0-9]+( [A-Za-z0-9]+)?$`)
)

// Handler exposes the auth HTTP endpoints.
type Handler struct {
	svc    *Service
	tokens *TokenService
}

// NewHandler constructs an auth Handler.
func NewHandler(svc *Service, tokens *TokenService) *Handler {
	return &Handler{svc: svc, tokens: tokens}
}

// RegisterRoutes registers auth routes on the mux. Public routes are wrapped
// with the provided public middleware; the protected /me route additionally
// requires a valid access token.
func (h *Handler) RegisterRoutes(mux *http.ServeMux, public httpx.Middleware) {
	if public == nil {
		public = func(next http.Handler) http.Handler { return next }
	}
	protected := httpx.Chain(public, RequireAuth(h.tokens))

	mux.Handle("POST /api/v1/auth/register", public(http.HandlerFunc(h.register)))
	mux.Handle("POST /api/v1/auth/login", public(http.HandlerFunc(h.login)))
	mux.Handle("POST /api/v1/auth/refresh", public(http.HandlerFunc(h.refresh)))
	mux.Handle("POST /api/v1/auth/logout", public(http.HandlerFunc(h.logout)))
	mux.Handle("GET /api/v1/me", protected(http.HandlerFunc(h.me)))
}

// --- DTOs ---

type userDTO struct {
	ID          string `json:"id"`
	Email       string `json:"email"`
	DisplayName string `json:"display_name"`
	Role        string `json:"role"`
	Locale      string `json:"locale"`
}

type profileDTO struct {
	ID          string `json:"id"`
	Email       string `json:"email"`
	DisplayName string `json:"display_name"`
	Role        string `json:"role"`
	Locale      string `json:"locale"`
	CreatedAt   string `json:"created_at"`
}

type authResponse struct {
	User         userDTO `json:"user"`
	AccessToken  string  `json:"access_token"`
	RefreshToken string  `json:"refresh_token"`
	ExpiresIn    int64   `json:"expires_in"`
}

func toUserDTO(u User) userDTO {
	return userDTO{
		ID:          encodeID(u.ID),
		Email:       u.Email,
		DisplayName: u.DisplayName,
		Role:        u.Role,
		Locale:      u.Locale,
	}
}

// --- Handlers ---

type registerRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"display_name"`
	Locale      string `json:"locale"`
}

func (h *Handler) register(w http.ResponseWriter, r *http.Request) {
	var req registerRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	if fields := validateRegister(req); len(fields) > 0 {
		httpx.Unprocessable(w, r, "invalid registration input", fields)
		return
	}

	user, pair, err := h.svc.Register(r.Context(), RegisterInput{
		Email:       req.Email,
		Password:    req.Password,
		DisplayName: req.DisplayName,
		Locale:      req.Locale,
		UserAgent:   r.UserAgent(),
	})
	if err != nil {
		switch {
		case errors.Is(err, ErrPasswordTooLong):
			httpx.Unprocessable(w, r, "password must not exceed 72 bytes", map[string]string{
				"password": "must not exceed 72 bytes",
			})
		case errors.Is(err, ErrEmailTaken):
			httpx.Conflict(w, r, "email is already registered")
		default:
			httpx.InternalError(w, r, "")
		}
		return
	}

	httpx.WriteJSON(w, http.StatusCreated, authResponse{
		User:         toUserDTO(user),
		AccessToken:  pair.AccessToken,
		RefreshToken: pair.RefreshToken,
		ExpiresIn:    pair.ExpiresIn,
	})
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *Handler) login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}
	if strings.TrimSpace(req.Email) == "" || req.Password == "" {
		// Keep the failure generic to avoid revealing which field was missing.
		httpx.Unauthorized(w, r, "invalid credentials")
		return
	}

	user, pair, err := h.svc.Login(r.Context(), LoginInput{
		Email:     req.Email,
		Password:  req.Password,
		UserAgent: r.UserAgent(),
	})
	if err != nil {
		if errors.Is(err, ErrInvalidCredentials) {
			httpx.Unauthorized(w, r, "invalid credentials")
			return
		}
		httpx.InternalError(w, r, "")
		return
	}

	httpx.WriteJSON(w, http.StatusOK, authResponse{
		User:         toUserDTO(user),
		AccessToken:  pair.AccessToken,
		RefreshToken: pair.RefreshToken,
		ExpiresIn:    pair.ExpiresIn,
	})
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type refreshResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

func (h *Handler) refresh(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}

	pair, err := h.svc.Refresh(r.Context(), req.RefreshToken, r.UserAgent())
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidRefreshToken), errors.Is(err, ErrRefreshTokenReused), errors.Is(err, ErrUserNotFound):
			httpx.Unauthorized(w, r, "invalid refresh token")
		default:
			httpx.InternalError(w, r, "")
		}
		return
	}

	httpx.WriteJSON(w, http.StatusOK, refreshResponse{
		AccessToken:  pair.AccessToken,
		RefreshToken: pair.RefreshToken,
		ExpiresIn:    pair.ExpiresIn,
	})
}

type logoutRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func (h *Handler) logout(w http.ResponseWriter, r *http.Request) {
	var req logoutRequest
	if !httpx.DecodeJSON(w, r, &req) {
		return
	}
	if err := h.svc.Logout(r.Context(), req.RefreshToken); err != nil {
		httpx.InternalError(w, r, "")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) me(w http.ResponseWriter, r *http.Request) {
	p, ok := PrincipalFromContext(r.Context())
	if !ok {
		httpx.Unauthorized(w, r, "authentication required")
		return
	}

	user, err := h.svc.Me(r.Context(), p.UserID)
	if err != nil {
		if errors.Is(err, ErrUserNotFound) {
			httpx.NotFound(w, r, "user not found")
			return
		}
		httpx.InternalError(w, r, "")
		return
	}

	httpx.WriteJSON(w, http.StatusOK, profileDTO{
		ID:          encodeID(user.ID),
		Email:       user.Email,
		DisplayName: user.DisplayName,
		Role:        user.Role,
		Locale:      user.Locale,
		CreatedAt:   user.CreatedAt.UTC().Format(time.RFC3339),
	})
}

func validateRegister(req registerRequest) map[string]string {
	fields := map[string]string{}
	if strings.TrimSpace(req.Email) == "" {
		fields["email"] = "is required"
	} else if !emailRe.MatchString(strings.TrimSpace(req.Email)) {
		fields["email"] = "must be a valid email address"
	}
	if req.Password == "" {
		fields["password"] = "is required"
	} else if len(req.Password) < 8 {
		fields["password"] = "must be at least 8 characters"
	}
	if strings.TrimSpace(req.DisplayName) == "" {
		fields["display_name"] = "is required"
	} else if !displayNameRe.MatchString(req.DisplayName) {
		fields["display_name"] = "may only contain letters, digits and at most one space"
	}
	return fields
}
