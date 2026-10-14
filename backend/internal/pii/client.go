package pii

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/textproto"
	"strings"
	"time"
)

// Client is a Redactor that calls a locally-running Python redaction service
// over plain HTTP. The Go and Python processes are expected to be co-located,
// but the HTTP boundary keeps them independently restartable and swappable.
//
// Wire protocol (POST <baseURL>/v1/redact):
//
//	Request:  multipart/form-data
//	  - field "locale"  (text): OCR/language hint, e.g. "en-SG"
//	  - field "image"   (file): raw screenshot bytes, Content-Type set
//	Response: 200 application/json
//	  {
//	    "redacted_text":  string,  // PII-stripped extracted text
//	    "image_base64":   string,  // base64 censored image
//	    "image_media_type": string,// e.g. "image/png"
//	    "regions_redacted": int     // non-content metadata
//	  }
//
// Any non-200 status, transport error, or malformed body is reported as a
// wrapped ErrUnavailable so the caller fails the check rather than persisting
// un-redacted content.
type Client struct {
	baseURL string
	http    *http.Client
}

// ClientOption configures a Client.
type ClientOption func(*Client)

// WithHTTPClient overrides the default HTTP client (e.g. for custom timeouts
// or transport in tests).
func WithHTTPClient(h *http.Client) ClientOption {
	return func(c *Client) {
		if h != nil {
			c.http = h
		}
	}
}

// NewClient builds a Client targeting baseURL (e.g. "http://127.0.0.1:8099").
// A sensible default timeout is applied; OCR can be slow, so it is generous.
func NewClient(baseURL string, opts ...ClientOption) *Client {
	c := &Client{
		baseURL: strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		http:    &http.Client{Timeout: 60 * time.Second},
	}
	for _, opt := range opts {
		opt(c)
	}
	return c
}

type redactResponse struct {
	RedactedText    string `json:"redacted_text"`
	ImageBase64     string `json:"image_base64"`
	ImageMediaType  string `json:"image_media_type"`
	RegionsRedacted int    `json:"regions_redacted"`
}

// Redact sends the screenshot to the Python service and returns the cleaned
// text and censored image. Never logs image bytes or extracted text.
func (c *Client) Redact(ctx context.Context, in Input) (Result, error) {
	if len(in.Image) == 0 {
		return Result{}, fmt.Errorf("%w: empty image", ErrUnavailable)
	}

	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	if err := mw.WriteField("locale", in.Locale); err != nil {
		return Result{}, fmt.Errorf("%w: write locale field: %v", ErrUnavailable, err)
	}
	part, err := mw.CreatePart(imagePartHeader(in.MediaType))
	if err != nil {
		return Result{}, fmt.Errorf("%w: create image part: %v", ErrUnavailable, err)
	}
	if _, err := part.Write(in.Image); err != nil {
		return Result{}, fmt.Errorf("%w: write image bytes: %v", ErrUnavailable, err)
	}
	if err := mw.Close(); err != nil {
		return Result{}, fmt.Errorf("%w: finalize multipart: %v", ErrUnavailable, err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/v1/redact", &body)
	if err != nil {
		return Result{}, fmt.Errorf("%w: build request: %v", ErrUnavailable, err)
	}
	req.Header.Set("Content-Type", mw.FormDataContentType())

	resp, err := c.http.Do(req)
	if err != nil {
		return Result{}, fmt.Errorf("%w: %v", ErrUnavailable, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		// Drain a bounded amount so the connection can be reused; do not log it.
		_, _ = io.CopyN(io.Discard, resp.Body, 4096)
		return Result{}, fmt.Errorf("%w: redactor returned status %d", ErrUnavailable, resp.StatusCode)
	}

	var decoded redactResponse
	if err := json.NewDecoder(io.LimitReader(resp.Body, 32<<20)).Decode(&decoded); err != nil {
		return Result{}, fmt.Errorf("%w: decode response: %v", ErrUnavailable, err)
	}

	img, err := base64.StdEncoding.DecodeString(decoded.ImageBase64)
	if err != nil {
		return Result{}, fmt.Errorf("%w: decode redacted image: %v", ErrUnavailable, err)
	}

	return Result{
		RedactedText:           decoded.RedactedText,
		RedactedImage:          img,
		RedactedImageMediaType: decoded.ImageMediaType,
		RegionsRedacted:        decoded.RegionsRedacted,
	}, nil
}

// imagePartHeader builds the MIME header for the image file part, carrying the
// upload's content type so the Python side can decode it correctly.
func imagePartHeader(mediaType string) textproto.MIMEHeader {
	if mediaType == "" {
		mediaType = "application/octet-stream"
	}
	ext := ".bin"
	switch mediaType {
	case "image/jpeg":
		ext = ".jpg"
	case "image/png":
		ext = ".png"
	case "image/webp":
		ext = ".webp"
	}
	h := make(textproto.MIMEHeader)
	h.Set("Content-Disposition", fmt.Sprintf(`form-data; name="image"; filename="upload%s"`, ext))
	h.Set("Content-Type", mediaType)
	return h
}
