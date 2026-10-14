package notify

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

// Push is a notification for one device.
type Push struct {
	Platform string            `json:"platform"` // fcm | apns | webpush
	Token    string            `json:"token"`
	Keys     json.RawMessage   `json:"keys,omitempty"`
	UserID   string            `json:"user_id"`
	Title    string            `json:"title"`
	Body     string            `json:"body"`
	Link     string            `json:"link"`
	Data     map[string]string `json:"data,omitempty"`
}

// ErrDeviceGone means the token is no longer valid; the caller removes it.
var ErrDeviceGone = errors.New("push device gone")

// Pusher delivers push notifications.
type Pusher interface {
	Push(ctx context.Context, p Push) error
}

// PushViaEmail is the mock push provider: each push becomes an e-mail to
// push+<user id>@push.terra.local so it shows up in Mailpit (like mock SMS).
type PushViaEmail struct{ Email Sender }

// Push implements Pusher.
func (m PushViaEmail) Push(ctx context.Context, p Push) error {
	return m.Email.Send(ctx, Message{Channel: Email, To: "push+" + p.UserID + "@push.terra.local", Template: "push",
		Subject: "Push " + p.Platform + ": " + p.Title, Text: p.Body + "\n\n" + p.Link})
}

// PushLog writes pushes to the log.
type PushLog struct{ L *slog.Logger }

// Push implements Pusher.
func (l PushLog) Push(_ context.Context, p Push) error {
	l.L.Info("push (not delivered)", "platform", p.Platform, "user", p.UserID, "title", p.Title)
	return nil
}

// FCM sends through Firebase Cloud Messaging HTTP v1. Flutter registers FCM
// tokens on Android and iOS (APNs is reached through Firebase), so one
// provider covers both mobile platforms.
type FCM struct {
	Project  string
	HTTP     *http.Client // authorized with the service account
	Fallback Pusher       // platforms FCM does not handle (web push)
}

// NewFCM builds the sender from a service account JSON key.
func NewFCM(ctx context.Context, project string, credentialsJSON []byte, fallback Pusher) (*FCM, error) {
	creds, err := google.CredentialsFromJSONWithType(ctx, credentialsJSON, google.ServiceAccount, "https://www.googleapis.com/auth/firebase.messaging")
	if err != nil {
		return nil, fmt.Errorf("fcm credentials: %w", err)
	}
	if project == "" {
		project = creds.ProjectID
	}
	return &FCM{Project: project, HTTP: oauth2.NewClient(ctx, creds.TokenSource), Fallback: fallback}, nil
}

// Push implements Pusher.
func (f *FCM) Push(ctx context.Context, p Push) error {
	if p.Platform != "fcm" && p.Platform != "apns" {
		return f.Fallback.Push(ctx, p)
	}
	data := map[string]string{"link": p.Link}
	for k, v := range p.Data {
		data[k] = v
	}
	body, _ := json.Marshal(map[string]any{"message": map[string]any{
		"token":        p.Token,
		"notification": map[string]string{"title": p.Title, "body": p.Body},
		"data":         data,
	}})
	url := "https://fcm.googleapis.com/v1/projects/" + f.Project + "/messages:send"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	res, err := f.HTTP.Do(req)
	if err != nil {
		return fmt.Errorf("fcm: %w", err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 64<<10))
	switch {
	case res.StatusCode == http.StatusOK:
		return nil
	case res.StatusCode == http.StatusNotFound || strings.Contains(string(raw), "UNREGISTERED"):
		return ErrDeviceGone
	}
	return fmt.Errorf("fcm: status %d: %.200s", res.StatusCode, raw)
}
