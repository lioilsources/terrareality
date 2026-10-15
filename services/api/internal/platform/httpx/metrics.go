package httpx

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/prometheus/client_golang/prometheus"
)

// LatencyBuckets resolve the search SLO (p95 < 300 ms) precisely: dense around
// 100-500 ms, coarse beyond.
var LatencyBuckets = []float64{.005, .01, .025, .05, .1, .15, .2, .25, .3, .35, .4, .5, .75, 1, 2.5, 5, 10}

// UnmatchedRoute labels requests that no route matched (404/405), keeping the
// label set bounded no matter what paths scanners try.
const UnmatchedRoute = "unmatched"

// Metrics records RED metrics per chi route pattern (never the raw path):
// terra_http_requests_total{method,route,status}, terra_http_request_duration_seconds
// and terra_http_requests_in_flight. status is the class ("2xx".."5xx").
// A nil registry returns a pass-through middleware (metrics disabled).
//
// It must wrap the chi router from the outside: it seeds the chi route context
// so the matched pattern is readable after the router returns.
func Metrics(reg *prometheus.Registry) func(http.Handler) http.Handler {
	if reg == nil {
		return func(next http.Handler) http.Handler { return next }
	}
	requests := prometheus.NewCounterVec(prometheus.CounterOpts{
		Namespace: "terra", Name: "http_requests_total", Help: "HTTP requests by route pattern and status class.",
	}, []string{"method", "route", "status"})
	duration := prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Namespace: "terra", Name: "http_request_duration_seconds", Help: "HTTP request latency by route pattern.",
		Buckets: LatencyBuckets,
	}, []string{"method", "route", "status"})
	inFlight := prometheus.NewGauge(prometheus.GaugeOpts{
		Namespace: "terra", Name: "http_requests_in_flight", Help: "HTTP requests being served.",
	})
	reg.MustRegister(requests, duration, inFlight)

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			rctx := chi.RouteContext(r.Context())
			if rctx == nil {
				rctx = chi.NewRouteContext()
				r = r.WithContext(context.WithValue(r.Context(), chi.RouteCtxKey, rctx))
			}
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)
			inFlight.Inc()
			start := time.Now()
			defer func() {
				inFlight.Dec()
				labels := []string{r.Method, routeLabel(rctx), StatusClass(ww.Status())}
				requests.WithLabelValues(labels...).Inc()
				duration.WithLabelValues(labels...).Observe(time.Since(start).Seconds())
			}()
			next.ServeHTTP(ww, r)
		})
	}
}

func routeLabel(rctx *chi.Context) string {
	if p := rctx.RoutePattern(); p != "" && p != "/*" {
		return p
	}
	return UnmatchedRoute
}

// StatusClass maps 204 to "2xx"; a handler that never wrote counts as 200.
func StatusClass(code int) string {
	if code == 0 {
		code = http.StatusOK
	}
	if code < 100 || code > 599 {
		return "other"
	}
	return strconv.Itoa(code/100) + "xx"
}
