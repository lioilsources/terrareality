package account

import (
	"testing"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

func TestLockoutBacksOffExponentially(t *testing.T) {
	now := time.Date(2026, 10, 1, 12, 0, 0, 0, time.UTC)
	l := &lockout{now: func() time.Time { return now }}
	const key = "password:victim@example.com"
	for i := range lockFree {
		if err := l.check(key); err != nil {
			t.Fatalf("locked after %d failures", i)
		}
		l.fail(key)
	}
	if err := l.check(key); err != nil {
		t.Fatal("the free attempts must not lock yet")
	}
	l.fail(key) // 6th: locked for lockBase
	if l.check(key) == nil {
		t.Fatal("not locked after the free attempts")
	}
	now = now.Add(lockBase + time.Second)
	if err := l.check(key); err != nil {
		t.Fatalf("still locked after %s: %v", lockBase, err)
	}
	l.fail(key) // 7th: twice as long
	now = now.Add(lockBase + time.Second)
	if l.check(key) == nil {
		t.Fatal("second lock must be longer than the first")
	}
	for range 30 {
		l.fail(key)
	}
	if d := l.m[key].lockedUntil.Sub(now); d > lockMax {
		t.Fatalf("lock %s exceeds the maximum", d)
	}

	// Other accounts are unaffected; success clears the key.
	if err := l.check("password:other@example.com"); err != nil {
		t.Fatal(err)
	}
	l.reset(key)
	if err := l.check(key); err != nil {
		t.Fatal(err)
	}
}

func TestCheckLockedUsesPersistentLock(t *testing.T) {
	now := time.Now()
	if err := checkLocked(db.User{}, now); err != nil {
		t.Fatalf("never failed: %v", err)
	}
	past := now.Add(-time.Second)
	if err := checkLocked(db.User{LockedUntil: &past}, now); err != nil {
		t.Fatalf("expired lock: %v", err)
	}
	future := now.Add(90 * time.Second)
	if e, ok := apperr.As(checkLocked(db.User{LockedUntil: &future}, now)); !ok || e.Status != 429 {
		t.Fatalf("locked account: %v", e)
	}
}
