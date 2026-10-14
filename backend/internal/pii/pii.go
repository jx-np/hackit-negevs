// Package pii provides a transport-agnostic port for the screenshot PII
// removal step, together with a no-op stub and an HTTP client that talks to a
// locally-running Python redaction service.
//
// The Go backend never performs OCR or image censoring itself. Instead it
// hands an uploaded screenshot to a redactor, which returns the cleaned
// (PII-stripped) extracted text plus a redacted copy of the image with
// sensitive regions censored. The two concerns described in AGENTS.md
// (PaddleOCR extraction, a decision model marking sensitive regions, and
// Pillow censoring the boxes) live entirely behind this port.
//
// Keeping the boundary as a plain HTTP API means the Go and Python services
// can be restarted, scaled, or swapped independently even when co-located on
// one host. The Go side depends only on the small Redactor interface.
//
// PRIVACY: inputs are raw, un-redacted screenshot bytes and outputs may still
// transit extracted text. Implementations MUST NOT log image bytes, OCR text,
// or any raw message content. Only non-content metadata (region counts,
// durations, media types) may be logged.
package pii

import (
	"context"
	"errors"
)

// ErrUnavailable indicates the redaction backend could not be reached or
// failed to produce a result. Callers treat this as a soft failure: the check
// is marked failed, never completed with un-redacted content.
var ErrUnavailable = errors.New("pii: redactor unavailable")

// Input carries a single screenshot to redact.
type Input struct {
	// Image is the raw upload bytes. Never log these.
	Image []byte
	// MediaType is the image content type, e.g. "image/png".
	MediaType string
	// Locale hints OCR/language handling, e.g. "en-SG".
	Locale string
}

// Result is the outcome of a redaction pass.
type Result struct {
	// RedactedText is the extracted text with PII removed. Treat as sensitive
	// (length-bounded, host-only URLs are the caller's responsibility) and
	// never log it.
	RedactedText string
	// RedactedImage is the censored image bytes. Safe to persist and, once the
	// owner publishes, to serve.
	RedactedImage []byte
	// RedactedImageMediaType is the content type of RedactedImage.
	RedactedImageMediaType string
	// RegionsRedacted counts censored regions. Non-content metadata, safe to
	// log for observability.
	RegionsRedacted int
}

// Redactor extracts text from a screenshot and censors sensitive regions.
//
// Implementations must be safe for concurrent use, must not retain the input
// after returning, and must never log raw content. Returning an error (wrap
// ErrUnavailable for backend outages) must leave the caller free to fail the
// check rather than persist un-redacted data.
type Redactor interface {
	Redact(ctx context.Context, in Input) (Result, error)
}
