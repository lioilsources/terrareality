package ai

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
)

// gateway answers chat completions with a fixed JSON summary and records the
// model it was asked for.
func gateway(t *testing.T, calls *atomic.Int32, model *atomic.Value) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls.Add(1)
		var req struct {
			Model string `json:"model"`
		}
		_ = json.NewDecoder(r.Body).Decode(&req)
		model.Store(req.Model)
		content := `{"summary":"ok","strengths":[],"gaps":[]}`
		_ = json.NewEncoder(w).Encode(map[string]any{"choices": []map[string]any{{"message": map[string]any{"content": content}}}})
	}))
	t.Cleanup(srv.Close)
	return srv
}

func down(t *testing.T, status int) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(status)
	}))
	t.Cleanup(srv.Close)
	return srv
}

func TestCloudFallback(t *testing.T) {
	// A closed server gives "connection refused".
	closed := httptest.NewServer(http.NotFoundHandler())
	closedURL := closed.URL
	closed.Close()

	cases := []struct {
		name      string
		primary   string
		flag      bool
		wantErr   bool
		wantCloud int32
	}{
		{"connection refused, flag on", closedURL, true, false, 1},
		{"connection refused, flag off", closedURL, false, true, 0},
		{"5xx, flag on", down(t, http.StatusBadGateway).URL, true, false, 1},
		{"4xx is not retried", down(t, http.StatusBadRequest).URL, true, true, 0},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var calls atomic.Int32
			var model atomic.Value
			cloud := gateway(t, &calls, &model)
			c := NewClient(tc.primary, "x", "openclaw-default")
			c.Fallback = NewEndpoint(cloud.URL, "cloud-key", "")
			flag := tc.flag
			c.FallbackOn = func(context.Context) bool { return flag }
			out, err := c.SummarizeApplication(context.Background(), ApplicationFacts{})
			if (err != nil) != tc.wantErr {
				t.Fatalf("err = %v, wantErr %v", err, tc.wantErr)
			}
			if calls.Load() != tc.wantCloud {
				t.Fatalf("cloud calls = %d, want %d", calls.Load(), tc.wantCloud)
			}
			if tc.wantCloud > 0 {
				if model.Load() != DefaultCloudModel || out.Model != DefaultCloudModel {
					t.Fatalf("cloud model %v, recorded %q", model.Load(), out.Model)
				}
			}
		})
	}
}

func TestPrimaryServesWithoutFallback(t *testing.T) {
	var pc, cc atomic.Int32
	var pm, cm atomic.Value
	primary, cloud := gateway(t, &pc, &pm), gateway(t, &cc, &cm)
	c := NewClient(primary.URL, "x", "openclaw-default")
	c.Fallback = NewEndpoint(cloud.URL, "k", "claude-haiku-5-5")
	c.FallbackOn = func(context.Context) bool { return true }
	out, err := c.SummarizeApplication(context.Background(), ApplicationFacts{})
	if err != nil || out.Model != "openclaw-default" || pc.Load() != 1 || cc.Load() != 0 {
		t.Fatalf("out %+v err %v primary %d cloud %d", out, err, pc.Load(), cc.Load())
	}
}

func TestNoFallbackWithoutEndpoint(t *testing.T) {
	c := NewClient(down(t, http.StatusServiceUnavailable).URL, "x", "m")
	c.FallbackOn = func(context.Context) bool { return true }
	if _, err := c.SummarizeApplication(context.Background(), ApplicationFacts{}); err == nil {
		t.Fatal("want error without a fallback endpoint")
	}
	if NewEndpoint("", "k", "m") != nil {
		t.Fatal("empty base URL must disable the fallback")
	}
}
