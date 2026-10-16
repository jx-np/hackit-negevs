package storage

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// mediaTypeExt maps supported media types to a file extension. Unknown types
// fall back to ".bin"; the extension is cosmetic since lookups go by key.
var mediaTypeExt = map[string]string{
	"image/jpeg": ".jpg",
	"image/png":  ".png",
	"image/webp": ".webp",
}

// legacyMediaSidecarSuffix is the suffix older builds used to persist the
// media type next to each object (e.g. "<key>.type"). It is kept only so
// Delete can clean up sidecars written before they were removed; the store
// neither writes nor reads it anymore.
const legacyMediaSidecarSuffix = ".type"

// LocalStore is a Store backed by a directory on the local filesystem.
//
// Layout: <root>/<prefix>/<random>.<ext> for the bytes. The extension is
// cosmetic (chosen from the media type at Put time); the content type is not
// stored here — the database is the source of truth. Keys are the path
// relative to root, using forward slashes, so they are portable across OSes.
type LocalStore struct {
	root string
}

// NewLocalStore creates a LocalStore rooted at dir, creating it if needed.
func NewLocalStore(dir string) (*LocalStore, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errors.New("storage: local root dir is required")
	}
	abs, err := filepath.Abs(dir)
	if err != nil {
		return nil, fmt.Errorf("storage: resolve root: %w", err)
	}
	if err := os.MkdirAll(abs, 0o750); err != nil {
		return nil, fmt.Errorf("storage: create root: %w", err)
	}
	return &LocalStore{root: abs}, nil
}

func (s *LocalStore) Put(ctx context.Context, prefix, mediaType string, body io.Reader) (string, error) {
	if err := ctx.Err(); err != nil {
		return "", err
	}
	prefix = sanitizePrefix(prefix)
	ext := mediaTypeExt[mediaType]
	if ext == "" {
		ext = ".bin"
	}
	name, err := randomName()
	if err != nil {
		return "", err
	}
	key := prefix + "/" + name + ext

	absPath, err := s.resolve(key)
	if err != nil {
		return "", err
	}
	if err := os.MkdirAll(filepath.Dir(absPath), 0o750); err != nil {
		return "", fmt.Errorf("storage: create prefix dir: %w", err)
	}

	f, err := os.OpenFile(absPath, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o640)
	if err != nil {
		return "", fmt.Errorf("storage: create object: %w", err)
	}
	if _, err := io.Copy(f, body); err != nil {
		f.Close()
		os.Remove(absPath)
		return "", fmt.Errorf("storage: write object: %w", err)
	}
	if err := f.Close(); err != nil {
		os.Remove(absPath)
		return "", fmt.Errorf("storage: close object: %w", err)
	}

	return key, nil
}

func (s *LocalStore) Get(ctx context.Context, key string) (Object, error) {
	if err := ctx.Err(); err != nil {
		return Object{}, err
	}
	absPath, err := s.resolve(key)
	if err != nil {
		return Object{}, err
	}
	info, err := os.Stat(absPath)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return Object{}, ErrNotFound
		}
		return Object{}, fmt.Errorf("storage: stat object: %w", err)
	}
	f, err := os.Open(absPath)
	if err != nil {
		return Object{}, fmt.Errorf("storage: open object: %w", err)
	}
	return Object{Body: f, Size: info.Size()}, nil
}

func (s *LocalStore) Delete(ctx context.Context, key string) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	absPath, err := s.resolve(key)
	if err != nil {
		return err
	}
	if err := os.Remove(absPath); err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("storage: delete object: %w", err)
	}
	// Legacy cleanup: older builds wrote a "<key>.type" media-type sidecar
	// next to each object. We no longer create or read it, but still remove
	// any that remain so deleting an object never leaves orphaned files.
	if err := os.Remove(absPath + legacyMediaSidecarSuffix); err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("storage: delete legacy media sidecar: %w", err)
	}
	return nil
}

// resolve converts an opaque key into an absolute path, guarding against path
// traversal so a crafted key can never escape the storage root.
func (s *LocalStore) resolve(key string) (string, error) {
	clean := filepath.Clean("/" + strings.ReplaceAll(key, "\\", "/"))
	abs := filepath.Join(s.root, filepath.FromSlash(clean))
	if abs != s.root && !strings.HasPrefix(abs, s.root+string(os.PathSeparator)) {
		return "", fmt.Errorf("storage: invalid key %q", key)
	}
	return abs, nil
}

func sanitizePrefix(prefix string) string {
	prefix = strings.Trim(strings.ReplaceAll(prefix, "\\", "/"), "/")
	parts := make([]string, 0, 4)
	for _, p := range strings.Split(prefix, "/") {
		if p == "" || p == "." || p == ".." {
			continue
		}
		parts = append(parts, p)
	}
	if len(parts) == 0 {
		return "misc"
	}
	return strings.Join(parts, "/")
}

func randomName() (string, error) {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("storage: random name: %w", err)
	}
	return hex.EncodeToString(buf), nil
}
