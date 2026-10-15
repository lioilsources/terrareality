package account

import (
	"strconv"
	"sync"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// Per-account brute-force protection (ASVS V2.2.1). The handler limiters are
// per client IP; this guard counts failures per account key (e-mail for the
// password, user id for the second factor), so credential stuffing spread
// over many addresses still locks the targeted account. After lockFree
// failures each further failure locks the key for lockBase, doubling up to
// lockMax. A success clears the key. State is in-process like the rate
// limiters (one API instance); a persistent counter needs users.failed_logins
// and users.locked_until (review S-A1).
const (
	lockFree   = 5
	lockBase   = 30 * time.Second
	lockMax    = time.Hour
	lockForget = 24 * time.Hour // a key without failures for this long starts over
)

type lockEntry struct {
	failures    int
	lockedUntil time.Time
	last        time.Time
}

// lockout tracks failed attempts per key. The zero value is ready to use.
type lockout struct {
	mu     sync.Mutex
	m      map[string]*lockEntry
	now    func() time.Time // tests
	lastGC time.Time
}

func (l *lockout) clock() time.Time {
	if l.now != nil {
		return l.now()
	}
	return time.Now()
}

// check returns account_locked (429 with the wait) while key is locked.
func (l *lockout) check(key string) error {
	l.mu.Lock()
	defer l.mu.Unlock()
	e := l.m[key]
	if e == nil {
		return nil
	}
	if wait := e.lockedUntil.Sub(l.clock()); wait > 0 {
		return apperr.TooMany("too many failed attempts, try again in " + strconv.Itoa(int(wait.Seconds())+1) + " s")
	}
	return nil
}

// fail records a failed attempt and returns the failure count.
func (l *lockout) fail(key string) int {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := l.clock()
	if l.m == nil {
		l.m = map[string]*lockEntry{}
	}
	if now.Sub(l.lastGC) > 10*time.Minute {
		for k, e := range l.m {
			if now.Sub(e.last) > lockForget && now.After(e.lockedUntil) {
				delete(l.m, k)
			}
		}
		l.lastGC = now
	}
	e := l.m[key]
	if e == nil || now.Sub(e.last) > lockForget {
		e = &lockEntry{}
		l.m[key] = e
	}
	e.failures++
	e.last = now
	if over := e.failures - lockFree; over > 0 {
		d := lockBase
		for i := 1; i < over && d < lockMax; i++ {
			d *= 2
		}
		e.lockedUntil = now.Add(min(d, lockMax))
	}
	return e.failures
}

// reset forgets key after a successful attempt.
func (l *lockout) reset(key string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	delete(l.m, key)
}
