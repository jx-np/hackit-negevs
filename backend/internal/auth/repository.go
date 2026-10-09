package auth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Repository is the persistence contract for the auth domain.
type Repository interface {
	// CreateUserWithPassword inserts a user and its password credential inside a
	// single transaction. Returns ErrEmailTaken on a duplicate normalized email.
	CreateUserWithPassword(ctx context.Context, u User, emailNormalized, passwordHash string) (User, error)
	// GetUserByEmailNormalized returns the user and stored password hash for a
	// normalized email. Returns ErrUserNotFound if absent.
	GetUserByEmailNormalized(ctx context.Context, emailNormalized string) (User, string, error)
	// GetUserByID returns a user by primary key. Returns ErrUserNotFound if absent.
	GetUserByID(ctx context.Context, id int64) (User, error)
	// CreateRefreshSession inserts a new refresh session.
	CreateRefreshSession(ctx context.Context, userID int64, tokenHash string, expiresAt time.Time, userAgent string) (RefreshSession, error)
	// GetRefreshSessionByTokenHash returns a session by its token hash. Returns
	// ErrInvalidRefreshToken if absent.
	GetRefreshSessionByTokenHash(ctx context.Context, tokenHash string) (RefreshSession, error)
	// RevokeSession marks a single session revoked. Idempotent.
	RevokeSession(ctx context.Context, sessionID int64) error
	// RevokeAllUserSessions revokes every active session for a user (used on
	// suspected refresh-token reuse).
	RevokeAllUserSessions(ctx context.Context, userID int64) error
	// RotateSession atomically creates a new session and marks the old one
	// revoked with replaced_by_session_id set to the new session.
	RotateSession(ctx context.Context, oldSessionID, userID int64, newTokenHash string, expiresAt time.Time, userAgent string) (RefreshSession, error)
}

// PostgresRepository is a pgx-backed Repository.
type PostgresRepository struct {
	pool *pgxpool.Pool
}

// NewPostgresRepository constructs a PostgresRepository.
func NewPostgresRepository(pool *pgxpool.Pool) *PostgresRepository {
	return &PostgresRepository{pool: pool}
}

const uniqueViolationCode = "23505"

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == uniqueViolationCode
	}
	return false
}

// CreateUserWithPassword implements Repository.
func (r *PostgresRepository) CreateUserWithPassword(ctx context.Context, u User, emailNormalized, passwordHash string) (User, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return User{}, fmt.Errorf("auth: begin tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	const insertUser = `
		INSERT INTO users (email, email_normalized, display_name, role, locale)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at`
	var created User = u
	err = tx.QueryRow(ctx, insertUser, u.Email, emailNormalized, u.DisplayName, u.Role, u.Locale).
		Scan(&created.ID, &created.CreatedAt, &created.UpdatedAt)
	if err != nil {
		if isUniqueViolation(err) {
			return User{}, ErrEmailTaken
		}
		return User{}, fmt.Errorf("auth: insert user: %w", err)
	}

	const insertCred = `
		INSERT INTO password_credentials (user_id, password_hash)
		VALUES ($1, $2)`
	if _, err := tx.Exec(ctx, insertCred, created.ID, passwordHash); err != nil {
		return User{}, fmt.Errorf("auth: insert password credential: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return User{}, fmt.Errorf("auth: commit tx: %w", err)
	}
	return created, nil
}

// GetUserByEmailNormalized implements Repository.
func (r *PostgresRepository) GetUserByEmailNormalized(ctx context.Context, emailNormalized string) (User, string, error) {
	const q = `
		SELECT u.id, u.email, u.display_name, u.role, u.locale, u.created_at, u.updated_at, c.password_hash
		FROM users u
		JOIN password_credentials c ON c.user_id = u.id
		WHERE u.email_normalized = $1`
	var u User
	var email *string
	var hash string
	err := r.pool.QueryRow(ctx, q, emailNormalized).
		Scan(&u.ID, &email, &u.DisplayName, &u.Role, &u.Locale, &u.CreatedAt, &u.UpdatedAt, &hash)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return User{}, "", ErrUserNotFound
		}
		return User{}, "", fmt.Errorf("auth: get user by email: %w", err)
	}
	if email != nil {
		u.Email = *email
	}
	return u, hash, nil
}

// GetUserByID implements Repository.
func (r *PostgresRepository) GetUserByID(ctx context.Context, id int64) (User, error) {
	const q = `
		SELECT id, email, display_name, role, locale, created_at, updated_at
		FROM users
		WHERE id = $1`
	var u User
	var email *string
	err := r.pool.QueryRow(ctx, q, id).
		Scan(&u.ID, &email, &u.DisplayName, &u.Role, &u.Locale, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return User{}, ErrUserNotFound
		}
		return User{}, fmt.Errorf("auth: get user by id: %w", err)
	}
	if email != nil {
		u.Email = *email
	}
	return u, nil
}

// CreateRefreshSession implements Repository.
func (r *PostgresRepository) CreateRefreshSession(ctx context.Context, userID int64, tokenHash string, expiresAt time.Time, userAgent string) (RefreshSession, error) {
	return insertRefreshSession(ctx, r.pool, userID, tokenHash, expiresAt, userAgent)
}

// GetRefreshSessionByTokenHash implements Repository.
func (r *PostgresRepository) GetRefreshSessionByTokenHash(ctx context.Context, tokenHash string) (RefreshSession, error) {
	const q = `
		SELECT id, user_id, token_hash, created_at, expires_at, revoked_at, replaced_by_session_id, user_agent
		FROM refresh_sessions
		WHERE token_hash = $1`
	var s RefreshSession
	err := r.pool.QueryRow(ctx, q, tokenHash).
		Scan(&s.ID, &s.UserID, &s.TokenHash, &s.CreatedAt, &s.ExpiresAt, &s.RevokedAt, &s.ReplacedBySessionID, &s.UserAgent)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return RefreshSession{}, ErrInvalidRefreshToken
		}
		return RefreshSession{}, fmt.Errorf("auth: get refresh session: %w", err)
	}
	return s, nil
}

// RevokeSession implements Repository.
func (r *PostgresRepository) RevokeSession(ctx context.Context, sessionID int64) error {
	const q = `UPDATE refresh_sessions SET revoked_at = now() WHERE id = $1 AND revoked_at IS NULL`
	if _, err := r.pool.Exec(ctx, q, sessionID); err != nil {
		return fmt.Errorf("auth: revoke session: %w", err)
	}
	return nil
}

// RevokeAllUserSessions implements Repository.
func (r *PostgresRepository) RevokeAllUserSessions(ctx context.Context, userID int64) error {
	const q = `UPDATE refresh_sessions SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL`
	if _, err := r.pool.Exec(ctx, q, userID); err != nil {
		return fmt.Errorf("auth: revoke all user sessions: %w", err)
	}
	return nil
}

// RotateSession implements Repository.
func (r *PostgresRepository) RotateSession(ctx context.Context, oldSessionID, userID int64, newTokenHash string, expiresAt time.Time, userAgent string) (RefreshSession, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return RefreshSession{}, fmt.Errorf("auth: begin rotate tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	newSession, err := insertRefreshSession(ctx, tx, userID, newTokenHash, expiresAt, userAgent)
	if err != nil {
		return RefreshSession{}, err
	}

	const revoke = `
		UPDATE refresh_sessions
		SET revoked_at = now(), replaced_by_session_id = $2
		WHERE id = $1`
	if _, err := tx.Exec(ctx, revoke, oldSessionID, newSession.ID); err != nil {
		return RefreshSession{}, fmt.Errorf("auth: revoke rotated session: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return RefreshSession{}, fmt.Errorf("auth: commit rotate tx: %w", err)
	}
	return newSession, nil
}

// querier abstracts *pgxpool.Pool and pgx.Tx for shared inserts.
type querier interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func insertRefreshSession(ctx context.Context, q querier, userID int64, tokenHash string, expiresAt time.Time, userAgent string) (RefreshSession, error) {
	const insert = `
		INSERT INTO refresh_sessions (user_id, token_hash, expires_at, user_agent)
		VALUES ($1, $2, $3, $4)
		RETURNING id, user_id, token_hash, created_at, expires_at, revoked_at, replaced_by_session_id, user_agent`
	var ua *string
	if userAgent != "" {
		ua = &userAgent
	}
	var s RefreshSession
	err := q.QueryRow(ctx, insert, userID, tokenHash, expiresAt, ua).
		Scan(&s.ID, &s.UserID, &s.TokenHash, &s.CreatedAt, &s.ExpiresAt, &s.RevokedAt, &s.ReplacedBySessionID, &s.UserAgent)
	if err != nil {
		return RefreshSession{}, fmt.Errorf("auth: insert refresh session: %w", err)
	}
	return s, nil
}
