// Package httpx contains shared, domain-agnostic HTTP building blocks:
// routing helpers, middleware, and JSON response/error helpers reused by all
// domains.
package httpx

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

// APIError is the stable error shape returned by the API.
//
//	{ "error": { "code": "...", "message": "...", "fields": {} }, "request_id": "..." }
type APIError struct {
	Error     APIErrorBody `json:"error"`
	RequestID string       `json:"request_id"`
}

// APIErrorBody is the inner body of an APIError.
type APIErrorBody struct {
	Code    string            `json:"code"`
	Message string            `json:"message"`
	Fields  map[string]string `json:"fields"`
}

// WriteJSON serializes v as JSON with the given status code.
func WriteJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if v == nil {
		return
	}
	if err := json.NewEncoder(w).Encode(v); err != nil {
		slog.Error("httpx: failed to encode JSON response", "error", err)
	}
}

// WriteError writes a stable error response without field details.
func WriteError(w http.ResponseWriter, r *http.Request, status int, code, message string) {
	WriteFieldError(w, r, status, code, message, nil)
}

// WriteFieldError writes a stable error response including per-field details.
func WriteFieldError(w http.ResponseWriter, r *http.Request, status int, code, message string, fields map[string]string) {
	if fields == nil {
		fields = map[string]string{}
	}
	WriteJSON(w, status, APIError{
		Error: APIErrorBody{
			Code:    code,
			Message: message,
			Fields:  fields,
		},
		RequestID: RequestIDFromContext(r.Context()),
	})
}

// Predefined error helpers for common statuses.

// BadRequest writes a 400 response.
func BadRequest(w http.ResponseWriter, r *http.Request, message string) {
	WriteError(w, r, http.StatusBadRequest, "bad_request", message)
}

// Unauthorized writes a 401 response.
func Unauthorized(w http.ResponseWriter, r *http.Request, message string) {
	WriteError(w, r, http.StatusUnauthorized, "unauthorized", message)
}

// Forbidden writes a 403 response.
func Forbidden(w http.ResponseWriter, r *http.Request, message string) {
	WriteError(w, r, http.StatusForbidden, "forbidden", message)
}

// NotFound writes a 404 response.
func NotFound(w http.ResponseWriter, r *http.Request, message string) {
	WriteError(w, r, http.StatusNotFound, "not_found", message)
}

// Conflict writes a 409 response.
func Conflict(w http.ResponseWriter, r *http.Request, message string) {
	WriteError(w, r, http.StatusConflict, "conflict", message)
}

// Unprocessable writes a 422 response, optionally including field details.
func Unprocessable(w http.ResponseWriter, r *http.Request, message string, fields map[string]string) {
	WriteFieldError(w, r, http.StatusUnprocessableEntity, "unprocessable_entity", message, fields)
}

// TooManyRequests writes a 429 response.
func TooManyRequests(w http.ResponseWriter, r *http.Request, message string) {
	WriteError(w, r, http.StatusTooManyRequests, "rate_limited", message)
}

// InternalError writes a 500 response with a stable shape.
func InternalError(w http.ResponseWriter, r *http.Request, message string) {
	if message == "" {
		message = "internal server error"
	}
	WriteError(w, r, http.StatusInternalServerError, "internal_error", message)
}
