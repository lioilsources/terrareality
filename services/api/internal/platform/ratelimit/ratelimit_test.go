package ratelimit

import (
	"testing"
	"time"
)

func TestTake(t *testing.T) {
	l := New(time.Minute, 2)
	for i := range 2 {
		if ok, _ := l.Take("a"); !ok {
			t.Fatalf("event %d refused within burst", i)
		}
	}
	ok, wait := l.Take("a")
	if ok || wait <= 0 || wait > time.Minute {
		t.Fatalf("third event: ok=%v wait=%s", ok, wait)
	}
	if ok, _ := l.Take("b"); !ok {
		t.Fatal("other key must have its own bucket")
	}
	// A refused event must not consume a token: the wait stays bounded.
	_, wait2 := l.Take("a")
	if wait2 > time.Minute {
		t.Fatalf("refusal consumed a token: wait %s", wait2)
	}
}

func TestParseRule(t *testing.T) {
	cases := map[string]Rule{
		"60/m:30": {Every: time.Second, Burst: 30},
		"10/s":    {Every: 100 * time.Millisecond, Burst: 10},
		"6/h:2":   {Every: 10 * time.Minute, Burst: 2},
		"off":     {},
		"0":       {},
	}
	for in, want := range cases {
		got, err := ParseRule(in)
		if err != nil || got != want {
			t.Errorf("ParseRule(%q) = %+v, %v; want %+v", in, got, err, want)
		}
	}
	for _, bad := range []string{"60", "x/m", "60/d", "60/m:x", "-1/m"} {
		if _, err := ParseRule(bad); err == nil {
			t.Errorf("ParseRule(%q) accepted", bad)
		}
	}
	if !(Rule{}).Off() || (Rule{}).Limiter() != nil {
		t.Error("zero rule must be off")
	}
}

func TestSlowRuleSurvivesIdleGC(t *testing.T) {
	// 5 per day: an exhausted bucket must not be forgotten after an idle hour.
	l := New(24*time.Hour/5, 5)
	for range 5 {
		l.Take("victim@example.com")
	}
	l.mu.Lock()
	l.buckets["victim@example.com"].seen = time.Now().Add(-2 * time.Hour)
	l.lastGC = time.Now().Add(-time.Hour)
	l.mu.Unlock()
	if ok, _ := l.Take("victim@example.com"); ok {
		t.Fatal("daily cap reset by idle-key GC")
	}

	// Fast rules still forget idle keys after an hour.
	f := New(time.Second, 1)
	f.Take("a")
	f.mu.Lock()
	f.buckets["a"].seen = time.Now().Add(-2 * time.Hour)
	f.lastGC = time.Now().Add(-time.Hour)
	f.mu.Unlock()
	f.Take("b") // triggers GC
	f.mu.Lock()
	_, kept := f.buckets["a"]
	f.mu.Unlock()
	if kept {
		t.Fatal("idle key of a fast rule not collected")
	}
}
