package auth

import (
	"context"
	"errors"
	"strings"
	"time"
)

// Config holds the subset of application configuration the auth service needs.
type Config struct {
	BcryptCost      int
	RefreshTokenTTL time.Duration
}

// Service holds auth business logic.
type Service struct {
	repo   Repository
	tokens *TokenService
	cfg    Config
	now    func() time.Time
}

// NewService constructs an auth Service.
func NewService(repo Repository, tokens *TokenService, cfg Config) *Service {
	return &Service{
		repo:   repo,
		tokens: tokens,
		cfg:    cfg,
		now:    time.Now,
	}
}

// TokenPair is the result of issuing tokens.
type TokenPair struct {
	AccessToken  string
	RefreshToken string
	ExpiresIn    int64 // access token lifetime in seconds
}

// RegisterInput carries registration parameters.
type RegisterInput struct {
	Email       string
	Password    string
	DisplayName string
	Locale      string
	UserAgent   string
}

// Register creates a new user and password credential, then issues tokens.
func (s *Service) Register(ctx context.Context, in RegisterInput) (User, TokenPair, error) {
	emailNormalized := normalizeEmail(in.Email)

	hash, err := HashPassword(in.Password, s.cfg.BcryptCost)
	if err != nil {
		return User{}, TokenPair{}, err
	}

	locale := strings.TrimSpace(in.Locale)
	if locale == "" {
		locale = "en-SG"
	}

	u := User{
		Email:       strings.TrimSpace(in.Email),
		DisplayName: strings.TrimSpace(in.DisplayName),
		Role:        RoleResident,
		Locale:      locale,
	}

	created, err := s.repo.CreateUserWithPassword(ctx, u, emailNormalized, hash)
	if err != nil {
		return User{}, TokenPair{}, err
	}

	pair, err := s.issueTokens(ctx, created, in.UserAgent)
	if err != nil {
		return User{}, TokenPair{}, err
	}
	return created, pair, nil
}

// LoginInput carries login parameters.
type LoginInput struct {
	Email     string
	Password  string
	UserAgent string
}

// Login verifies credentials and issues tokens. All failures return the generic
// ErrInvalidCredentials.
func (s *Service) Login(ctx context.Context, in LoginInput) (User, TokenPair, error) {
	emailNormalized := normalizeEmail(in.Email)

	u, hash, err := s.repo.GetUserByEmailNormalized(ctx, emailNormalized)
	if err != nil {
		if errors.Is(err, ErrUserNotFound) {
			return User{}, TokenPair{}, ErrInvalidCredentials
		}
		return User{}, TokenPair{}, err
	}

	if err := ComparePassword(hash, in.Password); err != nil {
		if errors.Is(err, ErrInvalidCredentials) {
			return User{}, TokenPair{}, ErrInvalidCredentials
		}
		return User{}, TokenPair{}, err
	}

	pair, err := s.issueTokens(ctx, u, in.UserAgent)
	if err != nil {
		return User{}, TokenPair{}, err
	}
	return u, pair, nil
}

// Refresh verifies and rotates a refresh token, returning a fresh token pair.
func (s *Service) Refresh(ctx context.Context, refreshToken, userAgent string) (TokenPair, error) {
	if refreshToken == "" {
		return TokenPair{}, ErrInvalidRefreshToken
	}
	tokenHash := HashRefreshToken(refreshToken)

	session, err := s.repo.GetRefreshSessionByTokenHash(ctx, tokenHash)
	if err != nil {
		return TokenPair{}, err
	}

	// Reuse detection: a revoked token being presented again suggests theft.
	// Revoke the entire chain for the user and reject.
	if session.IsRevoked() {
		_ = s.repo.RevokeAllUserSessions(ctx, session.UserID)
		return TokenPair{}, ErrRefreshTokenReused
	}

	if session.IsExpired(s.now()) {
		return TokenPair{}, ErrInvalidRefreshToken
	}

	u, err := s.repo.GetUserByID(ctx, session.UserID)
	if err != nil {
		return TokenPair{}, err
	}

	newToken, newHash, err := GenerateRefreshToken()
	if err != nil {
		return TokenPair{}, err
	}
	expiresAt := s.now().Add(s.cfg.RefreshTokenTTL)

	if _, err := s.repo.RotateSession(ctx, session.ID, u.ID, newHash, expiresAt, userAgent); err != nil {
		return TokenPair{}, err
	}

	access, err := s.tokens.Issue(u.ID, u.Role)
	if err != nil {
		return TokenPair{}, err
	}
	return TokenPair{
		AccessToken:  access,
		RefreshToken: newToken,
		ExpiresIn:    int64(s.tokens.AccessTokenTTL().Seconds()),
	}, nil
}

// Logout revokes the session identified by the given refresh token. It is
// idempotent: unknown tokens are treated as already logged out.
func (s *Service) Logout(ctx context.Context, refreshToken string) error {
	if refreshToken == "" {
		return nil
	}
	tokenHash := HashRefreshToken(refreshToken)
	session, err := s.repo.GetRefreshSessionByTokenHash(ctx, tokenHash)
	if err != nil {
		if errors.Is(err, ErrInvalidRefreshToken) {
			return nil
		}
		return err
	}
	return s.repo.RevokeSession(ctx, session.ID)
}

// Me returns the safe profile for a user by ID.
func (s *Service) Me(ctx context.Context, userID int64) (User, error) {
	return s.repo.GetUserByID(ctx, userID)
}

func (s *Service) issueTokens(ctx context.Context, u User, userAgent string) (TokenPair, error) {
	access, err := s.tokens.Issue(u.ID, u.Role)
	if err != nil {
		return TokenPair{}, err
	}

	refreshToken, refreshHash, err := GenerateRefreshToken()
	if err != nil {
		return TokenPair{}, err
	}
	expiresAt := s.now().Add(s.cfg.RefreshTokenTTL)

	if _, err := s.repo.CreateRefreshSession(ctx, u.ID, refreshHash, expiresAt, userAgent); err != nil {
		return TokenPair{}, err
	}

	return TokenPair{
		AccessToken:  access,
		RefreshToken: refreshToken,
		ExpiresIn:    int64(s.tokens.AccessTokenTTL().Seconds()),
	}, nil
}

func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}
