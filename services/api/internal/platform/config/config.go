// Package config loads process configuration from environment variables.
package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config holds all runtime settings. Every field maps to one env var so that
// dev, staging (NAS) and production (Hetzner) differ only in their .env file.
type Config struct {
	Env             string // dev | staging | prod
	HTTPAddr        string
	DatabaseURL     string
	LogLevel        string
	LogFormat       string // text | json
	TemporalAddress string // empty = Temporal disabled
	TemporalNS      string
	CentrifugoURL   string
	CentrifugoKey   string
	VisionURL       string
	LLMBaseURL      string // empty = AI mock mode
	LLMModel        string
	EmbeddingsModel string
	OTLPEndpoint    string // empty = tracing to stdout disabled
	ShutdownTimeout time.Duration
	CORSOrigins     []string
	TrustedProxies  []string // CIDRs of reverse proxies allowed to set X-Forwarded-For

	// Identity (M1).
	SecretKey        string        // 32+ bytes; seals TOTP secrets, signs mock IdP codes
	WebBaseURL       string        // links in e-mails point here
	APIPublicURL     string        // browser-reachable API URL (mock IdP pages)
	RedirectAllow    []string      // allowed OIDC redirect URI prefixes (web + mobile)
	SessionTTLWeb    time.Duration // sliding
	SessionTTLMobile time.Duration // sliding
	StaffRequireMFA  bool
	ErasureGrace     time.Duration
	TermsVersion     string
	PrivacyVersion   string
	MockIdP          bool // enable the local mock identity provider (dev/test only)
	GoogleClientID   string
	GoogleSecret     string
	AppleClientID    string
	AppleSecret      string // pre-generated client secret JWT (rotate every 6 months)
	BankIDIssuer     string // e.g. https://oidc.sandbox.bankid.cz/
	BankIDClientID   string
	BankIDSecret     string
	BankIDScopes     []string

	// Delivery.
	SMTPAddr    string // host:port; empty = log only
	MailFrom    string
	SMSProvider string // mock | log

	// Object storage (S3 compatible).
	S3Endpoint  string // host:port
	S3AccessKey string
	S3SecretKey string
	S3Bucket    string
	S3UseSSL    bool
	S3Region    string

	RateBurst int // credential endpoint burst per client IP

	// Catalog (M2).
	LLMAPIKey    string
	ImgproxyURL  string // browser-reachable imgproxy
	ImgproxyKey  string // hex
	ImgproxySalt string // hex
	ClamAVAddr   string // host:port of clamd; empty = scanning skipped
	Flags        map[string]bool
	SeedRuian    bool // load the embedded RÚIAN sample when the table is empty

	// Messaging (M4).
	CentrifugoTokenSecret string        // HMAC key for client tokens (same as Centrifugo's)
	CentrifugoWSURL       string        // websocket URL for browsers and the app
	MessageNotifyDelay    time.Duration // push/e-mail only if still unread after this
	PushProvider          string        // mock | log | fcm
	FCMCredentialsFile    string        // service account JSON (PUSH_PROVIDER=fcm)
	FCMProject            string        // defaults to the project in the credentials
	WebPushSeed           string        // derives the VAPID key pair (default: APP_SECRET_KEY)
	WebPushSubject        string        // contact for push services

	// Applications (M5).
	ISIRMode string // mock | live (public ISIR web service)
	ISIRURL  string // override of the ISIR endpoint
}

// Flag reports whether a feature flag is on.
func (c Config) Flag(name string) bool { return c.Flags[name] }

// Load reads the environment. It returns an error only for values that are
// present but malformed; missing optional values fall back to dev defaults.
func Load() (Config, error) {
	c := Config{
		Env:             get("APP_ENV", "dev"),
		HTTPAddr:        get("HTTP_ADDR", ":8080"),
		DatabaseURL:     get("DATABASE_URL", "postgres://terra:terra@localhost:5433/terra?sslmode=disable"),
		LogLevel:        get("LOG_LEVEL", "info"),
		LogFormat:       get("LOG_FORMAT", "text"),
		TemporalAddress: get("TEMPORAL_ADDRESS", ""),
		TemporalNS:      get("TEMPORAL_NAMESPACE", "default"),
		CentrifugoURL:   get("CENTRIFUGO_API_URL", ""),
		CentrifugoKey:   get("CENTRIFUGO_API_KEY", ""),
		VisionURL:       get("VISION_URL", ""),
		LLMBaseURL:      get("LLM_BASE_URL", ""),
		LLMModel:        get("LLM_MODEL", "openclaw-default"),
		EmbeddingsModel: get("EMBEDDINGS_MODEL", ""), // empty = no embeddings (similar listings off)
		OTLPEndpoint:    get("OTEL_EXPORTER_OTLP_ENDPOINT", ""),
		CORSOrigins:     splitList(get("CORS_ORIGINS", "http://localhost:5173,http://localhost:4321")),
		TrustedProxies:  splitList(get("TRUSTED_PROXIES", "127.0.0.1,::1")),
	}
	devLike := c.Env == "dev" || c.Env == "test"
	c.SecretKey = get("APP_SECRET_KEY", "")
	if c.SecretKey == "" && devLike {
		c.SecretKey = "dev-only-secret-key-change-me-0123456789"
	}
	c.WebBaseURL = strings.TrimRight(get("WEB_BASE_URL", "http://localhost:5173"), "/")
	c.APIPublicURL = strings.TrimRight(get("API_PUBLIC_URL", "http://localhost:8080"), "/")
	c.RedirectAllow = splitList(get("OIDC_REDIRECT_ALLOWLIST", c.WebBaseURL+"/auth/,http://localhost:4173/auth/,terra://auth/"))
	c.StaffRequireMFA = MustBool("STAFF_REQUIRE_MFA", !devLike)
	c.TermsVersion = get("TERMS_VERSION", "2026-10")
	c.PrivacyVersion = get("PRIVACY_VERSION", "2026-10")
	c.MockIdP = MustBool("MOCK_IDP", devLike)
	c.GoogleClientID, c.GoogleSecret = get("GOOGLE_CLIENT_ID", ""), get("GOOGLE_CLIENT_SECRET", "")
	c.AppleClientID, c.AppleSecret = get("APPLE_CLIENT_ID", ""), get("APPLE_CLIENT_SECRET", "")
	c.BankIDIssuer = get("BANKID_ISSUER", "")
	c.BankIDClientID, c.BankIDSecret = get("BANKID_CLIENT_ID", ""), get("BANKID_CLIENT_SECRET", "")
	c.BankIDScopes = splitList(get("BANKID_SCOPES", "openid,profile.name,profile.birthdate,profile.addresses"))
	c.SMTPAddr = get("SMTP_ADDR", "")
	c.MailFrom = get("MAIL_FROM", "TerraReality <no-reply@terrareality.cz>")
	c.SMSProvider = get("SMS_PROVIDER", "mock")
	c.S3Endpoint = get("S3_ENDPOINT", "")
	c.S3AccessKey, c.S3SecretKey = get("S3_ACCESS_KEY", ""), get("S3_SECRET_KEY", "")
	c.S3Bucket = get("S3_BUCKET", "terra")
	c.S3UseSSL = MustBool("S3_USE_SSL", false)
	c.S3Region = get("S3_REGION", "us-east-1")
	c.LLMAPIKey = get("LLM_API_KEY", "not-needed")
	c.ImgproxyURL = strings.TrimRight(get("IMGPROXY_URL", "http://localhost:8081"), "/")
	// Dev defaults match infra/dev/docker-compose.yml.
	c.ImgproxyKey = get("IMGPROXY_KEY", "6465762d696d6770726f78792d6b6579")
	c.ImgproxySalt = get("IMGPROXY_SALT", "6465762d696d6770726f78792d73616c74")
	c.ClamAVAddr = get("CLAMAV_ADDR", "")
	c.SeedRuian = MustBool("SEED_RUIAN_SAMPLE", devLike)
	c.CentrifugoTokenSecret = get("CENTRIFUGO_TOKEN_SECRET", "")
	if c.CentrifugoTokenSecret == "" && devLike {
		c.CentrifugoTokenSecret = "dev-centrifugo-token-secret-change-me" // infra/dev/centrifugo/config.json
	}
	c.CentrifugoWSURL = get("CENTRIFUGO_WS_URL", "ws://localhost:8000/connection/websocket")
	pushDefault := "log"
	if devLike {
		pushDefault = "mock"
	}
	c.PushProvider = get("PUSH_PROVIDER", pushDefault)
	c.FCMCredentialsFile, c.FCMProject = get("FCM_CREDENTIALS_FILE", ""), get("FCM_PROJECT_ID", "")
	c.WebPushSeed = get("WEBPUSH_VAPID_SEED", c.SecretKey)
	c.WebPushSubject = get("WEBPUSH_SUBJECT", "mailto:podpora@terrareality.cz")
	isirDefault := "live"
	if devLike {
		isirDefault = "mock"
	}
	c.ISIRMode, c.ISIRURL = get("ISIR_MODE", isirDefault), get("ISIR_URL", "")
	// Feature flags: comma list, "-name" turns a default off.
	c.Flags = map[string]bool{"ai.attributes": true, "ai.text": true, "ai.vision": true, "ai.cloud_fallback": false, "ai.moderation": true, "ai.applications": true}
	for _, f := range splitList(get("FEATURE_FLAGS", "")) {
		if strings.HasPrefix(f, "-") {
			c.Flags[f[1:]] = false
		} else {
			c.Flags[f] = true
		}
	}
	if n, err := strconv.Atoi(get("AUTH_RATE_BURST", "10")); err == nil {
		c.RateBurst = n
	}

	durations := []struct {
		key, def string
		dst      *time.Duration
	}{
		{"SHUTDOWN_TIMEOUT", "15s", &c.ShutdownTimeout},
		{"SESSION_TTL_WEB", "720h", &c.SessionTTLWeb},
		{"SESSION_TTL_MOBILE", "2160h", &c.SessionTTLMobile},
		{"GDPR_ERASURE_GRACE", "720h", &c.ErasureGrace},
		{"MESSAGE_NOTIFY_DELAY", "20s", &c.MessageNotifyDelay},
	}
	for _, d := range durations {
		v, err := time.ParseDuration(get(d.key, d.def))
		if err != nil {
			return c, fmt.Errorf("%s: %w", d.key, err)
		}
		*d.dst = v
	}
	if c.Env != "dev" && c.Env != "staging" && c.Env != "prod" && c.Env != "test" {
		return c, fmt.Errorf("APP_ENV must be dev|staging|prod|test, got %q", c.Env)
	}
	if len(c.SecretKey) < 32 {
		return c, fmt.Errorf("APP_SECRET_KEY must be at least 32 characters")
	}
	if c.CentrifugoURL != "" && c.CentrifugoTokenSecret == "" {
		return c, fmt.Errorf("CENTRIFUGO_TOKEN_SECRET is required with CENTRIFUGO_API_URL")
	}
	if c.MockIdP && !devLike && c.Env != "staging" {
		return c, fmt.Errorf("MOCK_IDP is not allowed in %s", c.Env)
	}
	return c, nil
}

// MustBool parses a boolean env var with a default.
func MustBool(key string, def bool) bool {
	v, ok := os.LookupEnv(key)
	if !ok {
		return def
	}
	b, err := strconv.ParseBool(v)
	if err != nil {
		return def
	}
	return b
}

func get(key, def string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return def
}

func splitList(s string) []string {
	var out []string
	for _, p := range strings.Split(s, ",") {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}
