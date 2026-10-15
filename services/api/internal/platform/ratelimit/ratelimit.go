// Package ratelimit is an in-process token bucket keyed by string (client IP,
// user id, e-mail). It protects credential, search, LLM and write endpoints of
// a single API instance; a shared limiter (Postgres or Caddy) is needed once
// the API runs on several nodes.
package ratelimit

import (
	"fmt"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

// Limiter holds one bucket per key and forgets idle keys.
type Limiter struct {
	mu      sync.Mutex
	buckets map[string]*entry
	every   time.Duration
	burst   int
	lastGC  time.Time
}

type entry struct {
	lim  *rate.Limiter
	seen time.Time
}

// New allows burst events and then one event per every.
func New(every time.Duration, burst int) *Limiter {
	return &Limiter{buckets: map[string]*entry{}, every: every, burst: burst, lastGC: time.Now()}
}

// Allow reports whether an event for key may happen now.
func (l *Limiter) Allow(key string) bool {
	ok, _ := l.Take(key)
	return ok
}

// Take is Allow that also says, when refused, how long until the next event
// for key would pass (for Retry-After).
func (l *Limiter) Take(key string) (bool, time.Duration) {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	if now.Sub(l.lastGC) > 10*time.Minute {
		for k, e := range l.buckets {
			if now.Sub(e.seen) > time.Hour {
				delete(l.buckets, k)
			}
		}
		l.lastGC = now
	}
	e, ok := l.buckets[key]
	if !ok {
		e = &entry{lim: rate.NewLimiter(rate.Every(l.every), l.burst)}
		l.buckets[key] = e
	}
	e.seen = now
	r := e.lim.ReserveN(now, 1)
	if !r.OK() {
		return false, l.every
	}
	if d := r.DelayFrom(now); d > 0 {
		r.CancelAt(now)
		return false, d
	}
	return true, 0
}

// Rule is a configured limit: Burst events, then one per Every. The zero
// Rule (Off) disables limiting.
type Rule struct {
	Every time.Duration
	Burst int
}

// Off reports whether the rule disables limiting.
func (r Rule) Off() bool { return r.Every <= 0 || r.Burst <= 0 }

// Limiter returns a limiter for the rule, nil when it is off.
func (r Rule) Limiter() *Limiter {
	if r.Off() {
		return nil
	}
	return New(r.Every, r.Burst)
}

func (r Rule) String() string {
	if r.Off() {
		return "off"
	}
	return fmt.Sprintf("every %s, burst %d", r.Every, r.Burst)
}

// ParseRule parses "N/unit[:burst]" (unit s, m or h; burst defaults to N),
// for example "60/m:30" = 30 at once, then one per second. "off" or "0"
// disables the limit.
func ParseRule(s string) (Rule, error) {
	s = strings.TrimSpace(strings.ToLower(s))
	if s == "off" || s == "0" || s == "" {
		return Rule{}, nil
	}
	spec, burstStr, hasBurst := strings.Cut(s, ":")
	nStr, unit, ok := strings.Cut(spec, "/")
	if !ok {
		return Rule{}, fmt.Errorf("rate %q: want N/unit[:burst]", s)
	}
	n, err := strconv.Atoi(nStr)
	if err != nil || n <= 0 {
		return Rule{}, fmt.Errorf("rate %q: bad count", s)
	}
	var per time.Duration
	switch unit {
	case "s", "sec", "second":
		per = time.Second
	case "m", "min", "minute":
		per = time.Minute
	case "h", "hour":
		per = time.Hour
	default:
		return Rule{}, fmt.Errorf("rate %q: unit must be s, m or h", s)
	}
	burst := n
	if hasBurst {
		if burst, err = strconv.Atoi(burstStr); err != nil || burst <= 0 {
			return Rule{}, fmt.Errorf("rate %q: bad burst", s)
		}
	}
	return Rule{Every: per / time.Duration(n), Burst: burst}, nil
}
