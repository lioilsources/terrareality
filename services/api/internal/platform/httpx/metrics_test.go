package httpx

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
)

func TestMetricsLabelsRoutePattern(t *testing.T) {
	reg := prometheus.NewRegistry()
	r := chi.NewRouter()
	r.Get("/v1/listings/{id}", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusNoContent) })
	r.Get("/v1/search", func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte("ok")) })
	r.Get("/boom", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusServiceUnavailable) })
	r.Get("/bad", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusBadRequest) })
	h := Metrics(reg)(r)

	for _, path := range []string{"/v1/listings/a", "/v1/listings/b", "/v1/search", "/boom", "/bad", "/nope/1", "/nope/2"} {
		h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, path, nil))
	}

	want := `
# HELP terra_http_requests_total HTTP requests by route pattern and status class.
# TYPE terra_http_requests_total counter
terra_http_requests_total{method="GET",route="/bad",status="4xx"} 1
terra_http_requests_total{method="GET",route="/boom",status="5xx"} 1
terra_http_requests_total{method="GET",route="/v1/listings/{id}",status="2xx"} 2
terra_http_requests_total{method="GET",route="/v1/search",status="2xx"} 1
terra_http_requests_total{method="GET",route="unmatched",status="4xx"} 2
`
	if err := testutil.GatherAndCompare(reg, strings.NewReader(want), "terra_http_requests_total"); err != nil {
		t.Fatal(err)
	}
	if n := testutil.CollectAndCount(reg, "terra_http_request_duration_seconds"); n != 5 {
		t.Fatalf("histogram series = %d, want 5", n)
	}
}

func TestMetricsNilRegistryIsPassThrough(t *testing.T) {
	called := false
	next := http.HandlerFunc(func(http.ResponseWriter, *http.Request) { called = true })
	Metrics(nil)(next).ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/", nil))
	if !called {
		t.Fatal("next handler not called")
	}
}

func TestStatusClass(t *testing.T) {
	for code, want := range map[int]string{0: "2xx", 200: "2xx", 204: "2xx", 301: "3xx", 404: "4xx", 429: "4xx", 500: "5xx", 503: "5xx", 42: "other"} {
		if got := StatusClass(code); got != want {
			t.Errorf("StatusClass(%d) = %q, want %q", code, got, want)
		}
	}
}
