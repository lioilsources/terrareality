package auth

import (
	"testing"
	"time"
)

func TestPasswordRoundTrip(t *testing.T) {
	h, err := HashPassword("correct horse battery")
	if err != nil {
		t.Fatal(err)
	}
	if err := VerifyPassword("correct horse battery", h); err != nil {
		t.Fatalf("verify: %v", err)
	}
	if err := VerifyPassword("wrong", h); err != ErrMismatch {
		t.Fatalf("want mismatch, got %v", err)
	}
	h2, _ := HashPassword("correct horse battery")
	if h == h2 {
		t.Fatal("salt not random")
	}
}

// RFC 6238 appendix B, SHA1 secret "12345678901234567890", 8 digits truncated to 6.
func TestTOTPVectors(t *testing.T) {
	secret := []byte("12345678901234567890")
	cases := map[int64]string{59: "287082", 1111111109: "081804", 1234567890: "005924", 2000000000: "279037"}
	for ts, want := range cases {
		if got := TOTPCode(secret, ts/30); got != want {
			t.Errorf("t=%d: got %s want %s", ts, got, want)
		}
	}
}

func TestTOTPValidateSkew(t *testing.T) {
	s := NewTOTPSecret()
	now := time.Unix(1_800_000_000, 0)
	prev := TOTPCode(s, TOTPStep(now)-1)
	if step := ValidateTOTP(s, prev, now); step != TOTPStep(now)-1 {
		t.Fatalf("previous step not accepted: %d", step)
	}
	old := TOTPCode(s, TOTPStep(now)-3)
	if ValidateTOTP(s, old, now) != 0 {
		t.Fatal("stale code accepted")
	}
	if ValidateTOTP(s, "12345", now) != 0 {
		t.Fatal("short code accepted")
	}
}

func TestRecoveryCodes(t *testing.T) {
	codes := NewRecoveryCodes(10)
	seen := map[string]bool{}
	for _, c := range codes {
		if len(c) != 11 || c[5] != '-' || seen[c] {
			t.Fatalf("bad code %q", c)
		}
		seen[c] = true
		if NormalizeRecoveryCode(" "+c[:5]+c[6:]+" ") != c {
			t.Fatalf("normalize %q", c)
		}
	}
}
