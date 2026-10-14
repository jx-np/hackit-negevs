package pii

import "context"

// Stub is a Redactor used when no Python redaction service is configured
// (local development, tests). It performs no OCR and no censoring: it reports
// the backend as unavailable so screenshot checks fail cleanly rather than
// completing with un-redacted content.
//
// This mirrors the privacy posture of the real client: when redaction cannot
// be guaranteed, the pipeline must not fabricate a "clean" result.
type Stub struct{}

// NewStub returns a Redactor that always reports the backend unavailable.
func NewStub() *Stub { return &Stub{} }

// Redact always returns ErrUnavailable without inspecting the image.
func (*Stub) Redact(context.Context, Input) (Result, error) {
	return Result{}, ErrUnavailable
}
