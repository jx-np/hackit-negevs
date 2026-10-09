package httpx

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
)

// DefaultMaxBodyBytes is the default request body size limit for JSON decoding.
const DefaultMaxBodyBytes int64 = 1 << 20 // 1 MiB

// DecodeJSON reads and decodes a JSON request body into dst. It enforces a
// maximum body size and rejects unknown fields. On failure it writes a 422
// response with field details and returns false.
func DecodeJSON(w http.ResponseWriter, r *http.Request, dst any) bool {
	return DecodeJSONLimit(w, r, dst, DefaultMaxBodyBytes)
}

// DecodeJSONLimit behaves like DecodeJSON with a caller-supplied size limit.
func DecodeJSONLimit(w http.ResponseWriter, r *http.Request, dst any, maxBytes int64) bool {
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes)

	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()

	if err := dec.Decode(dst); err != nil {
		writeDecodeError(w, r, err)
		return false
	}

	// Reject trailing data (multiple JSON values).
	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		Unprocessable(w, r, "request body must contain a single JSON object", nil)
		return false
	}

	return true
}

func writeDecodeError(w http.ResponseWriter, r *http.Request, err error) {
	var syntaxErr *json.SyntaxError
	var typeErr *json.UnmarshalTypeError
	var maxBytesErr *http.MaxBytesError

	switch {
	case errors.As(err, &syntaxErr):
		Unprocessable(w, r, "request body contains malformed JSON", nil)
	case errors.As(err, &typeErr):
		Unprocessable(w, r, "request body contains an invalid value", map[string]string{
			typeErr.Field: fmt.Sprintf("must be of type %s", typeErr.Type.String()),
		})
	case errors.As(err, &maxBytesErr):
		Unprocessable(w, r, "request body is too large", nil)
	case errors.Is(err, io.EOF):
		Unprocessable(w, r, "request body must not be empty", nil)
	case strings.HasPrefix(err.Error(), "json: unknown field "):
		field := strings.TrimPrefix(err.Error(), "json: unknown field ")
		field = strings.Trim(field, "\"")
		Unprocessable(w, r, "request body contains an unknown field", map[string]string{
			field: "unknown field",
		})
	default:
		Unprocessable(w, r, "request body could not be decoded", nil)
	}
}
