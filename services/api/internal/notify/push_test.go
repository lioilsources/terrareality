package notify

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
)

type captureRT struct{ body []byte }

func (c *captureRT) RoundTrip(r *http.Request) (*http.Response, error) {
	c.body, _ = io.ReadAll(r.Body)
	return &http.Response{StatusCode: http.StatusOK, Body: io.NopCloser(strings.NewReader("{}")), Header: http.Header{}}, nil
}

func TestPushDataCarriesKindAndID(t *testing.T) {
	d := PushData(PushConversation, "c-1", map[string]string{"conversation_id": "c-1", "kind": "ignored"})
	if d["kind"] != "conversation" || d["id"] != "c-1" || d["conversation_id"] != "c-1" {
		t.Fatalf("data = %v", d)
	}
	for _, k := range []string{PushConversation, PushApplication, PushViewing, PushLease, PushObligation} {
		if got := PushData(k, "x", nil); got["kind"] != k || got["id"] != "x" {
			t.Fatalf("%s: %v", k, got)
		}
	}
}

func TestFCMPayloadHasKindIDAndLink(t *testing.T) {
	rt := &captureRT{}
	f := &FCM{Project: "p", HTTP: &http.Client{Transport: rt}}
	err := f.Push(context.Background(), Push{Platform: "fcm", Token: "tok", Title: "t", Body: "b",
		Link: "https://terra.local/zpravy/c-1", Data: PushData(PushConversation, "c-1", nil)})
	if err != nil {
		t.Fatal(err)
	}
	var req struct {
		Message struct {
			Data map[string]string `json:"data"`
		} `json:"message"`
	}
	if err := json.Unmarshal(rt.body, &req); err != nil {
		t.Fatal(err)
	}
	d := req.Message.Data
	if d["kind"] != "conversation" || d["id"] != "c-1" || d["link"] != "https://terra.local/zpravy/c-1" {
		t.Fatalf("fcm data = %v", d)
	}
}
