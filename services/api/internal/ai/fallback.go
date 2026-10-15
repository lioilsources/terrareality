package ai

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"
)

// DefaultCloudModel is the fallback model on the cloud gateway: Claude Sonnet
// 5.5 handles extraction (JSON) and chat-first search (tool calling).
const DefaultCloudModel = "claude-sonnet-5-5"

// FlagCloudFallback gates the cloud fallback (backoffice-editable, off by default).
const FlagCloudFallback = "ai.cloud_fallback"

// Endpoint is an OpenAI-compatible chat completions gateway.
type Endpoint struct {
	BaseURL string
	APIKey  string
	Model   string
	HTTP    *http.Client // nil = 60 s timeout
}

// NewEndpoint returns the cloud fallback endpoint, or nil when baseURL is empty.
func NewEndpoint(baseURL, apiKey, model string) *Endpoint {
	if baseURL == "" {
		return nil
	}
	if model == "" {
		model = DefaultCloudModel
	}
	return &Endpoint{BaseURL: strings.TrimRight(baseURL, "/"), APIKey: apiKey, Model: model,
		HTTP: &http.Client{Timeout: 60 * time.Second}}
}

// statusError is a non-200 answer of a gateway.
type statusError struct {
	Code int
	Body []byte
}

func (e *statusError) Error() string { return fmt.Sprintf("llm: status %d: %.300s", e.Code, e.Body) }

// send posts one chat completions body and returns the raw response.
func send(ctx context.Context, hc *http.Client, baseURL, apiKey string, body []byte) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, baseURL+"/chat/completions", bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+apiKey)
	res, err := hc.Do(req)
	if err != nil {
		return nil, fmt.Errorf("llm: %w", err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 4<<20))
	if res.StatusCode != http.StatusOK {
		return nil, &statusError{Code: res.StatusCode, Body: raw}
	}
	return raw, nil
}

// retryable reports whether a primary failure may go to the fallback: the
// gateway is unreachable, timed out or answered 5xx (the Spark is outside its
// LLM window or overloaded). Client errors (4xx) and a cancelled caller are not.
func retryable(ctx context.Context, err error) bool {
	if ctx.Err() != nil {
		return false
	}
	var se *statusError
	if errors.As(err, &se) {
		return se.Code >= 500
	}
	return true // transport error: connection refused, reset, DNS, client timeout
}

func (c *Client) logger() *slog.Logger {
	if c.Log != nil {
		return c.Log
	}
	return slog.Default()
}

// post sends a chat completions request built for a model to the Spark
// gateway. When that fails retryably, a fallback endpoint is configured and
// FallbackOn (flag ai.cloud_fallback) allows it, the same request goes to the
// cloud gateway with the cloud model. It returns the raw response and the
// model that answered, which callers record with the suggestion (ADR 0003:
// the output stays a suggestion whichever provider produced it).
func (c *Client) post(ctx context.Context, build func(model string) []byte) ([]byte, string, error) {
	start := time.Now()
	raw, err := send(ctx, c.HTTP, c.BaseURL, c.APIKey, build(c.Model))
	if err == nil {
		c.logger().DebugContext(ctx, "llm served", "provider", "spark", "model", c.Model,
			"dur_ms", time.Since(start).Milliseconds())
		return raw, c.Model, nil
	}
	fb := c.Fallback
	if fb == nil || c.FallbackOn == nil || !retryable(ctx, err) || !c.FallbackOn(ctx) {
		return nil, "", err
	}
	hc := fb.HTTP
	if hc == nil {
		hc = &http.Client{Timeout: 60 * time.Second}
	}
	start = time.Now()
	raw, ferr := send(ctx, hc, fb.BaseURL, fb.APIKey, build(fb.Model))
	if ferr != nil {
		c.logger().WarnContext(ctx, "llm cloud fallback failed", "primary_err", err.Error(), "err", ferr.Error())
		return nil, "", fmt.Errorf("%w (cloud fallback: %v)", err, ferr)
	}
	c.logger().InfoContext(ctx, "llm served", "provider", "cloud", "model", fb.Model,
		"primary_err", err.Error(), "dur_ms", time.Since(start).Milliseconds())
	return raw, fb.Model, nil
}
