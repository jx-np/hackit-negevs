package news

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

// stubRepository is a Repository backed by fixed values.
type stubRepository struct {
	articles []Article
	err      error
}

func (s *stubRepository) ListArticles(context.Context) ([]Article, error) {
	return s.articles, s.err
}

func TestListArticlesResponseShape(t *testing.T) {
	repo := &stubRepository{articles: []Article{
		{
			ID:   1,
			Slug: "news-1",
			Icon: "message_square_warning",
			Translations: map[string]Translation{
				"en": {Locale: "en", Title: "Fake bank SMS", Body: "Never tap links."},
				"ms": {Locale: "ms", Title: "SMS palsu", Body: "Jangan klik pautan."},
			},
		},
	}}
	h := NewHandler(NewService(repo))

	rec := httptest.NewRecorder()
	h.listArticles(rec, httptest.NewRequest(http.MethodGet, "/api/v1/news", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}

	var body struct {
		Articles []struct {
			ID    string            `json:"id"`
			Icon  string            `json:"icon"`
			Title map[string]string `json:"title"`
			Text  map[string]string `json:"text"`
		} `json:"articles"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode body: %v", err)
	}
	if len(body.Articles) != 1 {
		t.Fatalf("articles = %d, want 1", len(body.Articles))
	}
	got := body.Articles[0]
	if got.ID != "news-1" {
		t.Errorf("id = %q, want news-1 (the slug)", got.ID)
	}
	if got.Icon != "message_square_warning" {
		t.Errorf("icon = %q", got.Icon)
	}
	if got.Title["en"] != "Fake bank SMS" || got.Text["en"] != "Never tap links." {
		t.Errorf("en translation mismatch: %+v", got)
	}
	if got.Title["ms"] != "SMS palsu" || got.Text["ms"] != "Jangan klik pautan." {
		t.Errorf("ms translation mismatch: %+v", got)
	}
}

func TestListArticlesEmptyIsArray(t *testing.T) {
	h := NewHandler(NewService(&stubRepository{}))

	rec := httptest.NewRecorder()
	h.listArticles(rec, httptest.NewRequest(http.MethodGet, "/api/v1/news", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	// An empty feed must serialize as [] rather than null so clients can iterate
	// without a nil check.
	if got := rec.Body.String(); got != "{\"articles\":[]}\n" {
		t.Errorf("body = %q, want empty articles array", got)
	}
}

func TestListArticlesRepositoryError(t *testing.T) {
	h := NewHandler(NewService(&stubRepository{err: errors.New("boom")}))

	rec := httptest.NewRecorder()
	h.listArticles(rec, httptest.NewRequest(http.MethodGet, "/api/v1/news", nil))

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusInternalServerError)
	}
}
