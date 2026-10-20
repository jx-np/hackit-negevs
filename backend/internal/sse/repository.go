package sse

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Repository is the persistence seam for the SSE endpoint. The handler only
// needs the public-visibility predicate; it never touches the database itself.
type Repository interface {
	// PostVisible reports whether a post exists and is publicly visible:
	// not deleted, not hidden/removed, and classified. It mirrors
	// moderation.PostgresRepository.ReportVisible exactly.
	PostVisible(ctx context.Context, reportID int64) (bool, error)
}

// PostgresRepository is a pgx-backed Repository.
type PostgresRepository struct {
	pool *pgxpool.Pool
}

// NewPostgresRepository constructs a PostgresRepository.
func NewPostgresRepository(pool *pgxpool.Pool) *PostgresRepository {
	return &PostgresRepository{pool: pool}
}

// PostVisible implements Repository.
func (r *PostgresRepository) PostVisible(ctx context.Context, reportID int64) (bool, error) {
	const q = `
		SELECT EXISTS (
			SELECT 1 FROM reports
			WHERE id = $1 AND deleted_at IS NULL
			  AND review_status NOT IN ('hidden', 'removed')
			  AND category_id IS NOT NULL
		)`
	var ok bool
	if err := r.pool.QueryRow(ctx, q, reportID).Scan(&ok); err != nil {
		return false, fmt.Errorf("sse: report visible: %w", err)
	}
	return ok, nil
}
