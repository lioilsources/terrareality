package config

import (
	"strings"
	"testing"
	"time"
)

// staging sets the minimum for a non-dev environment that passes Load.
func staging(t *testing.T) {
	t.Helper()
	t.Setenv("APP_ENV", "staging")
	t.Setenv("APP_SECRET_KEY", strings.Repeat("k", 32))
	t.Setenv("WEB_BASE_URL", "https://staging.example.cz")
	t.Setenv("IMGPROXY_KEY", "aa")
	t.Setenv("IMGPROXY_SALT", "bb")
	t.Setenv("MOCK_IDP", "")
	t.Setenv("PHONE_VERIFICATION", "")
	t.Setenv("SMS_PROVIDER", "")
	t.Setenv("OIDC_REDIRECT_ALLOWLIST", "")
}

func TestSessionMaxAgeDefaultsToLongestTTL(t *testing.T) {
	t.Setenv("APP_ENV", "test")
	t.Setenv("SESSION_TTL_WEB", "720h")
	t.Setenv("SESSION_TTL_MOBILE", "2160h")
	t.Setenv("SESSION_MAX_AGE", "")
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if c.SessionMaxAge != 2160*time.Hour || len(c.Warnings) != 0 {
		t.Fatalf("max age %s, warnings %v", c.SessionMaxAge, c.Warnings)
	}

	// An explicit shorter cap is honoured but reported.
	t.Setenv("SESSION_MAX_AGE", "720h")
	c, err = Load()
	if err != nil {
		t.Fatal(err)
	}
	if c.SessionMaxAge != 720*time.Hour || len(c.Warnings) != 1 || !strings.Contains(c.Warnings[0], "SESSION_TTL_MOBILE") {
		t.Fatalf("max age %s, warnings %v", c.SessionMaxAge, c.Warnings)
	}
}

func TestMockIdPOnlyInDevAndTest(t *testing.T) {
	staging(t)
	if _, err := Load(); err != nil {
		t.Fatalf("staging defaults: %v", err)
	}
	t.Setenv("MOCK_IDP", "true")
	if _, err := Load(); err == nil || !strings.Contains(err.Error(), "MOCK_IDP") {
		t.Fatalf("MOCK_IDP on staging: %v", err)
	}
}

func TestPhoneVerificationNeedsRealSMS(t *testing.T) {
	staging(t)
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if c.PhoneVerification {
		t.Fatal("phone verification must default to off outside dev/test")
	}
	t.Setenv("PHONE_VERIFICATION", "true")
	t.Setenv("SMS_PROVIDER", "log")
	if _, err := Load(); err == nil || !strings.Contains(err.Error(), "PHONE_VERIFICATION") {
		t.Fatalf("phone verification with SMS_PROVIDER=log: %v", err)
	}
	t.Setenv("PHONE_VERIFICATION", "")
	t.Setenv("SMS_PROVIDER", "carrier-pigeon")
	if _, err := Load(); err == nil || !strings.Contains(err.Error(), "SMS_PROVIDER") {
		t.Fatalf("unknown SMS_PROVIDER: %v", err)
	}
}

func TestUnsafeDevDefaults(t *testing.T) {
	staging(t)
	t.Setenv("IMGPROXY_KEY", "")
	t.Setenv("OIDC_REDIRECT_ALLOWLIST", "https://staging.example.cz/auth/,http://localhost:4173/auth/")
	c, err := Load()
	if err != nil {
		t.Fatalf("staging only warns: %v", err)
	}
	if len(c.Warnings) != 2 {
		t.Fatalf("warnings %v", c.Warnings)
	}
	// The default allowlist outside dev/test has no localhost entry.
	t.Setenv("OIDC_REDIRECT_ALLOWLIST", "")
	if c, _ = Load(); strings.Contains(strings.Join(c.RedirectAllow, ","), "localhost") {
		t.Fatalf("default allowlist %v", c.RedirectAllow)
	}

	// prod refuses them.
	t.Setenv("APP_ENV", "prod")
	t.Setenv("GOCARDLESS_SECRET_ID", "id")
	t.Setenv("STRIPE_SECRET_KEY", "sk_live_x")
	t.Setenv("STRIPE_WEBHOOK_SECRET", "whsec_live")
	t.Setenv("STRIPE_MODE", "")
	t.Setenv("REVOLUT_MODE", "")
	t.Setenv("BANK_PROVIDER", "")
	if _, err := Load(); err == nil || !strings.Contains(err.Error(), "IMGPROXY_KEY") {
		t.Fatalf("prod with dev imgproxy key: %v", err)
	}
	t.Setenv("IMGPROXY_KEY", "aa")
	if _, err := Load(); err != nil {
		t.Fatalf("prod with real keys: %v", err)
	}
}
