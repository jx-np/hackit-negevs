package checks

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// Defaults for the bounded classification queue that fronts the AI service.
const (
	// DefaultClassifierWorkers caps how many classification requests may be in
	// flight to the AI service at once.
	DefaultClassifierWorkers = 2
	// DefaultClassifierRetries is how many times a failed classification is
	// retried (after the initial attempt) before it is reported as failed.
	DefaultClassifierRetries = 2

	// defaultClassifierQueueSize bounds how many classifications may be waiting
	// in the queue before submitters block (backpressure).
	defaultClassifierQueueSize = 128

	// classifierRetryBackoff is the base delay between retries; it grows
	// linearly per attempt to give a transient outage a moment to clear.
	classifierRetryBackoff = 200 * time.Millisecond

	// classifierAttemptTimeout bounds a single HTTP attempt. It comfortably
	// exceeds the AI service's own downstream model timeout (~30s) so a slow
	// but healthy model response is not cut off prematurely.
	classifierAttemptTimeout = 35 * time.Second
)

// Classifier produces an explainable assessment for a message. It is the seam
// to the AI service's decision model (POST /v1/classify). Implementations must
// never log the submitted text.
//
// A nil Classifier means no classification backend is configured; the service
// then fails checks rather than synthesizing a verdict.
type Classifier interface {
	Classify(ctx context.Context, text, locale string) (Assessment, error)
}

// classifyRequest is the AI service's ClassifyRequest envelope: the message text
// and its locale. The text is sent in the request body and never logged.
type classifyRequest struct {
	Text   string `json:"text"`
	Locale string `json:"locale"`
}

// HTTPClassifier calls the Python AI service's POST /v1/classify endpoint and
// decodes the returned Assessment. That service also performs PII redaction, so
// the base URL is the shared AI service URL (PII_SERVICE_URL).
type HTTPClassifier struct {
	baseURL string
	client  *http.Client
}

// NewHTTPClassifier builds a classifier for the AI service at baseURL.
func NewHTTPClassifier(baseURL string) *HTTPClassifier {
	return &HTTPClassifier{
		baseURL: strings.TrimRight(baseURL, "/"),
		client:  &http.Client{Timeout: classifierAttemptTimeout},
	}
}

// Classify posts the message to /v1/classify. Any transport error, non-200
// status, or undecodable body is reported as ErrClassifierUnavailable so a pool
// can retry it and the handler can return a clean 503. The message text is sent
// in the request body and never logged.
func (c *HTTPClassifier) Classify(ctx context.Context, text, locale string) (Assessment, error) {
	payload, err := json.Marshal(classifyRequest{Text: text, Locale: locale})
	if err != nil {
		return Assessment{}, fmt.Errorf("%w: encode request: %v", ErrClassifierUnavailable, err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/v1/classify", bytes.NewReader(payload))
	if err != nil {
		return Assessment{}, fmt.Errorf("%w: %v", ErrClassifierUnavailable, err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return Assessment{}, fmt.Errorf("%w: %v", ErrClassifierUnavailable, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		// Drain a bounded amount so the connection can be reused; the body is
		// discarded, never logged.
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
		return Assessment{}, fmt.Errorf("%w: status %d", ErrClassifierUnavailable, resp.StatusCode)
	}

	var a Assessment
	if err := json.NewDecoder(resp.Body).Decode(&a); err != nil {
		return Assessment{}, fmt.Errorf("%w: decode response: %v", ErrClassifierUnavailable, err)
	}
	if strings.TrimSpace(a.Verdict) == "" {
		return Assessment{}, fmt.Errorf("%w: response missing verdict", ErrClassifierUnavailable)
	}
	return a, nil
}

// classifyJob is one queued classification. Retries happen inside the worker;
// the result channel is buffered so a worker never blocks even if the
// submitting caller has already given up.
type classifyJob struct {
	ctx    context.Context
	text   string
	locale string
	result chan classifyResult
}

type classifyResult struct {
	assessment Assessment
	err        error
}

// ClassifierPool is a bounded work queue in front of a Classifier: a fixed set
// of worker goroutines pulls jobs from a FIFO channel, so no more than `workers`
// classification requests are ever in flight to the AI service at once. A failed
// call is retried up to `retries` times before the error is returned. Callers
// block until their result is ready or their context is cancelled.
//
// Workers run for the lifetime of the process; the pool is not closed.
type ClassifierPool struct {
	inner   Classifier
	retries int
	jobs    chan classifyJob
}

// NewClassifierPool starts a pool of `workers` workers over `inner`, retrying a
// failed classification up to `retries` times. A non-positive worker count falls
// back to DefaultClassifierWorkers; a negative retry count falls back to 0.
func NewClassifierPool(inner Classifier, workers, retries int) *ClassifierPool {
	if workers < 1 {
		workers = DefaultClassifierWorkers
	}
	if retries < 0 {
		retries = 0
	}
	p := &ClassifierPool{
		inner:   inner,
		retries: retries,
		jobs:    make(chan classifyJob, defaultClassifierQueueSize),
	}
	for i := 0; i < workers; i++ {
		go p.worker()
	}
	return p
}

func (p *ClassifierPool) worker() {
	for job := range p.jobs {
		a, err := p.classifyWithRetries(job.ctx, job.text, job.locale)
		// Buffered result channel: never blocks, even if the caller is gone.
		job.result <- classifyResult{assessment: a, err: err}
	}
}

func (p *ClassifierPool) classifyWithRetries(ctx context.Context, text, locale string) (Assessment, error) {
	var lastErr error
	for attempt := 0; attempt <= p.retries; attempt++ {
		if ctx.Err() != nil {
			if lastErr != nil {
				return Assessment{}, lastErr
			}
			return Assessment{}, ctx.Err()
		}

		a, err := p.inner.Classify(ctx, text, locale)
		if err == nil {
			return a, nil
		}
		lastErr = err

		if attempt == p.retries {
			break
		}
		timer := time.NewTimer(time.Duration(attempt+1) * classifierRetryBackoff)
		select {
		case <-timer.C:
		case <-ctx.Done():
			timer.Stop()
			return Assessment{}, lastErr
		}
	}
	return Assessment{}, lastErr
}

// Classify enqueues a classification and waits for its result. It returns the
// caller's context error if the context is cancelled before a worker finishes.
func (p *ClassifierPool) Classify(ctx context.Context, text, locale string) (Assessment, error) {
	job := classifyJob{
		ctx:    ctx,
		text:   text,
		locale: locale,
		result: make(chan classifyResult, 1),
	}

	select {
	case p.jobs <- job:
	case <-ctx.Done():
		return Assessment{}, ctx.Err()
	}

	select {
	case r := <-job.result:
		return r.assessment, r.err
	case <-ctx.Done():
		// The worker still owns the job; it observes the cancelled context and
		// discards the result into the buffered channel. We do not wait for it.
		return Assessment{}, ctx.Err()
	}
}
