package httpx

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestTrustedProxies(t *testing.T) {
	trusted, err := ParsePrefixes([]string{"10.0.0.0/8", "127.0.0.1"})
	if err != nil {
		t.Fatal(err)
	}
	var got string
	h := TrustedProxies(trusted)(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		got = ClientIP(r.Context())
	}))
	cases := []struct {
		name, remote, xff, want string
	}{
		{"direct client ignores header", "203.0.113.9:5000", "1.2.3.4", "203.0.113.9"},
		{"via trusted proxy", "10.0.0.2:5000", "198.51.100.7", "198.51.100.7"},
		{"spoofed leftmost is ignored", "10.0.0.2:5000", "6.6.6.6, 198.51.100.7", "198.51.100.7"},
		{"chain of trusted proxies", "127.0.0.1:1", "198.51.100.7, 10.1.1.1", "198.51.100.7"},
		{"garbage header stops", "10.0.0.2:5000", "nonsense", "10.0.0.2"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			r := httptest.NewRequest(http.MethodGet, "/", nil)
			r.RemoteAddr = c.remote
			if c.xff != "" {
				r.Header.Set("X-Forwarded-For", c.xff)
			}
			h.ServeHTTP(httptest.NewRecorder(), r)
			if got != c.want {
				t.Fatalf("got %q want %q", got, c.want)
			}
		})
	}
}
