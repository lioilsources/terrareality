// Package realtime publishes events to Centrifugo and issues the tokens
// clients use to connect. The API publishes after the database transaction
// commits; clients subscribe to one channel per conversation and to their
// own user channel (inbox, notifications, presence).
package realtime

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

// ConversationChannel is the channel of one conversation.
func ConversationChannel(id uuid.UUID) string { return "conv:" + id.String() }

// UserChannel is a user's personal channel. Clients join it through the
// connection token (server-side subscription), never by name.
func UserChannel(id uuid.UUID) string { return "user:" + id.String() }

// Publisher sends events and reports presence.
type Publisher interface {
	Publish(ctx context.Context, channel string, data any) error
	// Online reports whether anyone is subscribed to the channel.
	Online(ctx context.Context, channel string) (bool, error)
}

// Centrifugo talks to the Centrifugo server HTTP API.
type Centrifugo struct {
	URL  string // e.g. http://localhost:8000/api
	Key  string
	HTTP *http.Client
}

// NewCentrifugo creates the adapter.
func NewCentrifugo(url, key string) *Centrifugo {
	return &Centrifugo{URL: strings.TrimRight(url, "/"), Key: key, HTTP: &http.Client{Timeout: 3 * time.Second}}
}

func (c *Centrifugo) call(ctx context.Context, method string, in, out any) error {
	body, _ := json.Marshal(in)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.URL+"/"+method, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", c.Key)
	res, err := c.HTTP.Do(req)
	if err != nil {
		return fmt.Errorf("centrifugo %s: %w", method, err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("centrifugo %s: status %d: %.200s", method, res.StatusCode, raw)
	}
	var env struct {
		Error *struct {
			Code    int    `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
		Result json.RawMessage `json:"result"`
	}
	if err := json.Unmarshal(raw, &env); err != nil {
		return fmt.Errorf("centrifugo %s: %w", method, err)
	}
	if env.Error != nil {
		return fmt.Errorf("centrifugo %s: %d %s", method, env.Error.Code, env.Error.Message)
	}
	if out != nil && len(env.Result) > 0 {
		return json.Unmarshal(env.Result, out)
	}
	return nil
}

// Publish implements Publisher.
func (c *Centrifugo) Publish(ctx context.Context, channel string, data any) error {
	return c.call(ctx, "publish", map[string]any{"channel": channel, "data": data}, nil)
}

// Online implements Publisher.
func (c *Centrifugo) Online(ctx context.Context, channel string) (bool, error) {
	var out struct {
		NumClients int `json:"num_clients"`
	}
	if err := c.call(ctx, "presence_stats", map[string]any{"channel": channel}, &out); err != nil {
		return false, err
	}
	return out.NumClients > 0, nil
}

// Event is one published message (Memory keeps them for tests).
type Event struct {
	Channel string
	Data    any
}

// Memory is the offline publisher: it records events and lets tests mark
// channels as online.
type Memory struct {
	mu     sync.Mutex
	events []Event
	online map[string]bool
}

// Publish implements Publisher.
func (m *Memory) Publish(_ context.Context, channel string, data any) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.events = append(m.events, Event{channel, data})
	return nil
}

// Online implements Publisher.
func (m *Memory) Online(_ context.Context, channel string) (bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.online[channel], nil
}

// SetOnline marks a channel as having subscribers.
func (m *Memory) SetOnline(channel string, on bool) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.online == nil {
		m.online = map[string]bool{}
	}
	m.online[channel] = on
}

// Events returns the events published to a channel.
func (m *Memory) Events(channel string) []Event {
	m.mu.Lock()
	defer m.mu.Unlock()
	var out []Event
	for _, e := range m.events {
		if e.Channel == channel {
			out = append(out, e)
		}
	}
	return out
}

// Tokens signs Centrifugo connection and subscription tokens (HS256 JWT).
type Tokens struct {
	Secret []byte
	TTL    time.Duration
}

// Connect returns a connection token that also subscribes the client to its
// user channel on the server side.
func (t Tokens) Connect(userID uuid.UUID, now time.Time) (string, time.Time) {
	exp := now.Add(t.TTL)
	return t.sign(map[string]any{"sub": userID.String(), "exp": exp.Unix(), "iat": now.Unix(),
		"channels": []string{UserChannel(userID)}}), exp
}

// Subscribe returns a token for one channel.
func (t Tokens) Subscribe(userID uuid.UUID, channel string, now time.Time) (string, time.Time) {
	exp := now.Add(t.TTL)
	return t.sign(map[string]any{"sub": userID.String(), "channel": channel, "exp": exp.Unix(), "iat": now.Unix()}), exp
}

var b64 = base64.RawURLEncoding

func (t Tokens) sign(claims map[string]any) string {
	head := b64.EncodeToString([]byte(`{"alg":"HS256","typ":"JWT"}`))
	body, _ := json.Marshal(claims)
	msg := head + "." + b64.EncodeToString(body)
	mac := hmac.New(sha256.New, t.Secret)
	mac.Write([]byte(msg))
	return msg + "." + b64.EncodeToString(mac.Sum(nil))
}
