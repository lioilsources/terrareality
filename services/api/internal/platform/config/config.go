// Package config loads process configuration from environment variables.
package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/platform/ratelimit"
	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
)

// Config holds all runtime settings. Every field maps to one env var so that
// dev, staging (NAS) and production (Hetzner) differ only in their .env file.
type Config struct {
	Env             string // dev | staging | prod
	HTTPAddr        string
	DatabaseURL     string // prod: login role IN ROLE terra_service (api, worker, terractl)
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

	// Schema owner for cmd/migrate (goose + River), MIGRATE_DATABASE_URL;
	// falls back to DATABASE_URL (dev, tests). See ADR 0012 point 5.
	MigrateDatabaseURL string

	// Identity (M1).
	SecretKey        string        // 32+ bytes; seals TOTP secrets, signs mock IdP codes
	WebBaseURL       string        // links in e-mails point here
	APIPublicURL     string        // browser-reachable API URL (mock IdP pages)
	RedirectAllow    []string      // allowed OIDC redirect URI prefixes (web + mobile)
	SessionTTLWeb    time.Duration // sliding
	SessionTTLMobile time.Duration // sliding
	SessionMaxAge    time.Duration // SESSION_MAX_AGE, absolute lifetime regardless of activity (ASVS V3.3.2); default max(web, mobile)
	PwnedPasswords   string        // PWNED_PASSWORDS: hibp | local | off (breached-password check, ASVS V2.1.7)
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

	// Key rotation (M8b): APP_SECRET_KEY_PREVIOUS, comma-separated, newest first.
	// Previous keys only open and verify; see docs/runbooks/key-rotation.md.
	SecretKeyPrevious []string

	// Delivery.
	SMTPAddr     string // host:port; empty = log only
	SMTPUsername string // SMTP_USERNAME, empty = no SMTP auth
	SMTPPassword string // SMTP_PASSWORD
	MailFrom     string
	SMSProvider  string // mock | log (no real SMS adapter yet)
	// PhoneVerification (PHONE_VERIFICATION) enables SMS phone verification.
	// Outside dev/test it needs a real SMS provider, so it defaults to off
	// there and config refuses it with mock/log (OTP codes must not end up in
	// logs or a fake inbox).
	PhoneVerification bool

	// Object storage (S3 compatible).
	S3Endpoint  string // host:port
	S3AccessKey string
	S3SecretKey string
	S3Bucket    string
	S3UseSSL    bool
	S3Region    string

	RateBurst int // credential endpoint burst per client IP

	// Security (M8): per-route rate limits ("N/unit:burst" or "off") and HSTS.
	RateSearch  ratelimit.Rule // RATE_LIMIT_SEARCH, public search per IP
	RateChat    ratelimit.Rule // RATE_LIMIT_CHAT, chat-first search (LLM)
	RateWebhook ratelimit.Rule // RATE_LIMIT_WEBHOOK, payment webhooks per IP
	RateApply   ratelimit.Rule // RATE_LIMIT_APPLY, application submissions per user
	RateMessage ratelimit.Rule // RATE_LIMIT_MESSAGE, messages and new conversations per user
	RateReport  ratelimit.Rule // RATE_LIMIT_REPORT, listing/conversation reports per user or IP
	HSTS        bool           // Strict-Transport-Security on API responses (default: prod)

	// Cloud LLM fallback (M8), used only when the Spark gateway fails and the
	// flag ai.cloud_fallback is on. OpenAI-compatible gateway in front of Claude.
	CloudLLMBaseURL string // CLOUD_LLM_BASE_URL, empty = no fallback
	CloudLLMAPIKey  string
	CloudLLMModel   string // default claude-sonnet-5-5

	// Catalog (M2).
	LLMAPIKey    string
	ImgproxyURL  string        // browser-reachable imgproxy
	ImgproxyKey  string        // hex
	ImgproxySalt string        // hex
	ImgproxyTTL  time.Duration // IMGPROXY_URL_TTL: signed photo URLs expire after 1-2x this; 0 = never
	ClamAVAddr   string        // host:port of clamd; empty = scanning skipped
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

	// Leasing (M6).
	TypstBin          string // typst binary for lease documents
	TemplatesReviewed bool   // lawyer reviewed the templates: no DRAFT watermark
	BankProvider      string // mock | gocardless
	GoCardlessID      string
	GoCardlessKey     string

	// Billing (M7): Stripe for platform services only (ADR 0002), Revolut
	// Business merchant links landlord-direct, supplier data for invoices.
	StripeMode          string // mock | live (default mock without STRIPE_SECRET_KEY; never mock in prod)
	StripeSecretKey     string
	StripeWebhookSecret string
	RevolutMode         string // mock | live (default mock in dev/test)
	RevolutAPIURL       string // Merchant API base (sandbox by default)
	PlatformLegalName   string
	PlatformICO         string
	PlatformDIC         string
	PlatformAddress     string
	PlatformIBAN        string

	// Warnings are non-fatal configuration problems; the binaries log them at
	// startup (Load has no logger).
	Warnings []string
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
	c.MigrateDatabaseURL = get("MIGRATE_DATABASE_URL", c.DatabaseURL)
	devLike := c.Env == "dev" || c.Env == "test"
	c.SecretKey = get("APP_SECRET_KEY", "")
	if c.SecretKey == "" && devLike {
		c.SecretKey = "dev-only-secret-key-change-me-0123456789"
	}
	c.SecretKeyPrevious = splitList(get("APP_SECRET_KEY_PREVIOUS", ""))
	c.WebBaseURL = strings.TrimRight(get("WEB_BASE_URL", "http://localhost:5173"), "/")
	c.APIPublicURL = strings.TrimRight(get("API_PUBLIC_URL", "http://localhost:8080"), "/")
	redirectDefault := c.WebBaseURL + "/auth/,terra://auth/"
	if devLike {
		redirectDefault = c.WebBaseURL + "/auth/,http://localhost:4173/auth/,terra://auth/" // + web preview build
	}
	c.RedirectAllow = splitList(get("OIDC_REDIRECT_ALLOWLIST", redirectDefault))
	c.StaffRequireMFA = MustBool("STAFF_REQUIRE_MFA", !devLike)
	pwnedDefault := "hibp"
	if devLike {
		pwnedDefault = "local" // offline: make dev and tests need no network
	}
	c.PwnedPasswords = get("PWNED_PASSWORDS", pwnedDefault)
	c.TermsVersion = get("TERMS_VERSION", "2026-10")
	c.PrivacyVersion = get("PRIVACY_VERSION", "2026-10")
	c.MockIdP = MustBool("MOCK_IDP", devLike)
	c.GoogleClientID, c.GoogleSecret = get("GOOGLE_CLIENT_ID", ""), get("GOOGLE_CLIENT_SECRET", "")
	c.AppleClientID, c.AppleSecret = get("APPLE_CLIENT_ID", ""), get("APPLE_CLIENT_SECRET", "")
	c.BankIDIssuer = get("BANKID_ISSUER", "")
	c.BankIDClientID, c.BankIDSecret = get("BANKID_CLIENT_ID", ""), get("BANKID_CLIENT_SECRET", "")
	c.BankIDScopes = splitList(get("BANKID_SCOPES", "openid,profile.name,profile.birthdate,profile.addresses"))
	c.SMTPAddr = get("SMTP_ADDR", "")
	c.SMTPUsername, c.SMTPPassword = get("SMTP_USERNAME", ""), get("SMTP_PASSWORD", "")
	c.MailFrom = get("MAIL_FROM", "TerraReality <no-reply@terrareality.cz>")
	c.SMSProvider = get("SMS_PROVIDER", "mock")
	c.PhoneVerification = MustBool("PHONE_VERIFICATION", devLike)
	c.S3Endpoint = get("S3_ENDPOINT", "")
	c.S3AccessKey, c.S3SecretKey = get("S3_ACCESS_KEY", ""), get("S3_SECRET_KEY", "")
	c.S3Bucket = get("S3_BUCKET", "terra")
	c.S3UseSSL = MustBool("S3_USE_SSL", false)
	c.S3Region = get("S3_REGION", "us-east-1")
	c.LLMAPIKey = get("LLM_API_KEY", "not-needed")
	c.ImgproxyURL = strings.TrimRight(get("IMGPROXY_URL", "http://localhost:8081"), "/")
	// Dev defaults match infra/dev/docker-compose.yml.
	c.ImgproxyKey = get("IMGPROXY_KEY", devImgproxyKey)
	c.ImgproxySalt = get("IMGPROXY_SALT", devImgproxySalt)
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
	c.TypstBin = get("TYPST_BIN", "typst")
	c.TemplatesReviewed = MustBool("LEASE_TEMPLATES_REVIEWED", false)
	c.GoCardlessID, c.GoCardlessKey = get("GOCARDLESS_SECRET_ID", ""), get("GOCARDLESS_SECRET_KEY", "")
	bankDefault := "mock"
	if c.GoCardlessID != "" {
		bankDefault = "gocardless"
	}
	c.BankProvider = get("BANK_PROVIDER", bankDefault)
	c.StripeSecretKey = get("STRIPE_SECRET_KEY", "")
	c.StripeWebhookSecret = get("STRIPE_WEBHOOK_SECRET", "whsec_dev")
	stripeDefault := "mock"
	if c.StripeSecretKey != "" {
		stripeDefault = "live"
	}
	c.StripeMode = get("STRIPE_MODE", stripeDefault)
	revolutDefault := "live"
	if devLike {
		revolutDefault = "mock"
	}
	c.RevolutMode = get("REVOLUT_MODE", revolutDefault)
	c.RevolutAPIURL = get("REVOLUT_API_URL", "https://sandbox-merchant.revolut.com")
	c.PlatformLegalName = get("PLATFORM_LEGAL_NAME", "TerraReality s.r.o. (dev)")
	c.PlatformICO = get("PLATFORM_ICO", "00000000")
	c.PlatformDIC = get("PLATFORM_DIC", "CZ00000000")
	c.PlatformAddress = get("PLATFORM_ADDRESS", "Václavské náměstí 1, 110 00 Praha 1")
	c.PlatformIBAN = get("PLATFORM_IBAN", "CZ6508000000192000145399")
	// Feature flag defaults: comma list, "-name" turns a default off. Rows in
	// the feature_flags table (backoffice) override these (internal/flags).
	c.Flags = map[string]bool{"ai.attributes": true, "ai.text": true, "ai.vision": true, "ai.cloud_fallback": false, "ai.moderation": true, "ai.applications": true,
		"payments.revolut": devLike} // on in dev/test; staging/prod switch it on in the backoffice
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
	c.HSTS = MustBool("HSTS", c.Env == "prod")
	c.CloudLLMBaseURL = strings.TrimRight(get("CLOUD_LLM_BASE_URL", ""), "/")
	c.CloudLLMAPIKey = get("CLOUD_LLM_API_KEY", "")
	c.CloudLLMModel = get("CLOUD_LLM_MODEL", "claude-sonnet-5-5")
	// Production defaults; dev/test (one IP runs the whole e2e suite) are 20x looser.
	rates := []struct {
		key, prod, dev string
		dst            *ratelimit.Rule
	}{
		{"RATE_LIMIT_SEARCH", "120/m:60", "2400/m:1200", &c.RateSearch},
		{"RATE_LIMIT_CHAT", "10/m:5", "200/m:100", &c.RateChat},
		{"RATE_LIMIT_WEBHOOK", "600/m:300", "12000/m:6000", &c.RateWebhook},
		{"RATE_LIMIT_APPLY", "20/h:10", "400/h:200", &c.RateApply},
		{"RATE_LIMIT_MESSAGE", "30/m:20", "600/m:400", &c.RateMessage},
		{"RATE_LIMIT_REPORT", "10/h:5", "200/h:100", &c.RateReport},
	}
	for _, r := range rates {
		def := r.prod
		if devLike {
			def = r.dev
		}
		rule, err := ratelimit.ParseRule(get(r.key, def))
		if err != nil {
			return c, fmt.Errorf("%s: %w", r.key, err)
		}
		*r.dst = rule
	}

	durations := []struct {
		key, def string
		dst      *time.Duration
	}{
		{"SHUTDOWN_TIMEOUT", "15s", &c.ShutdownTimeout},
		{"SESSION_TTL_WEB", "720h", &c.SessionTTLWeb},
		{"SESSION_TTL_MOBILE", "2160h", &c.SessionTTLMobile},
		{"SESSION_MAX_AGE", "0", &c.SessionMaxAge}, // 0 = max(SESSION_TTL_WEB, SESSION_TTL_MOBILE), below
		{"GDPR_ERASURE_GRACE", "720h", &c.ErasureGrace},
		{"MESSAGE_NOTIFY_DELAY", "20s", &c.MessageNotifyDelay},
		{"IMGPROXY_URL_TTL", "0", &c.ImgproxyTTL},
	}
	for _, d := range durations {
		v, err := time.ParseDuration(get(d.key, d.def))
		if err != nil {
			return c, fmt.Errorf("%s: %w", d.key, err)
		}
		*d.dst = v
	}
	if c.ImgproxyTTL < 0 {
		return c, fmt.Errorf("IMGPROXY_URL_TTL must not be negative")
	}
	if c.Env != "dev" && c.Env != "staging" && c.Env != "prod" && c.Env != "test" {
		return c, fmt.Errorf("APP_ENV must be dev|staging|prod|test, got %q", c.Env)
	}
	// The absolute lifetime must not silently cut the sliding ones short: by
	// default it is the longer of the two (90-day mobile sessions stay 90 days).
	if c.SessionMaxAge == 0 {
		c.SessionMaxAge = max(c.SessionTTLWeb, c.SessionTTLMobile)
	} else if c.SessionMaxAge < 0 {
		return c, fmt.Errorf("SESSION_MAX_AGE must not be negative")
	} else {
		for _, t := range []struct {
			key string
			ttl time.Duration
		}{{"SESSION_TTL_WEB", c.SessionTTLWeb}, {"SESSION_TTL_MOBILE", c.SessionTTLMobile}} {
			if t.ttl > c.SessionMaxAge {
				c.Warnings = append(c.Warnings, fmt.Sprintf("%s (%s) is longer than SESSION_MAX_AGE (%s); those sessions end after %s",
					t.key, t.ttl, c.SessionMaxAge, c.SessionMaxAge))
			}
		}
	}
	// APP_SECRET_KEY_PREVIOUS entries are validated by secretbox.New (app.Build).
	if len(c.SecretKey) < secretbox.MinSecretLen {
		return c, fmt.Errorf("APP_SECRET_KEY must be at least %d characters", secretbox.MinSecretLen)
	}
	if len(c.SecretKeyPrevious) > 0 && os.Getenv("WEBPUSH_VAPID_SEED") == "" && !devLike {
		// The VAPID key pair derives from the seed; following a new
		// APP_SECRET_KEY would invalidate every browser push subscription.
		return c, fmt.Errorf("set WEBPUSH_VAPID_SEED (to the previous APP_SECRET_KEY) before rotating APP_SECRET_KEY, see docs/runbooks/key-rotation.md")
	}
	if c.CentrifugoURL != "" && c.CentrifugoTokenSecret == "" {
		return c, fmt.Errorf("CENTRIFUGO_TOKEN_SECRET is required with CENTRIFUGO_API_URL")
	}
	if c.BankProvider == "mock" && c.Env == "prod" {
		return c, fmt.Errorf("BANK_PROVIDER=mock is not allowed in prod")
	}
	if c.StripeMode != "mock" && c.StripeMode != "live" {
		return c, fmt.Errorf("STRIPE_MODE must be mock|live, got %q", c.StripeMode)
	}
	if c.Env == "prod" && (c.StripeMode == "mock" || c.StripeSecretKey == "") {
		return c, fmt.Errorf("STRIPE_SECRET_KEY is required in prod (STRIPE_MODE=mock is not allowed)")
	}
	if c.StripeMode == "live" && (c.StripeSecretKey == "" || c.StripeWebhookSecret == "" || c.StripeWebhookSecret == "whsec_dev") && !devLike {
		return c, fmt.Errorf("STRIPE_MODE=live needs STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET")
	}
	if c.RevolutMode != "mock" && c.RevolutMode != "live" {
		return c, fmt.Errorf("REVOLUT_MODE must be mock|live, got %q", c.RevolutMode)
	}
	if c.RevolutMode == "mock" && c.Env == "prod" {
		return c, fmt.Errorf("REVOLUT_MODE=mock is not allowed in prod")
	}
	switch c.PwnedPasswords {
	case "hibp", "local", "off":
	default:
		return c, fmt.Errorf("PWNED_PASSWORDS must be hibp|local|off, got %q", c.PwnedPasswords)
	}
	// The mock IdP lets anyone sign in as any e-mail (incl. staff), so it
	// never runs on a publicly reachable environment, staging included.
	if c.MockIdP && !devLike {
		return c, fmt.Errorf("MOCK_IDP is not allowed in %s", c.Env)
	}
	switch c.SMSProvider {
	case "mock", "log":
	default:
		return c, fmt.Errorf("SMS_PROVIDER must be mock|log, got %q", c.SMSProvider)
	}
	if c.PhoneVerification && !devLike {
		// mock mails the code to a fake inbox, log drops it: neither verifies a phone.
		return c, fmt.Errorf("PHONE_VERIFICATION needs a real SMS provider in %s (SMS_PROVIDER=%s)", c.Env, c.SMSProvider)
	}
	// Dev defaults that are unsafe on a public host: refused in prod, reported
	// on staging (NAS) which runs on them today.
	var unsafe []string
	if c.ImgproxyKey == devImgproxyKey || c.ImgproxySalt == devImgproxySalt {
		unsafe = append(unsafe, "IMGPROXY_KEY/IMGPROXY_SALT use the public dev values")
	}
	for _, r := range c.RedirectAllow {
		if isLocalURL(r) {
			unsafe = append(unsafe, fmt.Sprintf("OIDC_REDIRECT_ALLOWLIST contains %s", r))
		}
	}
	if len(unsafe) > 0 && !devLike {
		if c.Env == "prod" {
			return c, fmt.Errorf("unsafe configuration in prod: %s", strings.Join(unsafe, "; "))
		}
		c.Warnings = append(c.Warnings, unsafe...)
	}
	return c, nil
}

// Dev values of the imgproxy signing key and salt (infra/dev/docker-compose.yml).
const (
	devImgproxyKey  = "6465762d696d6770726f78792d6b6579"
	devImgproxySalt = "6465762d696d6770726f78792d73616c74"
)

// isLocalURL reports whether an allowlist entry points at a local host.
func isLocalURL(u string) bool {
	for _, h := range []string{"://localhost", "://127.", "://[::1]", "://0.0.0.0"} {
		if strings.Contains(u, h) {
			return true
		}
	}
	return false
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
