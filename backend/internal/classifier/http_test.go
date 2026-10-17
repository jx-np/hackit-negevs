package classifier

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"slices"
	"sync"
	"testing"
)

// aiStub is a minimal fake AI service serving the two classification endpoints.
// The zero status means 200.
type aiStub struct {
	catStatus int
	catBody   string
	tagStatus int
	tagBody   string

	mu        sync.Mutex
	gotText   string
	gotLocale string
	calls     int
}

func (s *aiStub) server(t *testing.T) *httptest.Server {
	t.Helper()
	record := func(r *http.Request) {
		var req classifyRequest
		_ = json.NewDecoder(r.Body).Decode(&req)
		s.mu.Lock()
		defer s.mu.Unlock()
		s.gotText = req.Text
		s.gotLocale = req.Locale
		s.calls++
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/v1/classify/category", func(w http.ResponseWriter, r *http.Request) {
		record(r)
		if s.catStatus != 0 {
			w.WriteHeader(s.catStatus)
		}
		_, _ = io.WriteString(w, s.catBody)
	})
	mux.HandleFunc("/v1/classify/tags", func(w http.ResponseWriter, r *http.Request) {
		record(r)
		if s.tagStatus != 0 {
			w.WriteHeader(s.tagStatus)
		}
		_, _ = io.WriteString(w, s.tagBody)
	})
	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return srv
}

func (s *aiStub) recorded() (string, string, int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.gotText, s.gotLocale, s.calls
}

func catJSON(slug string) string {
	b, _ := json.Marshal(map[string]any{"category": slug, "confidence": 0.9, "degraded": false})
	return string(b)
}

func tagsJSON(scores map[string]float64) string {
	b, _ := json.Marshal(map[string]any{"scores": scores, "degraded": false})
	return string(b)
}

func TestHTTPClassifierKeepsTagsAtOrAboveThreshold(t *testing.T) {
	stub := &aiStub{
		catBody: catJSON("phishing"),
		tagBody: tagsJSON(map[string]float64{
			"phishing":      0.9,
			"otp-scam":      0.5,
			"money-request": 0.3, // exactly at threshold: kept
			"prize-scam":    0.2, // below threshold: dropped
		}),
	}
	srv := stub.server(t)
	c := NewHTTPClassifier(srv.URL, 0.3)

	got, err := c.Classify(context.Background(), "verify your otp", "en-SG")
	if err != nil {
		t.Fatalf("Classify error: %v", err)
	}
	if got.Slug != "phishing" {
		t.Errorf("Slug = %q, want phishing", got.Slug)
	}
	if got.Confidence != 0.9 {
		t.Errorf("Confidence = %v, want 0.9", got.Confidence)
	}
	want := []string{"phishing", "otp-scam", "money-request"}
	if !slices.Equal(got.Tags, want) {
		t.Errorf("Tags = %v, want %v", got.Tags, want)
	}
	text, locale, calls := stub.recorded()
	if text != "verify your otp" || locale != "en-SG" {
		t.Errorf("request = (%q, %q), want (verify your otp, en-SG)", text, locale)
	}
	if calls != 2 {
		t.Errorf("calls = %d, want 2 (category + tags)", calls)
	}
}

func TestHTTPClassifierDefaultThresholdWhenNonPositive(t *testing.T) {
	stub := &aiStub{
		catBody: catJSON("phishing"),
		tagBody: tagsJSON(map[string]float64{"phishing": 0.5, "otp-scam": 0.29}),
	}
	srv := stub.server(t)
	c := NewHTTPClassifier(srv.URL, 0)
	if c.tagThreshold != DefaultTagThreshold {
		t.Fatalf("tagThreshold = %v, want %v", c.tagThreshold, DefaultTagThreshold)
	}

	got, err := c.Classify(context.Background(), "x", "en-SG")
	if err != nil {
		t.Fatalf("Classify error: %v", err)
	}
	want := []string{"phishing"} // 0.29 < 0.30 default
	if !slices.Equal(got.Tags, want) {
		t.Errorf("Tags = %v, want %v", got.Tags, want)
	}
}

func TestHTTPClassifierDeterministicOrderOnTies(t *testing.T) {
	stub := &aiStub{
		catBody: catJSON("phishing"),
		tagBody: tagsJSON(map[string]float64{"phishing": 0.5, "otp-scam": 0.5}),
	}
	srv := stub.server(t)
	c := NewHTTPClassifier(srv.URL, 0.3)

	got, err := c.Classify(context.Background(), "x", "en-SG")
	if err != nil {
		t.Fatalf("Classify error: %v", err)
	}
	want := []string{"otp-scam", "phishing"} // equal score -> slug ascending
	if !slices.Equal(got.Tags, want) {
		t.Errorf("Tags = %v, want %v", got.Tags, want)
	}
}

func TestHTTPClassifierCategoryDegradedIsError(t *testing.T) {
	stub := &aiStub{
		catBody: `{"category":"","confidence":0,"degraded":true}`,
		tagBody: tagsJSON(map[string]float64{"phishing": 0.9}),
	}
	srv := stub.server(t)
	c := NewHTTPClassifier(srv.URL, 0.3)

	if _, err := c.Classify(context.Background(), "x", "en-SG"); !errors.Is(err, ErrUnavailable) {
		t.Fatalf("err = %v, want ErrUnavailable", err)
	}
}

func TestHTTPClassifierCategoryEmptyIsError(t *testing.T) {
	stub := &aiStub{
		catBody: `{"category":"","confidence":0.9,"degraded":false}`,
		tagBody: tagsJSON(map[string]float64{"phishing": 0.9}),
	}
	srv := stub.server(t)
	c := NewHTTPClassifier(srv.URL, 0.3)

	if _, err := c.Classify(context.Background(), "x", "en-SG"); !errors.Is(err, ErrUnavailable) {
		t.Fatalf("err = %v, want ErrUnavailable", err)
	}
}

func TestHTTPClassifierCategoryNon200IsError(t *testing.T) {
	stub := &aiStub{
		catStatus: http.StatusInternalServerError,
		catBody:   "boom",
		tagBody:   tagsJSON(map[string]float64{"phishing": 0.9}),
	}
	srv := stub.server(t)
	c := NewHTTPClassifier(srv.URL, 0.3)

	if _, err := c.Classify(context.Background(), "x", "en-SG"); !errors.Is(err, ErrUnavailable) {
		t.Fatalf("err = %v, want ErrUnavailable", err)
	}
}

func TestHTTPClassifierTagsFailureKeepsCategory(t *testing.T) {
	stub := &aiStub{
		catBody:   catJSON("phishing"),
		tagStatus: http.StatusInternalServerError,
		tagBody:   "boom",
	}
	srv := stub.server(t)
	c := NewHTTPClassifier(srv.URL, 0.3)

	got, err := c.Classify(context.Background(), "x", "en-SG")
	if err != nil {
		t.Fatalf("Classify error: %v, want nil (tags are advisory)", err)
	}
	if got.Slug != "phishing" {
		t.Errorf("Slug = %q, want phishing", got.Slug)
	}
	if len(got.Tags) != 0 {
		t.Errorf("Tags = %v, want none", got.Tags)
	}
}

func TestHTTPClassifierTagsDegradedKeepsCategory(t *testing.T) {
	stub := &aiStub{
		catBody: catJSON("phishing"),
		tagBody: `{"scores":{},"degraded":true}`,
	}
	srv := stub.server(t)
	c := NewHTTPClassifier(srv.URL, 0.3)

	got, err := c.Classify(context.Background(), "x", "en-SG")
	if err != nil {
		t.Fatalf("Classify error: %v, want nil", err)
	}
	if got.Slug != "phishing" || len(got.Tags) != 0 {
		t.Errorf("result = %+v, want slug phishing and no tags", got)
	}
}

func TestHTTPClassifierTrimsTrailingSlash(t *testing.T) {
	stub := &aiStub{catBody: catJSON("phishing"), tagBody: tagsJSON(nil)}
	srv := stub.server(t)
	c := NewHTTPClassifier(srv.URL+"/", 0.3)

	if _, err := c.Classify(context.Background(), "x", "en-SG"); err != nil {
		t.Fatalf("Classify error: %v", err)
	}
	if c.baseURL != srv.URL {
		t.Errorf("baseURL = %q, want %q", c.baseURL, srv.URL)
	}
}
