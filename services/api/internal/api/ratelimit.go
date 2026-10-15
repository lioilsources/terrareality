package api

import (
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/platform/httpx"
	"github.com/terrareality/terrareality/services/api/internal/platform/ratelimit"
)

// RateLimits are the per-route request limits (RATE_LIMIT_* in config). A
// zero Rule disables that limit. Credential endpoints keep their own
// handler-level limiters (AUTH_RATE_BURST, see auth_handlers.go).
type RateLimits struct {
	Search  ratelimit.Rule // GET /v1/search, per client IP
	Chat    ratelimit.Rule // POST /v1/search/chat (LLM), per user or IP
	Webhook ratelimit.Rule // POST /v1/webhooks/*, per client IP (generous: Stripe retries in bursts)
	Apply   ratelimit.Rule // POST /v1/applications, per user
	Message ratelimit.Rule // new conversations, messages, attachments, per user
	Report  ratelimit.Rule // listing and conversation reports (DSA notices), per user or IP
}

type limitedRoute struct {
	method  string
	pattern []string // path segments, "*" matches one segment
	lim     *ratelimit.Limiter
	name    string
}

func segments(p string) []string { return strings.Split(strings.Trim(p, "/"), "/") }

func (lr limitedRoute) matches(r *http.Request) bool {
	if r.Method != lr.method {
		return false
	}
	segs := segments(r.URL.Path)
	if len(segs) != len(lr.pattern) {
		return false
	}
	for i, s := range lr.pattern {
		if s != "*" && s != segs[i] {
			return false
		}
	}
	return true
}

// rateLimitRoutes maps the limits onto routes. Routes sharing a Rule share
// one limiter (messages to several threads count together).
func rateLimitRoutes(rl RateLimits) []limitedRoute {
	var out []limitedRoute
	add := func(rule ratelimit.Rule, name string, routes ...string) {
		lim := rule.Limiter()
		if lim == nil {
			return
		}
		for _, rt := range routes {
			method, path, _ := strings.Cut(rt, " ")
			out = append(out, limitedRoute{method: method, pattern: segments(path), lim: lim, name: name})
		}
	}
	add(rl.Search, "search", "GET /v1/search")
	add(rl.Chat, "chat", "POST /v1/search/chat")
	add(rl.Webhook, "webhook", "POST /v1/webhooks/*")
	add(rl.Apply, "apply", "POST /v1/applications")
	add(rl.Message, "message",
		"POST /v1/conversations",
		"POST /v1/conversations/*/messages",
		"POST /v1/conversations/*/attachments",
		"POST /v1/groups/*/messages")
	add(rl.Report, "report",
		"POST /v1/listings/*/reports",
		"POST /v1/conversations/*/reports")
	return out
}

// rateLimit answers 429 problem+json with Retry-After once a caller exceeds
// the limit of a route. Signed-in callers are keyed by user, others by the
// client IP (resolved through trusted proxies). It runs after the session
// middleware.
func rateLimit(rl RateLimits) func(http.Handler) http.Handler {
	routes := rateLimitRoutes(rl)
	return func(next http.Handler) http.Handler {
		if len(routes) == 0 {
			return next
		}
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			for _, lr := range routes {
				if !lr.matches(r) {
					continue
				}
				key := "ip:" + httpx.ClientIP(r.Context())
				if p := auth.FromContext(r.Context()); p != nil && lr.name != "webhook" {
					key = "user:" + p.UserID.String()
				}
				if ok, wait := lr.lim.Take(key); !ok {
					writeTooMany(w, r, wait)
					return
				}
				break
			}
			next.ServeHTTP(w, r)
		})
	}
}

func writeTooMany(w http.ResponseWriter, r *http.Request, wait time.Duration) {
	secs := max(1, int(math.Ceil(wait.Seconds())))
	w.Header().Set("Retry-After", strconv.Itoa(secs))
	httpx.WriteProblem(w, httpx.Problem{Status: http.StatusTooManyRequests, Code: "rate_limited",
		Detail: "too many requests, try again later", Instance: r.URL.Path})
}
