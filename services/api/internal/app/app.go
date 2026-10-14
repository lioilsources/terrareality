// Package app wires adapters from configuration. Both binaries (api, worker)
// use it so they agree on providers, storage and delivery.
package app

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"net/smtp"
	"os"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/identity"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
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
	if d.Box, err = secretbox.New(cfg.SecretKey); err != nil {
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
		if u := os.Getenv("SMTP_USERNAME"); u != "" {
			host := cfg.SMTPAddr
			for i := len(host) - 1; i >= 0; i-- {
				if host[i] == ':' {
					host = host[:i]
					break
				}
			}
			a = smtp.PlainAuth("", u, os.Getenv("SMTP_PASSWORD"), host)
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
	d.Scanner = media.NoScanner{}
	if cfg.ClamAVAddr != "" {
		d.Scanner = media.ClamAV{Addr: cfg.ClamAVAddr}
	} else if cfg.Env == "prod" {
		log.Warn("CLAMAV_ADDR not set, uploads are not scanned for malware")
	}
	d.Vision = vision.New(cfg.VisionURL)
	d.AI = ai.Mock{}
	if cfg.LLMBaseURL != "" {
		d.AI = ai.NewClient(cfg.LLMBaseURL, cfg.LLMAPIKey, cfg.LLMModel)
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

// Moderator returns the AI used for moderation verdicts.
func (d Deps) Moderator() ai.Moderator {
	if m, ok := d.AI.(ai.Moderator); ok {
		return m
	}
	return ai.Mock{}
}

// Tokens signs Centrifugo client tokens.
func Tokens(cfg config.Config) realtime.Tokens {
	return realtime.Tokens{Secret: []byte(cfg.CentrifugoTokenSecret), TTL: time.Hour}
}

// ListingFlags maps feature flags onto the catalog service.
func ListingFlags(cfg config.Config) listing.Flags {
	return listing.Flags{AIAttributes: cfg.Flag("ai.attributes"), AIText: cfg.Flag("ai.text"), Vision: cfg.Flag("ai.vision")}
}

// AccountConfig maps process config onto the account service settings.
func AccountConfig(cfg config.Config) account.Config {
	return account.Config{WebBaseURL: cfg.WebBaseURL, SessionTTLWeb: cfg.SessionTTLWeb, SessionTTLMobile: cfg.SessionTTLMobile,
		RedirectAllow: cfg.RedirectAllow, TermsVersion: cfg.TermsVersion, PrivacyVersion: cfg.PrivacyVersion,
		ErasureGrace: cfg.ErasureGrace, StaffRequireMFA: cfg.StaffRequireMFA}
}
