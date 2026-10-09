package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// Claims are the custom JWT claims for access tokens.
type Claims struct {
	Role string `json:"role"`
	jwt.RegisteredClaims
}

// TokenService issues and parses HS256 access tokens and generates opaque
// refresh tokens.
type TokenService struct {
	secret         []byte
	accessTokenTTL time.Duration
}

// NewTokenService constructs a TokenService.
func NewTokenService(secret string, accessTokenTTL time.Duration) *TokenService {
	return &TokenService{
		secret:         []byte(secret),
		accessTokenTTL: accessTokenTTL,
	}
}

// AccessTokenTTL returns the configured access token lifetime.
func (ts *TokenService) AccessTokenTTL() time.Duration {
	return ts.accessTokenTTL
}

// Issue creates a signed access token for the given user and role.
func (ts *TokenService) Issue(userID int64, role string) (string, error) {
	now := time.Now()
	claims := Claims{
		Role: role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   encodeID(userID),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(ts.accessTokenTTL)),
			ID:        uuid.NewString(),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(ts.secret)
	if err != nil {
		return "", fmt.Errorf("auth: sign access token: %w", err)
	}
	return signed, nil
}

// Parse validates a signed access token and returns its claims.
func (ts *TokenService) Parse(tokenString string) (*Claims, error) {
	claims := &Claims{}
	_, err := jwt.ParseWithClaims(tokenString, claims, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("auth: unexpected signing method: %v", t.Header["alg"])
		}
		return ts.secret, nil
	}, jwt.WithValidMethods([]string{"HS256"}))
	if err != nil {
		return nil, fmt.Errorf("auth: parse access token: %w", err)
	}
	return claims, nil
}

// refreshTokenBytes is the entropy size of an opaque refresh token.
const refreshTokenBytes = 32

// GenerateRefreshToken returns a new opaque refresh token (base64url, no
// padding) alongside its SHA-256 hex hash for storage.
func GenerateRefreshToken() (token string, hash string, err error) {
	buf := make([]byte, refreshTokenBytes)
	if _, err := rand.Read(buf); err != nil {
		return "", "", fmt.Errorf("auth: generate refresh token: %w", err)
	}
	token = base64.RawURLEncoding.EncodeToString(buf)
	return token, HashRefreshToken(token), nil
}

// HashRefreshToken returns the SHA-256 hex digest of an opaque refresh token.
// Only this hash is ever stored.
func HashRefreshToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}
