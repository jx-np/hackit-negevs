package grok

import (
	"bytes"
	"fmt"
	"image"
	"image/draw"
	"image/jpeg"
	"math"

	_ "image/png"

	xdraw "golang.org/x/image/draw"
	_ "golang.org/x/image/webp"
)

// maxImageDimension is the longest side, in pixels, of every image attached to
// a model request. Larger images are downscaled before they are sent: image
// tokens (and so cost and latency) grow with size, and screenshot text remains
// legible at this dimension.
const maxImageDimension = 768

// maxImagePixels bounds the decoded pixel count accepted by downscaleImage. A
// small, highly compressed file can otherwise describe enormous dimensions and
// exhaust memory when decoded; anything above this is skipped without decoding.
const maxImagePixels = 40_000_000 // 40 megapixels

// jpegQuality is the encoder quality for downscaled images. It keeps screenshot
// text crisp while shrinking the payload substantially.
const jpegQuality = 85

// downscaleImage prepares one image for a model request. When both sides are
// already within maxImageDimension the original bytes and media type are
// returned untouched (no re-encode). Otherwise the image is decoded, scaled
// with CatmullRom so its longest side is exactly maxImageDimension (aspect
// ratio preserved), flattened onto white to remove transparency, and re-encoded
// as JPEG.
//
// JPEG, PNG and WebP inputs are supported. Images whose declared dimensions
// exceed maxImagePixels are rejected. Returned errors never contain image
// bytes.
func downscaleImage(data []byte, mediaType string) ([]byte, string, error) {
	cfg, _, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil {
		return nil, "", fmt.Errorf("grok: decode image config: %w", err)
	}
	if cfg.Width <= 0 || cfg.Height <= 0 {
		return nil, "", fmt.Errorf("grok: invalid image dimensions %dx%d", cfg.Width, cfg.Height)
	}
	if int64(cfg.Width)*int64(cfg.Height) > maxImagePixels {
		return nil, "", fmt.Errorf("grok: image dimensions %dx%d exceed %d pixels",
			cfg.Width, cfg.Height, maxImagePixels)
	}
	if cfg.Width <= maxImageDimension && cfg.Height <= maxImageDimension {
		return data, mediaType, nil
	}

	src, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, "", fmt.Errorf("grok: decode image: %w", err)
	}

	bounds := src.Bounds()
	w, h := bounds.Dx(), bounds.Dy()
	if w <= 0 || h <= 0 {
		return nil, "", fmt.Errorf("grok: invalid decoded image dimensions %dx%d", w, h)
	}
	if w <= maxImageDimension && h <= maxImageDimension {
		// The header was pessimistic; the decoded image is small enough after
		// all, so keep its original bytes.
		return data, mediaType, nil
	}

	dstW, dstH := scaledDimensions(w, h)
	dst := image.NewRGBA(image.Rect(0, 0, dstW, dstH))
	// Paint white first so transparent source pixels flatten onto white rather
	// than black when the alpha channel is dropped by the JPEG encoder.
	draw.Draw(dst, dst.Bounds(), image.White, image.Point{}, draw.Src)
	xdraw.CatmullRom.Scale(dst, dst.Bounds(), src, bounds, draw.Over, nil)

	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, dst, &jpeg.Options{Quality: jpegQuality}); err != nil {
		return nil, "", fmt.Errorf("grok: encode image: %w", err)
	}
	return buf.Bytes(), "image/jpeg", nil
}

// scaledDimensions returns the target dimensions for a w×h image whose longest
// side is scaled to maxImageDimension. The shorter side is rounded and never
// drops below one pixel.
func scaledDimensions(w, h int) (int, int) {
	if w >= h {
		return maxImageDimension, max(1, int(math.Round(float64(h)*maxImageDimension/float64(w))))
	}
	return max(1, int(math.Round(float64(w)*maxImageDimension/float64(h)))), maxImageDimension
}
