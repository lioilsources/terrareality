package httpx

import (
	"log/slog"
	"net/http"
	"runtime/debug"
	"slices"
	"strings"
	"time"

	"github.com/go-chi/chi/v5/middleware"
)

// Recover converts panics into a 500 problem response and logs the stack.
func Recover(log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if rec := recover(); rec != nil {
					if rec == http.ErrAbortHandler {
						panic(rec)
					}
					log.Error("panic", "err", rec, "path", LogPath(r.URL.Path),
						"request_id", middleware.GetReqID(r.Context()), "stack", string(debug.Stack()))
					WriteProblem(w, Problem{Status: http.StatusInternalServerError})
				}
			}()
			next.ServeHTTP(w, r)
		})
	}
}

// AccessLog logs one line per request. Paths carrying a secret are redacted
// (LogPath); query strings are never logged.
func AccessLog(log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)
			start := time.Now()
			next.ServeHTTP(ww, r)
			lvl := slog.LevelInfo
			if r.URL.Path == "/healthz" || r.URL.Path == "/v1/version" { // probes
				lvl = slog.LevelDebug
			}
			log.Log(r.Context(), lvl, "http",
				"method", r.Method, "path", LogPath(r.URL.Path), "status", ww.Status(),
				"bytes", ww.BytesWritten(), "dur_ms", time.Since(start).Milliseconds(),
				"request_id", middleware.GetReqID(r.Context()))
		})
	}
}

// secretPathPrefixes are routes whose next path segment may be a bearer
// secret. Invitation tokens now travel in POST bodies (/v1/invitations/lookup
// and /accept, review S-A2); a client still putting one in the path (the
// removed routes) is redacted all the same.
var secretPathPrefixes = []string{"/v1/invitations/"}

// publicSegments are known route segments after a secret prefix.
var publicSegments = map[string]bool{"lookup": true, "accept": true}

// LogPath returns path with secret segments replaced by "{redacted}", for
// logs and traces.
func LogPath(path string) string {
	for _, p := range secretPathPrefixes {
		rest, ok := strings.CutPrefix(path, p)
		if !ok || rest == "" || publicSegments[rest] {
			continue
		}
		_, tail, hasTail := strings.Cut(rest, "/")
		if hasTail {
			return p + "{redacted}/" + tail
		}
		return p + "{redacted}"
	}
	return path
}

// CORS allows the configured browser origins (web app, Astro site).
func CORS(origins []string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			if origin != "" && slices.Contains(origins, origin) {
				h := w.Header()
				h.Set("Access-Control-Allow-Origin", origin)
				h.Set("Access-Control-Allow-Credentials", "true")
				h.Set("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Request-Id")
				h.Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
				h.Add("Vary", "Origin")
			}
			if r.Method == http.MethodOptions && origin != "" {
				w.WriteHeader(http.StatusNoContent)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
