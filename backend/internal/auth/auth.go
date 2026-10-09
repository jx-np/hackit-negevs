// Package auth implements the authentication domain: registration, login,
// token refresh with rotation, logout, and the authenticated profile endpoint.
package auth

import (
	"errors"
	"strconv"
	"time"
)

// Roles supported by the system (mirrors the users.role CHECK constraint).
const (
	RoleResident  = "resident"
	RoleHelper    = "helper"
	RoleModerator = "moderator"
	RoleAdmin     = "admin"
)

// Domain errors surfaced by the service layer and mapped to HTTP statuses by
// handlers.
var (
	// ErrInvalidCredentials is returned for any login failure. It is
	// intentionally generic to avoid revealing whether an email exists.
	ErrInvalidCredentials = errors.New("auth: invalid credentials")
	// ErrEmailTaken is returned when registering a duplicate normalized email.
	ErrEmailTaken = errors.New("auth: email already registered")
	// ErrPasswordTooLong is returned when a password exceeds bcrypt's 72-byte limit.
	ErrPasswordTooLong = errors.New("auth: password exceeds 72 bytes")
	// ErrInvalidRefreshToken is returned when a refresh token is unknown,
	// expired, or malformed.
	ErrInvalidRefreshToken = errors.New("auth: invalid refresh token")
	// ErrRefreshTokenReused is returned when an already-revoked refresh token is
	// presented, indicating possible theft.
	ErrRefreshTokenReused = errors.New("auth: refresh token reused")
	// ErrUserNotFound is returned when a user lookup yields no row.
	ErrUserNotFound = errors.New("auth: user not found")
)

// User is the internal representation of a user row.
type User struct {
	ID          int64
	Email       string
	DisplayName string
	Role        string
	Locale      string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// Principal is the authenticated identity attached to a request context.
type Principal struct {
	UserID int64
	Role   string
}

// RefreshSession is the internal representation of a refresh_sessions row.
type RefreshSession struct {
	ID                  int64
	UserID              int64
	TokenHash           string
	CreatedAt           time.Time
	ExpiresAt           time.Time
	RevokedAt           *time.Time
	ReplacedBySessionID *int64
	UserAgent           *string
}

// IsRevoked reports whether the session has been revoked.
func (s RefreshSession) IsRevoked() bool {
	return s.RevokedAt != nil
}

// IsExpired reports whether the session has expired at the given time.
func (s RefreshSession) IsExpired(now time.Time) bool {
	return !now.Before(s.ExpiresAt)
}

// encodeID serializes a bigint PK as an opaque string for JSON output.
func encodeID(id int64) string {
	return strconv.FormatInt(id, 10)
}
