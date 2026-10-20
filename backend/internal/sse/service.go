package sse

import "context"

// Service is the transport-agnostic seam for the SSE endpoint's business
// rules. Today that is only the public-visibility check; keeping it here means
// the handler never talks to the database directly.
type Service struct {
	repo Repository
}

// NewService constructs an SSE Service.
func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// PostVisible reports whether a post exists and is publicly visible. A
// repository failure is returned as-is (the handler maps it to 500), never
// collapsed into "not found".
func (s *Service) PostVisible(ctx context.Context, reportID int64) (bool, error) {
	return s.repo.PostVisible(ctx, reportID)
}
