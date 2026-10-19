package news

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Repository is the persistence contract for the news domain.
type Repository interface {
	// ListArticles returns active articles ordered by sort_order, each with all
	// of its translations.
	ListArticles(ctx context.Context) ([]Article, error)
}

// PostgresRepository is a pgx-backed Repository.
type PostgresRepository struct {
	pool *pgxpool.Pool
}

// NewPostgresRepository constructs a PostgresRepository.
func NewPostgresRepository(pool *pgxpool.Pool) *PostgresRepository {
	return &PostgresRepository{pool: pool}
}

// ListArticles implements Repository. Rows are grouped into articles in query
// order, so no sorting is needed in Go.
func (r *PostgresRepository) ListArticles(ctx context.Context) ([]Article, error) {
	const q = `
		SELECT
			a.id, a.slug, a.icon, a.sort_order,
			t.locale, t.title, t.body
		FROM news_articles a
		JOIN news_article_translations t ON t.article_id = a.id
		WHERE a.active = true
		ORDER BY a.sort_order ASC, a.id ASC, t.locale ASC`

	rows, err := r.pool.Query(ctx, q)
	if err != nil {
		return nil, fmt.Errorf("news: query articles: %w", err)
	}
	defer rows.Close()

	var (
		out    []Article
		lastID int64
	)
	for rows.Next() {
		var (
			id   int64
			slug string
			icon string
			sort int
			tr   Translation
		)
		if err := rows.Scan(&id, &slug, &icon, &sort, &tr.Locale, &tr.Title, &tr.Body); err != nil {
			return nil, fmt.Errorf("news: scan article: %w", err)
		}
		if len(out) == 0 || id != lastID {
			out = append(out, Article{
				ID:           id,
				Slug:         slug,
				Icon:         icon,
				SortOrder:    sort,
				Translations: make(map[string]Translation),
			})
			lastID = id
		}
		out[len(out)-1].Translations[tr.Locale] = tr
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("news: iterate articles: %w", err)
	}
	return out, nil
}
