// Package ratelimit is an in-process token bucket keyed by string (client IP,
// e-mail). It protects credential endpoints of a single API instance; a shared
// limiter (Postgres or Caddy) is needed once the API runs on several nodes.
package ratelimit

import (
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
	return e.lim.Allow()
}
