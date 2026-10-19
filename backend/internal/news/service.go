package news

import "context"

// Service holds news business logic. It is transport-agnostic.
type Service struct {
	repo Repository
}

// NewService constructs a news Service.
func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// ListArticles returns active news articles with all of their translations.
func (s *Service) ListArticles(ctx context.Context) ([]Article, error) {
	return s.repo.ListArticles(ctx)
}
