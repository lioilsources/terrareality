package storage

import (
	"context"
	"errors"
	"net/url"
	"strings"
	"testing"
	"time"
)

func TestMemoryGetLimited(t *testing.T) {
	m := NewMemory("http://blob.test")
	ctx := context.Background()
	_ = m.Put(ctx, "k", "image/jpeg", make([]byte, 100))
	if _, err := m.GetLimited(ctx, "k", 99); !errors.Is(err, ErrTooLarge) {
		t.Fatalf("over limit: %v", err)
	}
	if b, err := m.GetLimited(ctx, "k", 100); err != nil || len(b) != 100 {
		t.Fatalf("at limit: %d %v", len(b), err)
	}
	if _, err := m.GetLimited(ctx, "missing", 10); !errors.Is(err, ErrNotFound) {
		t.Fatalf("missing: %v", err)
	}
}

func TestAttachmentDisposition(t *testing.T) {
	d := AttachmentDisposition("výpis \"x\".pdf\r\n")
	if !strings.HasPrefix(d, "attachment; ") || strings.ContainsAny(d, "\r\n") || strings.Count(d, `"`) != 2 {
		t.Fatalf("disposition %q", d)
	}
	if !strings.Contains(d, "filename*=UTF-8''") {
		t.Fatalf("no RFC 5987 name: %q", d)
	}
	if AttachmentDisposition("") != `attachment; filename="download"; filename*=UTF-8''download` {
		t.Fatalf("empty name: %q", AttachmentDisposition(""))
	}
}

func TestPresignDownloadForcesSafeType(t *testing.T) {
	m := NewMemory("http://blob.test")
	for ct, want := range map[string]string{"text/html": "application/octet-stream", "image/jpeg": "image/jpeg",
		"": "application/octet-stream", "application/pdf": "application/pdf"} {
		u, err := m.PresignDownload(context.Background(), "k", "a.bin", ct, time.Minute)
		if err != nil {
			t.Fatal(err)
		}
		pu, _ := url.Parse(u)
		if got := pu.Query().Get("response-content-type"); got != want {
			t.Fatalf("%q: got %q", ct, got)
		}
		if !strings.HasPrefix(pu.Query().Get("response-content-disposition"), "attachment") {
			t.Fatalf("%q: not an attachment: %s", ct, u)
		}
	}
}
