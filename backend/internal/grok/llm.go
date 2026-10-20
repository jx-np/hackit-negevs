package grok

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
)

// chatCompletionsPath is appended to the configured BaseURL. It is the
// OpenAI-compatible chat completions endpoint exposed by the LiteLLM gateway.
const chatCompletionsPath = "/chat/completions"

// defaultMaxTokens is the completion budget. It is deliberately generous
// because reasoning tokens count toward it and a reasoning model can spend most
// of the budget before emitting any visible answer.
const defaultMaxTokens = 16384

// maxResponseBytes bounds how much of the upstream response body is read, so a
// misbehaving gateway cannot make the bot allocate without limit.
const maxResponseBytes = 4 << 20 // 4 MiB

// Image is one image attached to a user turn. MediaType is one of the
// OpenAI-compatible image media types; Data holds the raw bytes of an
// already-published, PII-redacted derivative. Both are never logged.
type Image struct {
	MediaType string
	Data      []byte
}

// Message is one turn in a chat completion request. Content carries the turn
// text; Images optionally attaches images to a user turn (system turns never
// carry images). Images is excluded from the default JSON shape and handled by
// MarshalJSON so a text-only turn serialises exactly as a plain string content,
// while a multimodal turn serialises to the OpenAI vision content-parts array.
type Message struct {
	Role    string  `json:"role"`
	Content string  `json:"content"`
	Images  []Image `json:"-"`
}

// contentPart is one entry of an OpenAI-compatible multimodal content array.
type contentPart struct {
	Type     string          `json:"type"`
	Text     string          `json:"text,omitempty"`
	ImageURL *imageURLObject `json:"image_url,omitempty"`
}

// imageURLObject is the image_url payload of a vision content part. The URL is
// a base64 data URI.
type imageURLObject struct {
	URL string `json:"url"`
}

// MarshalJSON emits the plain string content form when the turn has no images,
// and the vision content-parts array form when it does. Image bytes are only
// ever base64-encoded into the request body; they are never logged.
func (m Message) MarshalJSON() ([]byte, error) {
	if len(m.Images) == 0 {
		type plain struct {
			Role    string `json:"role"`
			Content string `json:"content"`
		}
		return json.Marshal(plain{Role: m.Role, Content: m.Content})
	}

	parts := make([]contentPart, 0, len(m.Images)+1)
	parts = append(parts, contentPart{Type: "text", Text: m.Content})
	for _, img := range m.Images {
		parts = append(parts, contentPart{
			Type: "image_url",
			ImageURL: &imageURLObject{
				URL: "data:" + img.MediaType + ";base64," + base64.StdEncoding.EncodeToString(img.Data),
			},
		})
	}

	type multimodal struct {
		Role    string        `json:"role"`
		Content []contentPart `json:"content"`
	}
	return json.Marshal(multimodal{Role: m.Role, Content: parts})
}

// Chat roles. Only system and user turns are ever sent.
const (
	RoleSystem = "system"
	RoleUser   = "user"
)

// LLM is the completion port the service depends on. Implementations must never
// log the messages they receive or the text they return.
type LLM interface {
	// Complete returns the assistant's reply text for messages. An empty reply
	// is reported as an error.
	Complete(ctx context.Context, messages []Message) (string, error)
}

// Errors surfaced by the HTTP client. They never carry prompt or response
// content.
var (
	// ErrLLMUnavailable reports a transport, encoding or response-decoding
	// failure.
	ErrLLMUnavailable = errors.New("grok: llm request failed")
	// ErrLLMStatus reports a non-2xx response; it contains only the status code.
	ErrLLMStatus = errors.New("grok: llm bad status")
	// ErrEmptyCompletion reports a 2xx response with no usable content, e.g. a
	// reasoning model that hit the token limit before answering.
	ErrEmptyCompletion = errors.New("grok: empty completion")
)

// StatusError is returned for a non-2xx response and carries only the HTTP
// status code. It unwraps to ErrLLMStatus so errors.Is(err, ErrLLMStatus) keeps
// working, while errors.As recovers the code for decisions such as retrying
// without images after a 4xx rejection.
type StatusError struct {
	Code int
}

// Error implements error. It never carries response content.
func (e *StatusError) Error() string {
	return fmt.Sprintf("grok: llm bad status: status %d", e.Code)
}

// Unwrap makes errors.Is(err, ErrLLMStatus) match a StatusError.
func (e *StatusError) Unwrap() error { return ErrLLMStatus }

// chatRequest is the OpenAI-compatible request envelope. max_tokens is always
// sent; stream is always false.
type chatRequest struct {
	Model     string    `json:"model"`
	Messages  []Message `json:"messages"`
	Stream    bool      `json:"stream"`
	MaxTokens int       `json:"max_tokens"`
}

// chatResponse decodes only the fields the bot uses. Reasoning fields are
// ignored entirely.
type chatResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
		FinishReason string `json:"finish_reason"`
	} `json:"choices"`
}

// HTTPLLM is an OpenAI-compatible chat-completions client. It is safe for
// concurrent use.
//
// It performs no retries: the LiteLLM gateway in front of the model already
// retries failed upstream requests.
type HTTPLLM struct {
	baseURL   string
	apiKey    string
	model     string
	maxTokens int
	client    *http.Client
}

// NewHTTPLLM builds a client for cfg. A non-positive timeout falls back to
// DefaultTimeout and a non-positive MaxConcurrent to DefaultMaxConcurrent; the
// latter sizes the connection pool so concurrent jobs are not throttled by
// idle-connection reuse.
func NewHTTPLLM(cfg Config) *HTTPLLM {
	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = DefaultTimeout
	}
	maxConcurrent := cfg.MaxConcurrent
	if maxConcurrent <= 0 {
		maxConcurrent = DefaultMaxConcurrent
	}

	transport := &http.Transport{}
	if base, ok := http.DefaultTransport.(*http.Transport); ok {
		transport = base.Clone()
	}
	transport.MaxIdleConnsPerHost = maxConcurrent

	return &HTTPLLM{
		baseURL:   strings.TrimRight(cfg.BaseURL, "/"),
		apiKey:    cfg.APIKey,
		model:     cfg.Model,
		maxTokens: defaultMaxTokens,
		client:    &http.Client{Timeout: timeout, Transport: transport},
	}
}

// Complete POSTs messages to {BaseURL}/chat/completions and returns the first
// choice's content. A leading reasoning block is stripped and empty content is
// an error. The request and response bodies are never logged.
func (c *HTTPLLM) Complete(ctx context.Context, messages []Message) (string, error) {
	payload, err := json.Marshal(chatRequest{
		Model:     c.model,
		Messages:  messages,
		Stream:    false,
		MaxTokens: c.maxTokens,
	})
	if err != nil {
		return "", fmt.Errorf("%w: encode request: %v", ErrLLMUnavailable, err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+chatCompletionsPath, bytes.NewReader(payload))
	if err != nil {
		return "", fmt.Errorf("%w: %v", ErrLLMUnavailable, err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("%w: %v", ErrLLMUnavailable, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		// Drain a bounded amount so the connection can be reused; the body is
		// discarded, never logged, and the error carries only the status code.
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
		return "", &StatusError{Code: resp.StatusCode}
	}

	var out chatResponse
	if err := json.NewDecoder(io.LimitReader(resp.Body, maxResponseBytes)).Decode(&out); err != nil {
		return "", fmt.Errorf("%w: decode response: %v", ErrLLMUnavailable, err)
	}
	if len(out.Choices) == 0 {
		return "", ErrEmptyCompletion
	}

	content := stripThinkBlocks(out.Choices[0].Message.Content)
	if content == "" {
		// Covers finish_reason "length" with no visible content: a reasoning
		// model exhausted the budget inside its reasoning block.
		return "", ErrEmptyCompletion
	}
	return content, nil
}

// Reasoning-block handling. Some reasoning models prepend a scratchpad block to
// their visible answer; only the answer should be posted.
var (
	// thinkBlockPattern matches a leading reasoning block, tolerating optional
	// attributes and both the "think" and "thinking" tag spellings.
	thinkBlockPattern = regexp.MustCompile(`(?is)^\s*<think(?:ing)?(?:\s[^>]*)?>.*?</think(?:ing)?\s*>`)

	// leadingCloseThinkPattern matches a stray closing reasoning tag left at the
	// start when the opening tag was absent.
	leadingCloseThinkPattern = regexp.MustCompile(`(?is)^\s*</think(?:ing)?\s*>`)
)

// stripThinkBlocks removes any leading reasoning block(s) from s and trims the
// result. Text after the block is preserved untouched.
func stripThinkBlocks(s string) string {
	t := s
	for {
		next := thinkBlockPattern.ReplaceAllString(t, "")
		next = leadingCloseThinkPattern.ReplaceAllString(next, "")
		if next == t {
			break
		}
		t = next
	}
	return strings.TrimSpace(t)
}
