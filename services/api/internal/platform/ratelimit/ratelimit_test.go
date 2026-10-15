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
