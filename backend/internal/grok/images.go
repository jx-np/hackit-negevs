package grok

import (
	"context"
	"errors"
	"io"
	"log/slog"

	"scamshield/internal/storage"
)

// Image attachment bounds. Images give the model visual context for the post,
// but they are best-effort: any problem reading one simply drops it and the
// reply proceeds text-only. The caps keep a post with many or huge images from
// inflating the prompt or the process's memory.
const (
	// maxImages is how many of a post's images (first by display position) are
	// attached to one request.
	maxImages = 4
	// maxImageBytes is the per-image read cap. An image larger than this is
	// skipped.
	maxImageBytes = 4 << 20 // 4 MiB
	// maxTotalImageBytes caps the combined size of attached images after any
	// downscaling.
	maxTotalImageBytes = 10 << 20 // 10 MiB
)

// supportedImageMediaTypes is the set the model accepts. The database already
// constrains report_images.media_type to this set; it is checked again here so
// a future schema change cannot feed the model an unexpected payload.
var supportedImageMediaTypes = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
	"image/webp": true,
}

// loadImages reads the first maxImages of refs (which are already in display
// order) into model-ready Image values. It is best-effort: unsupported media
// types, missing blobs, read errors, oversized images, undecodable images and
// total-size overruns all skip that image rather than failing. Images larger
// than maxImageDimension on their longest side are downscaled and re-encoded as
// JPEG before the total-size cap is applied. A nil store yields no images. Only
// ids, positions, media types, sizes and errors are ever logged; bytes, base64
// and storage keys are never logged.
func loadImages(ctx context.Context, store storage.Store, reportID int64, refs []ImageRef, logger *slog.Logger) []Image {
	if store == nil || len(refs) == 0 {
		return nil
	}
	if logger == nil {
		logger = slog.Default()
	}

	var (
		out   []Image
		total int64
	)
	for _, ref := range refs {
		if len(out) >= maxImages {
			break
		}
		if !supportedImageMediaTypes[ref.MediaType] {
			logger.Warn("grok: skipping post image with unsupported media type",
				"report_id", reportID, "position", ref.Position, "media_type", ref.MediaType)
			continue
		}

		data, err := readImage(ctx, store, ref)
		if err != nil {
			// A missing blob is expected once a post's image has been purged;
			// log it at Warn without exposing the key.
			logger.Warn("grok: skipping unreadable post image",
				"report_id", reportID, "position", ref.Position, "error", err)
			continue
		}
		if int64(len(data)) > maxImageBytes {
			logger.Warn("grok: skipping oversized post image",
				"report_id", reportID, "position", ref.Position, "size", len(data))
			continue
		}

		// Downscale before applying the total-size cap so the cap measures what
		// is actually sent. The per-image cap above still bounds the raw read.
		resized, mediaType, err := downscaleImage(data, ref.MediaType)
		if err != nil {
			logger.Warn("grok: skipping undecodable post image",
				"report_id", reportID, "position", ref.Position, "error", err)
			continue
		}
		if total+int64(len(resized)) > maxTotalImageBytes {
			logger.Warn("grok: skipping post image, total size cap reached",
				"report_id", reportID, "position", ref.Position, "size", len(resized))
			continue
		}

		out = append(out, Image{MediaType: mediaType, Data: resized})
		total += int64(len(resized))
	}
	return out
}

// readImage opens and reads one blob, bounded to maxImageBytes+1 bytes so an
// oversized object is detected without reading it all. The object body is always
// closed. The returned error never carries object bytes.
func readImage(ctx context.Context, store storage.Store, ref ImageRef) ([]byte, error) {
	obj, err := store.Get(ctx, ref.StorageKey)
	if err != nil {
		if errors.Is(err, storage.ErrNotFound) {
			return nil, storage.ErrNotFound
		}
		return nil, err
	}
	defer obj.Body.Close()

	data, err := io.ReadAll(io.LimitReader(obj.Body, maxImageBytes+1))
	if err != nil {
		return nil, err
	}
	return data, nil
}
