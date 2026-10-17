package classifier

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strings"
	"time"
)

// DefaultTagThreshold is the minimum model probability a predicted tag must
// reach to be attached to a post. Tags scored below it are dropped. It is used
// when a non-positive threshold is configured.
const DefaultTagThreshold = 0.30

// classifierAttemptTimeout bounds a single HTTP attempt to the AI service. It
// comfortably exceeds the service's own downstream model timeout (~30s) so a
// slow but healthy model response is not cut off prematurely.
const classifierAttemptTimeout = 35 * time.Second

// ErrUnavailable reports that the decision-model service could not produce a
// usable classification (transport error, non-200 status, undecodable body,
// degraded response, or a missing category). The caller leaves the post
// unclassified rather than failing the publish.
var ErrUnavailable = errors.New("classifier: service unavailable")

// classifyRequest is the request envelope shared by the AI service's
// classification endpoints: the message text and its locale. The text is sent
// in the request body and never logged.
type classifyRequest struct {
	Text   string `json:"text"`
	Locale string `json:"locale"`
}

// categoryResponse is the wire shape of POST /v1/classify/category. Only the
// fields the classifier consumes are decoded.
type categoryResponse struct {
	Category   string  `json:"category"`
	Confidence float64 `json:"confidence"`
	Degraded   bool    `json:"degraded"`
}

// tagsResponse is the wire shape of POST /v1/classify/tags. Scores maps tag
// slug to probability.
type tagsResponse struct {
	Scores   map[string]float64 `json:"scores"`
	Degraded bool               `json:"degraded"`
}

// HTTPClassifier assigns a community post's category and tags by calling the
// Python AI service: POST /v1/classify/category (required) and
// POST /v1/classify/tags (advisory), issued concurrently. It satisfies the
// Classifier port and is safe for concurrent use.
//
// PRIVACY: the message text is sent in the request body and is never logged or
// retained. The returned Reason is content-free.
type HTTPClassifier struct {
	baseURL      string
	client       *http.Client
	tagThreshold float64
}

// NewHTTPClassifier builds a classifier for the AI service at baseURL.
// tagThreshold is the minimum tag probability to keep; a non-positive value
// falls back to DefaultTagThreshold.
func NewHTTPClassifier(baseURL string, tagThreshold float64) *HTTPClassifier {
	if tagThreshold <= 0 {
		tagThreshold = DefaultTagThreshold
	}
	return &HTTPClassifier{
		baseURL:      strings.TrimRight(baseURL, "/"),
		client:       &http.Client{Timeout: classifierAttemptTimeout},
		tagThreshold: tagThreshold,
	}
}

// Classify resolves the category and tags for text. The category is required:
// any failure to produce one is returned as an error so the post stays
// unclassified. Tags are advisory — if the tags call fails, the category is
// still returned with no tags.
func (c *HTTPClassifier) Classify(ctx context.Context, text, locale string) (Result, error) {
	type catOutcome struct {
		slug string
		conf float64
		err  error
	}
	type tagOutcome struct {
		tags []string
		err  error
	}

	catCh := make(chan catOutcome, 1)
	go func() {
		slug, conf, err := c.classifyCategory(ctx, text, locale)
		catCh <- catOutcome{slug: slug, conf: conf, err: err}
	}()

	// The tags call runs concurrently but its result is best-effort: the
	// buffered channel lets the goroutine finish even if we return early on a
	// category error.
	tagCh := make(chan tagOutcome, 1)
	go func() {
		tags, err := c.classifyTags(ctx, text, locale)
		tagCh <- tagOutcome{tags: tags, err: err}
	}()

	cat := <-catCh
	if cat.err != nil {
		return Result{}, cat.err
	}

	var tags []string
	if t := <-tagCh; t.err == nil {
		tags = t.tags
	}

	return Result{
		Slug:       cat.slug,
		Confidence: cat.conf,
		Reason:     fmt.Sprintf("http classifier: %d tag(s)", len(tags)),
		Tags:       tags,
	}, nil
}

// classifyCategory calls /v1/classify/category and returns the predicted
// category slug. A degraded response or missing category is an error.
func (c *HTTPClassifier) classifyCategory(ctx context.Context, text, locale string) (string, float64, error) {
	var resp categoryResponse
	if err := c.post(ctx, "/v1/classify/category", text, locale, &resp); err != nil {
		return "", 0, err
	}
	if resp.Degraded {
		return "", 0, fmt.Errorf("%w: category service degraded", ErrUnavailable)
	}
	slug := strings.TrimSpace(resp.Category)
	if slug == "" {
		return "", 0, fmt.Errorf("%w: category response missing category", ErrUnavailable)
	}
	return slug, resp.Confidence, nil
}

// classifyTags calls /v1/classify/tags and returns the tag slugs whose score
// meets the threshold, ordered by descending score then ascending slug. A
// degraded response is an error; the caller then reports the category alone.
func (c *HTTPClassifier) classifyTags(ctx context.Context, text, locale string) ([]string, error) {
	var resp tagsResponse
	if err := c.post(ctx, "/v1/classify/tags", text, locale, &resp); err != nil {
		return nil, err
	}
	if resp.Degraded {
		return nil, fmt.Errorf("%w: tag service degraded", ErrUnavailable)
	}
	return c.selectTags(resp.Scores), nil
}

// selectTags keeps every non-empty slug whose score reaches the threshold, in a
// deterministic order (score descending, then slug ascending) so repeated
// classifications of the same message are stable.
func (c *HTTPClassifier) selectTags(scores map[string]float64) []string {
	type scored struct {
		slug  string
		score float64
	}
	kept := make([]scored, 0, len(scores))
	for slug, score := range scores {
		if slug == "" || score < c.tagThreshold {
			continue
		}
		kept = append(kept, scored{slug: slug, score: score})
	}
	sort.Slice(kept, func(i, j int) bool {
		if kept[i].score != kept[j].score {
			return kept[i].score > kept[j].score
		}
		return kept[i].slug < kept[j].slug
	})
	tags := make([]string, len(kept))
	for i, s := range kept {
		tags[i] = s.slug
	}
	return tags
}

// post marshals the shared classify request, POSTs it to path, and decodes the
// 200 response into out. Any transport error, non-200 status, or decode failure
// is wrapped in ErrUnavailable. The request body is never logged.
func (c *HTTPClassifier) post(ctx context.Context, path, text, locale string, out any) error {
	payload, err := json.Marshal(classifyRequest{Text: text, Locale: locale})
	if err != nil {
		return fmt.Errorf("%w: encode request: %v", ErrUnavailable, err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(payload))
	if err != nil {
		return fmt.Errorf("%w: %v", ErrUnavailable, err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("%w: %v", ErrUnavailable, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		// Drain a bounded amount so the connection can be reused; the body is
		// discarded, never logged.
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
		return fmt.Errorf("%w: status %d", ErrUnavailable, resp.StatusCode)
	}

	if err := json.NewDecoder(resp.Body).Decode(out); err != nil {
		return fmt.Errorf("%w: decode response: %v", ErrUnavailable, err)
	}
	return nil
}
