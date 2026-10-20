// Package app wires adapters from configuration. Both binaries (api, worker)
// use it so they agree on providers, storage and delivery.
package app

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"net/smtp"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/billing"
	"github.com/terrareality/terrareality/services/api/internal/flags"
	"github.com/terrareality/terrareality/services/api/internal/identity"
	"github.com/terrareality/terrareality/services/api/internal/isir"
	"github.com/terrareality/terrareality/services/api/internal/jobs"
	"github.com/terrareality/terrareality/services/api/internal/leasing"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	"github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/pwned"
	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
	"github.com/terrareality/terrareality/services/api/internal/portfolio"
	"github.com/terrareality/terrareality/services/api/internal/realtime"
	"github.com/terrareality/terrareality/services/api/internal/storage"
	"github.com/terrareality/terrareality/services/api/internal/vision"
)

// Deps are the configured adapters.
type Deps struct {
	Box      *secretbox.Box
	Renderer *notify.Renderer
	IDP      *identity.Registry
	MockIdP  http.Handler // nil when no mock provider is active
	Blob     storage.Blob
	Sender   notify.Sender
	Img      *media.Imgproxy
	Scanner  media.Scanner
	Vision   *vision.Client
	AI       ai.Assistant
	RT       realtime.Publisher
	Pusher   notify.Pusher
	WebPush  *notify.WebPush
}

// Build creates adapters. Real providers are used when their credentials are
// configured; otherwise mocks (dev/test only) keep everything working offline.
func Build(cfg config.Config, log *slog.Logger) (Deps, error) {
	var d Deps
	var err error
	if d.Box, err = secretbox.New(cfg.SecretKey, cfg.SecretKeyPrevious...); err != nil {
		return d, err
	}
	if d.Renderer, err = notify.NewRenderer(); err != nil {
		return d, err
	}

	mocks := map[string]*identity.Mock{}
	mock := func(id string) identity.Provider {
		m := identity.NewMock(id, cfg.APIPublicURL, d.Box)
		mocks[id] = m
		return m
	}
	var social []identity.Provider
	switch {
	case cfg.GoogleClientID != "":
		social = append(social, identity.NewOIDC(identity.OIDCConfig{ID: "google", Issuer: "https://accounts.google.com",
			ClientID: cfg.GoogleClientID, ClientSecret: cfg.GoogleSecret, Scopes: []string{"openid", "email", "profile"}}))
	case cfg.MockIdP:
		social = append(social, mock("google"))
	}
	switch {
	case cfg.AppleClientID != "":
		social = append(social, identity.NewOIDC(identity.OIDCConfig{ID: "apple", Issuer: "https://appleid.apple.com",
			ClientID: cfg.AppleClientID, ClientSecret: cfg.AppleSecret, Scopes: []string{"openid", "email", "name"}, FormPost: true}))
	case cfg.MockIdP:
		social = append(social, mock("apple"))
	}
	var verifier identity.Provider
	switch {
	case cfg.BankIDIssuer != "":
		verifier = identity.NewOIDC(identity.OIDCConfig{ID: "bankid", Issuer: cfg.BankIDIssuer, ClientID: cfg.BankIDClientID,
			ClientSecret: cfg.BankIDSecret, Scopes: cfg.BankIDScopes, UseUserInfo: true})
	case cfg.MockIdP:
		verifier = mock("bankid")
	}
	d.IDP = identity.NewRegistry(verifier, social...)
	if len(mocks) > 0 {
		d.MockIdP = identity.MockHandler(mocks)
	}

	switch {
	case cfg.S3Endpoint != "":
		if d.Blob, err = storage.NewS3(storage.S3Config{Endpoint: cfg.S3Endpoint, AccessKey: cfg.S3AccessKey,
			SecretKey: cfg.S3SecretKey, Bucket: cfg.S3Bucket, Region: cfg.S3Region, UseSSL: cfg.S3UseSSL}); err != nil {
			return d, err
		}
	case cfg.Env == "dev" || cfg.Env == "test":
		log.Warn("S3_ENDPOINT not set, using in-memory object storage")
		d.Blob = storage.NewMemory(cfg.APIPublicURL + "/dev/blob")
	default:
		return d, fmt.Errorf("S3_ENDPOINT is required in %s", cfg.Env)
	}

	var email notify.Sender = notify.Log{L: log}
	if cfg.SMTPAddr != "" {
		var a smtp.Auth
		if cfg.SMTPUsername != "" {
			host, _, err := net.SplitHostPort(cfg.SMTPAddr)
			if err != nil {
				return d, fmt.Errorf("SMTP_ADDR: %w", err)
			}
			a = smtp.PlainAuth("", cfg.SMTPUsername, cfg.SMTPPassword, host)
		}
		email = &notify.SMTP{Addr: cfg.SMTPAddr, From: cfg.MailFrom, Auth: a}
	}
	var sms notify.Sender = notify.Log{L: log}
	if cfg.SMSProvider == "mock" {
		sms = notify.SMSViaEmail{Email: email}
	}
	d.Sender = notify.Router{Email: email, SMS: sms}

	if d.Img, err = media.NewImgproxy(cfg.ImgproxyURL, cfg.S3Bucket, cfg.ImgproxyKey, cfg.ImgproxySalt); err != nil {
		return d, err
	}
	d.Img.TTL = cfg.ImgproxyTTL
	d.Scanner = media.NoScanner{}
	if cfg.ClamAVAddr != "" {
		d.Scanner = media.ClamAV{Addr: cfg.ClamAVAddr}
	} else if cfg.Env == "prod" {
		log.Warn("CLAMAV_ADDR not set, uploads are not scanned for malware")
	}
	d.Vision = vision.New(cfg.VisionURL)
	d.AI = ai.Mock{}
	if cfg.LLMBaseURL != "" {
		d.AI = LLM(cfg, log)
	}

	if cfg.CentrifugoURL != "" {
		d.RT = realtime.NewCentrifugo(cfg.CentrifugoURL, cfg.CentrifugoKey)
	} else {
		log.Warn("CENTRIFUGO_API_URL not set, realtime events stay in memory")
		d.RT = &realtime.Memory{}
	}
	var mobile notify.Pusher = notify.PushLog{L: log}
	switch cfg.PushProvider {
	case "mock":
		mobile = notify.PushViaEmail{Email: email}
	case "fcm":
		creds, err := os.ReadFile(cfg.FCMCredentialsFile)
		if err != nil {
			return d, fmt.Errorf("FCM_CREDENTIALS_FILE: %w", err)
		}
		if mobile, err = notify.NewFCM(context.Background(), cfg.FCMProject, creds, notify.PushLog{L: log}); err != nil {
			return d, err
		}
	}
	if d.WebPush, err = notify.NewWebPush(cfg.WebPushSeed, cfg.WebPushSubject); err != nil {
		return d, err
	}
	// Browser subscriptions always go to the real push services (they are
	// created by real browsers); PUSH_PROVIDER=log silences everything.
	web := notify.Pusher(d.WebPush)
	if cfg.PushProvider == "log" {
		web = mobile
	}
	d.Pusher = notify.PlatformRouter{Web: web, Mobile: mobile}
	return d, nil
}

// LLM returns the Spark gateway client. With CLOUD_LLM_BASE_URL set it carries
// the cloud fallback, which stays inactive until GateCloudFallback ties it to
// the flag ai.cloud_fallback.
func LLM(cfg config.Config, log *slog.Logger) *ai.Client {
	c := ai.NewClient(cfg.LLMBaseURL, cfg.LLMAPIKey, cfg.LLMModel)
	c.Log = log
	c.Fallback = ai.NewEndpoint(cfg.CloudLLMBaseURL, cfg.CloudLLMAPIKey, cfg.CloudLLMModel)
	return c
}

// GateCloudFallback enables the cloud fallback of the given LLM clients per
// request while the flag ai.cloud_fallback is on (backoffice-editable).
func GateCloudFallback(fl *flags.Store, clients ...any) {
	for _, x := range clients {
		if c, ok := x.(*ai.Client); ok && c != nil {
			c.FallbackOn = func(ctx context.Context) bool { return fl.Enabled(ctx, ai.FlagCloudFallback) }
		}
	}
}

// Moderator returns the AI used for moderation verdicts.
func (d Deps) Moderator() ai.Moderator {
	if m, ok := d.AI.(ai.Moderator); ok {
		return m
	}
	return ai.Mock{}
}

// Summarizer returns the AI used for application summaries.
func (d Deps) Summarizer() ai.Summarizer {
	if m, ok := d.AI.(ai.Summarizer); ok {
		return m
	}
	return ai.Mock{}
}

// ISIR returns the insolvency register checker: the public web service in
// production, the mock in dev/test unless ISIR_MODE=live.
func ISIR(cfg config.Config) isir.Checker {
	if cfg.ISIRMode == "live" {
		return isir.NewClient(cfg.ISIRURL)
	}
	return isir.Mock{}
}

// Leasing builds the lease service; mockBank is non-nil when the mock bank is
// active (the dev transaction endpoint needs it).
func Leasing(cfg config.Config, d Deps, pool *pgxpool.Pool, jobs leasing.Jobs, outbox notify.Outbox, log *slog.Logger) (*leasing.Service, *leasing.MockBank) {
	svc := &leasing.Service{Pool: pool, Render: leasing.Typst{Bin: cfg.TypstBin},
		Signers: map[string]leasing.SignatureProvider{"mock": leasing.MockSigner{}}, Blob: d.Blob, Scanner: d.Scanner, Jobs: jobs,
		Outbox: outbox, Mail: d.Renderer, Pusher: d.Pusher, WebBaseURL: cfg.WebBaseURL, TemplatesReviewed: cfg.TemplatesReviewed, Log: log}
	var mock *leasing.MockBank
	switch cfg.BankProvider {
	case "gocardless":
		svc.Bank = leasing.NewGoCardless(cfg.GoCardlessID, cfg.GoCardlessKey)
	default:
		mock = &leasing.MockBank{}
		svc.Bank = mock
	}
	return svc, mock
}

// Portfolio builds the portfolio service (rent roll, risk, dashboard).
func Portfolio(d Deps, pool *pgxpool.Pool) *portfolio.Service {
	var sum ai.PortfolioSummarizer = ai.Mock{}
	if s, ok := d.AI.(ai.PortfolioSummarizer); ok {
		sum = s
	}
	return &portfolio.Service{Pool: pool, Scorer: &portfolio.Scorer{Pool: pool}, AI: sum}
}

// Tokens signs Centrifugo client tokens.
func Tokens(cfg config.Config) realtime.Tokens {
	return realtime.Tokens{Secret: []byte(cfg.CentrifugoTokenSecret), TTL: time.Hour}
}

// Flags is the live feature flag store: feature_flags rows over the config
// defaults (Config.Flags incl. FEATURE_FLAGS).
func Flags(cfg config.Config, pool *pgxpool.Pool) *flags.Store {
	return flags.New(pool, cfg.Flags)
}

// ListingFlags maps feature flags onto the catalog service.
func ListingFlags(f *flags.Store) listing.Flags {
	return listing.Flags{Source: f}
}

// Pwned returns the breached-password checker for PWNED_PASSWORDS
// (validated by config.Load).
func Pwned(cfg config.Config, log *slog.Logger) (pwned.Checker, error) {
	return pwned.New(cfg.PwnedPasswords, log)
}

// AccountConfig maps process config onto the account service settings.
func AccountConfig(cfg config.Config) account.Config {
	return account.Config{WebBaseURL: cfg.WebBaseURL, SessionTTLWeb: cfg.SessionTTLWeb, SessionTTLMobile: cfg.SessionTTLMobile,
		SessionMaxAge: cfg.SessionMaxAge,
		RedirectAllow: cfg.RedirectAllow, TermsVersion: cfg.TermsVersion, PrivacyVersion: cfg.PrivacyVersion,
		ErasureGrace: cfg.ErasureGrace, StaffRequireMFA: cfg.StaffRequireMFA, DisablePhoneVerification: !cfg.PhoneVerification}
}

// LogWarnings reports the non-fatal configuration problems found by config.Load.
func LogWarnings(cfg config.Config, log *slog.Logger) {
	for _, w := range cfg.Warnings {
		log.Warn("config: " + w)
	}
}

// MigrateOnStart applies the goose and River migrations when MIGRATE_ON_START
// is on (default: dev). It connects as the schema owner (MIGRATE_DATABASE_URL,
// falling back to DATABASE_URL): the runtime login role may not run DDL or
// write goose_db_version (ADR 0012 point 5).
func MigrateOnStart(ctx context.Context, cfg config.Config) error {
	if !config.MustBool("MIGRATE_ON_START", cfg.Env == "dev") {
		return nil
	}
	pool, err := db.Open(ctx, cfg.MigrateDatabaseURL)
	if err != nil {
		return fmt.Errorf("MIGRATE_DATABASE_URL: %w", err)
	}
	defer pool.Close()
	if err := db.Migrate(ctx, pool); err != nil {
		return err
	}
	return jobs.MigrateRiver(ctx, pool)
}

// BillingDeps are the billing service and the dev mock pages (nil unless the
// provider runs in mock mode).
type BillingDeps struct {
	Service     *billing.Service
	MockStripe  http.Handler // /mock/stripe/...
	MockRevolut http.Handler // /mock/revolut/...
}

// Billing builds the billing service. Stripe runs in mock mode without
// STRIPE_SECRET_KEY (never in prod, config validation refuses it); the mock
// delivers its signed webhook in-process instead of HTTP to itself. Revolut
// links are created in the landlord's own merchant account (ADR 0002).
func Billing(cfg config.Config, d Deps, pool *pgxpool.Pool, fs billing.Flags, jobs billing.Jobs, outbox notify.Outbox, log *slog.Logger) BillingDeps {
	if fs == nil {
		fs = billing.FlagFunc(cfg.Flag)
	}
	svc := &billing.Service{Pool: pool, Box: d.Box, Blob: d.Blob, Outbox: outbox, Mail: d.Renderer, Jobs: jobs,
		Invoices: billing.InvoiceRenderer{Bin: cfg.TypstBin}, WebBaseURL: cfg.WebBaseURL, RedirectAllow: cfg.RedirectAllow, Flags: fs, Log: log,
		Supplier: billing.Party{Name: cfg.PlatformLegalName, ICO: cfg.PlatformICO, DIC: cfg.PlatformDIC,
			Address: cfg.PlatformAddress, IBAN: cfg.PlatformIBAN}}
	out := BillingDeps{Service: svc}
	if cfg.StripeMode == "live" {
		svc.Stripe = billing.NewStripeHTTP(cfg.StripeSecretKey, cfg.StripeWebhookSecret)
	} else {
		mock := billing.NewMockStripe(cfg.APIPublicURL, cfg.StripeWebhookSecret)
		mock.Deliver = svc.HandleWebhook
		svc.Stripe, out.MockStripe = mock, mock.Handler()
	}
	if cfg.RevolutMode == "live" {
		svc.Revolut = billing.NewRevolutHTTP(cfg.RevolutAPIURL)
	} else {
		mock := billing.NewMockRevolut(cfg.APIPublicURL)
		svc.Revolut, out.MockRevolut = mock, mock.Handler()
	}
	return out
}
