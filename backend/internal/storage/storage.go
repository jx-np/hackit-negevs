// Package storage provides a small, transport-agnostic port for persisting
// binary blobs (currently user-uploaded images and their redacted
// derivatives) behind an interface, together with a local-filesystem
// implementation.
//
// The port intentionally hides where bytes actually live so the rest of the
// codebase depends only on opaque storage keys. A production deployment can
// swap the local implementation for an object-store client (S3, GCS, ...)
// without touching callers.
//
// PRIVACY: stored objects may contain raw, un-redacted screenshot bytes. Never
// log object contents, and never expose a raw upload key through any public
// surface. Only redacted derivatives are ever served publicly, and only after
// the owner explicitly publishes them.
package storage

import (
	"context"
	"errors"
	"io"
)

// ErrNotFound is returned when a key does not resolve to a stored object.
var ErrNotFound = errors.New("storage: object not found")

// Object is the result of reading a stored blob.
type Object struct {
	// Body streams the object's bytes. Callers must Close it.
	Body io.ReadCloser
	// MediaType is the stored content type (e.g. "image/png").
	MediaType string
	// Size is the object size in bytes.
	Size int64
}

// Store persists and retrieves opaque binary objects.
//
// Implementations must be safe for concurrent use. Keys are opaque strings
// chosen by the implementation; callers persist them (e.g. in
// private_uploads.storage_key) and pass them back to read or delete.
type Store interface {
	// Put stores body under a namespace prefix and returns the generated
	// opaque key. mediaType is persisted alongside the bytes. The provided
	// size is advisory; implementations should not trust it for enforcement.
	Put(ctx context.Context, prefix, mediaType string, body io.Reader) (key string, err error)

	// Get opens the object identified by key. The caller owns the returned
	// Body and must Close it. Returns ErrNotFound if the key is unknown.
	Get(ctx context.Context, key string) (Object, error)

	// Delete removes the object identified by key. Deleting a missing key is
	// not an error (idempotent).
	Delete(ctx context.Context, key string) error
}
