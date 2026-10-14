// Package vision is the client of services/vision (Python), which tags
// photos and blurs privacy regions. In mock mode it answers deterministically.
package vision

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// Region is a normalized bounding box (0..1) of a face or licence plate.
type Region struct {
	Label string     `json:"label"`
	Box   [4]float64 `json:"box"` // x0, y0, x1, y1
}

// Analysis is the vision result for one photo.
type Analysis struct {
	RoomType           string   `json:"room_type"`
	Tags               []string `json:"tags"`
	Caption            string   `json:"caption"`
	NeedsPrivacyReview bool     `json:"needs_privacy_review"`
	Regions            []Region `json:"regions"`
	Model              string   `json:"model"`
	Mock               bool     `json:"mock"`
}

// Client calls the vision service.
type Client struct {
	BaseURL string
	HTTP    *http.Client
}

// New creates a client; baseURL empty disables vision.
func New(baseURL string) *Client {
	return &Client{BaseURL: strings.TrimRight(baseURL, "/"), HTTP: &http.Client{Timeout: 180 * time.Second}}
}

// Enabled reports whether a vision service is configured.
func (c *Client) Enabled() bool { return c != nil && c.BaseURL != "" }

// Analyze tags the image at imageURL (a short-lived presigned URL).
func (c *Client) Analyze(ctx context.Context, imageURL, locale string) (Analysis, error) {
	var a Analysis
	body, _ := json.Marshal(map[string]string{"image_url": imageURL, "locale": locale})
	res, err := c.post(ctx, "/v1/photos/analyze", body)
	if err != nil {
		return a, err
	}
	defer res.Body.Close()
	return a, json.NewDecoder(res.Body).Decode(&a)
}

// Redact returns the image with the regions blurred (JPEG).
func (c *Client) Redact(ctx context.Context, imageURL string, regions []Region) ([]byte, error) {
	body, _ := json.Marshal(map[string]any{"image_url": imageURL, "regions": regions})
	res, err := c.post(ctx, "/v1/photos/redact", body)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	return io.ReadAll(io.LimitReader(res.Body, 64<<20))
}

func (c *Client) post(ctx context.Context, path string, body []byte) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.BaseURL+path, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	res, err := c.HTTP.Do(req)
	if err != nil {
		return nil, fmt.Errorf("vision: %w", err)
	}
	if res.StatusCode != http.StatusOK {
		msg, _ := io.ReadAll(io.LimitReader(res.Body, 2000))
		res.Body.Close()
		return nil, fmt.Errorf("vision %s: status %d: %s", path, res.StatusCode, msg)
	}
	return res, nil
}
