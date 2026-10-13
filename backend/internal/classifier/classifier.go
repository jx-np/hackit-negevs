// Package classifier assigns a scam category to a published community post.
//
// The classifier is deliberately separated from the posts domain: it is a pure,
// transport-agnostic port that a model-backed implementation can later satisfy
// (e.g. by calling the Python decision-model service described in AGENTS.md).
// Until then the wired implementation is Stub, which returns a fixed category.
//
// PRIVACY: implementations receive already-scrubbed, length-bounded text and
// must never log it. Only the returned slug and non-content metadata may be
// logged or persisted.
package classifier

import "context"

// Result is a classification outcome. Slug is a categories.slug value; an empty
// Slug means "unclassified" and the post stays private to its author until a
// later classification succeeds.
type Result struct {
	// Slug is the predicted category slug (e.g. "phishing"). Empty means no
	// prediction was produced.
	Slug string
	// Confidence is a 0..1 self-reported score. Advisory only.
	Confidence float64
	// Reason is a short non-content explanation, safe to log.
	Reason string
}

// Classifier predicts the scam category of a message. It is safe for concurrent
// use. Implementations must be deterministic for a given input where possible
// and must not retain the text passed to Classify.
type Classifier interface {
	// Classify returns a prediction for text in the given locale (e.g. "en-SG").
	// Returning an error leaves the post unclassified rather than failing it.
	Classify(ctx context.Context, text string, locale string) (Result, error)
}

// Stub is the placeholder implementation used until the decision-model service
// is available. It always reports the same category.
type Stub struct {
	// Slug is the category returned for every input. Defaults to DefaultSlug.
	Slug string
	// Confidence is the fixed confidence reported alongside Slug.
	Confidence float64
}

// DefaultSlug is the category the stub reports for every message.
const DefaultSlug = "phishing"

// NewStub returns a Stub with the default slug and full confidence.
func NewStub() *Stub {
	return &Stub{Slug: DefaultSlug, Confidence: 1}
}

// Classify implements Classifier. The text argument is ignored and never
// logged or retained.
func (s *Stub) Classify(_ context.Context, _ string, _ string) (Result, error) {
	slug := s.Slug
	if slug == "" {
		slug = DefaultSlug
	}
	return Result{
		Slug:       slug,
		Confidence: s.Confidence,
		Reason:     "stub classifier",
	}, nil
}

// Classified reports whether a result carries a usable slug.
func (r Result) Classified() bool { return r.Slug != "" }
