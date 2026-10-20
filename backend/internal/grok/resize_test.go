package grok

import (
	"bytes"
	"context"
	"encoding/binary"
	"hash/crc32"
	"image"
	"image/png"
	"testing"
)

// encodePNG encodes img as PNG, failing the test on error.
func encodePNG(t *testing.T, img image.Image) []byte {
	t.Helper()
	var buf bytes.Buffer
	if err := png.Encode(&buf, img); err != nil {
		t.Fatalf("encode png: %v", err)
	}
	return buf.Bytes()
}

// tinyPNG returns a small, valid PNG that is already within maxImageDimension,
// so the loader must pass its bytes through unchanged.
func tinyPNG(t *testing.T) []byte {
	t.Helper()
	return encodePNG(t, image.NewNRGBA(image.Rect(0, 0, 16, 16)))
}

// pngChunk builds one PNG chunk (length, type, data, CRC).
func pngChunk(typ string, data []byte) []byte {
	var buf bytes.Buffer
	_ = binary.Write(&buf, binary.BigEndian, uint32(len(data)))
	buf.WriteString(typ)
	buf.Write(data)
	crc := crc32.NewIEEE()
	_, _ = crc.Write([]byte(typ))
	_, _ = crc.Write(data)
	_ = binary.Write(&buf, binary.BigEndian, crc.Sum32())
	return buf.Bytes()
}

// insertPNGChunk inserts an ancillary chunk after IHDR. The result is still a
// valid PNG; the chunk only changes the on-disk size. It lets tests exercise the
// total-size cap without making images expensive to decode.
func insertPNGChunk(base []byte, typ string, data []byte) []byte {
	const ihdrEnd = 8 + 4 + 4 + 13 + 4 // signature + length + type + IHDR + CRC
	out := make([]byte, 0, len(base)+len(data)+12)
	out = append(out, base[:ihdrEnd]...)
	out = append(out, pngChunk(typ, data)...)
	out = append(out, base[ihdrEnd:]...)
	return out
}

// fakePNGHeader builds a PNG whose header declares the given dimensions but
// carries no pixel data. DecodeConfig reads only the header, so it is enough to
// exercise the decompression-bomb guard without allocating a huge image.
func fakePNGHeader(t *testing.T, width, height uint32) []byte {
	t.Helper()
	data := make([]byte, 13)
	binary.BigEndian.PutUint32(data[0:4], width)
	binary.BigEndian.PutUint32(data[4:8], height)
	data[8] = 8  // bit depth
	data[9] = 6  // color type: RGBA
	data[10] = 0 // compression
	data[11] = 0 // filter
	data[12] = 0 // interlace

	var buf bytes.Buffer
	buf.Write([]byte{0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n'})
	buf.Write(pngChunk("IHDR", data))
	return buf.Bytes()
}

func TestDownscaleImage(t *testing.T) {
	small := encodePNG(t, image.NewNRGBA(image.Rect(0, 0, 100, 50)))
	landscape := encodePNG(t, image.NewRGBA(image.Rect(0, 0, 1600, 900)))
	portrait := encodePNG(t, image.NewRGBA(image.Rect(0, 0, 600, 1200)))
	// Zero-valued NRGBA pixels are fully transparent. Re-encoding as JPEG must
	// flatten them onto white, not black.
	transparent := encodePNG(t, image.NewNRGBA(image.Rect(0, 0, 1200, 1200)))

	tests := []struct {
		name          string
		data          []byte
		mediaType     string
		wantErr       bool
		wantSame      bool
		wantMediaType string
		wantFormat    string
		wantW, wantH  int
		wantWhite     bool
	}{
		{
			name:          "small image unchanged",
			data:          small,
			mediaType:     "image/png",
			wantSame:      true,
			wantMediaType: "image/png",
			wantFormat:    "png",
			wantW:         100,
			wantH:         50,
		},
		{
			name:          "large landscape scaled",
			data:          landscape,
			mediaType:     "image/png",
			wantMediaType: "image/jpeg",
			wantFormat:    "jpeg",
			wantW:         768,
			wantH:         432,
		},
		{
			name:          "large portrait scaled",
			data:          portrait,
			mediaType:     "image/png",
			wantMediaType: "image/jpeg",
			wantFormat:    "jpeg",
			wantW:         384,
			wantH:         768,
		},
		{
			name:          "transparent png flattened onto white",
			data:          transparent,
			mediaType:     "image/png",
			wantMediaType: "image/jpeg",
			wantFormat:    "jpeg",
			wantW:         768,
			wantH:         768,
			wantWhite:     true,
		},
		{
			name:      "corrupt data rejected",
			data:      []byte("not an image"),
			mediaType: "image/png",
			wantErr:   true,
		},
		{
			name:      "over-megapixel header rejected",
			data:      fakePNGHeader(t, 8000, 6000), // 48 MP
			mediaType: "image/png",
			wantErr:   true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			out, mediaType, err := downscaleImage(tt.data, tt.mediaType)
			if tt.wantErr {
				if err == nil {
					t.Fatal("expected an error")
				}
				if out != nil || mediaType != "" {
					t.Errorf("error result = (%d bytes, %q), want (nil, \"\")", len(out), mediaType)
				}
				return
			}
			if err != nil {
				t.Fatalf("downscaleImage() error = %v", err)
			}
			if tt.wantSame && !bytes.Equal(out, tt.data) {
				t.Error("small image bytes changed, want original bytes untouched")
			}
			if mediaType != tt.wantMediaType {
				t.Errorf("media type = %q, want %q", mediaType, tt.wantMediaType)
			}

			cfg, format, err := image.DecodeConfig(bytes.NewReader(out))
			if err != nil {
				t.Fatalf("output does not decode: %v", err)
			}
			if format != tt.wantFormat {
				t.Errorf("output format = %q, want %q", format, tt.wantFormat)
			}
			if cfg.Width != tt.wantW || cfg.Height != tt.wantH {
				t.Errorf("output dimensions = %dx%d, want %dx%d", cfg.Width, cfg.Height, tt.wantW, tt.wantH)
			}

			if tt.wantWhite {
				img, _, err := image.Decode(bytes.NewReader(out))
				if err != nil {
					t.Fatalf("decode output: %v", err)
				}
				r, g, b, _ := img.At(0, 0).RGBA()
				if r < 0xF000 || g < 0xF000 || b < 0xF000 {
					t.Errorf("transparent pixel = (%d, %d, %d), want white", r, g, b)
				}
			}
		})
	}
}

func TestLoadImagesDownscalesLargeImages(t *testing.T) {
	small := tinyPNG(t)
	large := encodePNG(t, image.NewRGBA(image.Rect(0, 0, 1600, 1000)))

	store := newFakeStore()
	store.objects["small"] = small
	store.objects["large"] = large
	refs := []ImageRef{
		{StorageKey: "small", MediaType: "image/png", Position: 0},
		{StorageKey: "large", MediaType: "image/png", Position: 1},
	}

	got := loadImages(context.Background(), store, 7, refs, discardLogger())
	if len(got) != 2 {
		t.Fatalf("images = %d, want 2", len(got))
	}
	if !bytes.Equal(got[0].Data, small) || got[0].MediaType != "image/png" {
		t.Error("small image should be passed through unchanged")
	}
	if got[1].MediaType != "image/jpeg" {
		t.Errorf("large image media type = %q, want image/jpeg", got[1].MediaType)
	}
	cfg, format, err := image.DecodeConfig(bytes.NewReader(got[1].Data))
	if err != nil {
		t.Fatalf("downscaled image does not decode: %v", err)
	}
	if format != "jpeg" || cfg.Width != 768 || cfg.Height != 480 {
		t.Errorf("downscaled image = %s %dx%d, want jpeg 768x480", format, cfg.Width, cfg.Height)
	}
}

func TestLoadImagesSkipsUndecodableImage(t *testing.T) {
	small := tinyPNG(t)
	store := newFakeStore()
	store.objects["bad"] = []byte("not an image")
	store.objects["ok"] = small
	refs := []ImageRef{
		{StorageKey: "bad", MediaType: "image/png", Position: 0},
		{StorageKey: "ok", MediaType: "image/png", Position: 1},
	}

	got := loadImages(context.Background(), store, 7, refs, discardLogger())
	if len(got) != 1 {
		t.Fatalf("images = %d, want 1 (undecodable image skipped)", len(got))
	}
	if !bytes.Equal(got[0].Data, small) {
		t.Error("remaining image should be the valid one")
	}
}
