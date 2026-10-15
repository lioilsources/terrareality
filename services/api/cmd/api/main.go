// Command api serves the TerraReality HTTP API.
package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/api"
	"github.com/terrareality/terrareality/services/api/internal/app"
	"github.com/terrareality/terrareality/services/api/internal/applications"
	"github.com/terrareality/terrareality/services/api/internal/catalog"
	dbq "github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/health"
	"github.com/terrareality/terrareality/services/api/internal/jobs"
	"github.com/terrareality/terrareality/services/api/internal/leasing"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/messaging"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/buildinfo"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	"github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/httpx"
	"github.com/terrareality/terrareality/services/api/internal/platform/logx"
	"github.com/terrareality/terrareality/services/api/internal/platform/telemetry"
	"github.com/terrareality/terrareality/services/api/internal/ruian"
	"github.com/terrareality/terrareality/services/api/internal/search"
)

func main() {
	if err := run(); err != nil {
		os.Stderr.WriteString("api: " + err.Error() + "\n")
		os.Exit(1)
	}
}

func run() error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load()
	if err != nil {
		return err
	}
	log := logx.New(cfg.LogLevel, cfg.LogFormat)
	log.Info("starting api", "version", buildinfo.Version, "env", cfg.Env, "addr", cfg.HTTPAddr)

	shutdownTracing, err := telemetry.Setup(ctx, "terra-api", cfg.OTLPEndpoint, cfg.Env)
	if err != nil {
		return err
	}
	defer shutdownTracing(context.Background())

	pool, err := db.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()
	if config.MustBool("MIGRATE_ON_START", cfg.Env == "dev") {
		if err := db.Migrate(ctx, pool); err != nil {
			return err
		}
		if err := jobs.MigrateRiver(ctx, pool); err != nil {
			return err
		}
	}
	deps, err := app.Build(cfg, log)
	fl := app.Flags(cfg, pool)
	if err != nil {
		return err
	}
	rc, err := jobs.NewInsertOnlyClient(pool)
	if err != nil {
		return err
	}
	accounts := &account.Service{Pool: pool, Box: deps.Box, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer,
		IDP: deps.IDP, Blob: deps.Blob, Scheduler: jobs.Scheduler{Client: rc}, Cfg: app.AccountConfig(cfg)}
	orgs := &org.Service{Pool: pool, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer, WebBaseURL: cfg.WebBaseURL}
	listings := &listing.Service{Pool: pool, Blob: deps.Blob, Img: deps.Img, Scanner: deps.Scanner, Vision: deps.Vision, AI: deps.AI,
		Jobs: jobs.CatalogJobs{Client: rc}, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer, Flags: app.ListingFlags(fl),
		WebBaseURL: cfg.WebBaseURL, Search: search.Indexer{}}
	messages := &messaging.Service{Pool: pool, RT: deps.RT, Tokens: app.Tokens(cfg), WSURL: cfg.CentrifugoWSURL,
		Jobs: jobs.MessagingJobs{Client: rc}, Blob: deps.Blob, Scanner: deps.Scanner, NotifyDelay: cfg.MessageNotifyDelay,
		Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer, WebBaseURL: cfg.WebBaseURL, Log: log}
	apps := &applications.Service{Pool: pool, RT: deps.RT, Jobs: jobs.ApplicationJobs{Client: rc}, Outbox: jobs.Outbox{Client: rc},
		Render: deps.Renderer, Blob: deps.Blob, Scanner: deps.Scanner, ISIR: app.ISIR(cfg), WebBaseURL: cfg.WebBaseURL, Log: log}
	leases, mockBank := app.Leasing(cfg, deps, pool, jobs.LeaseJobs{Client: rc}, jobs.Outbox{Client: rc}, log)
	bill := app.Billing(cfg, deps, pool, fl, jobs.BillingJobs{Client: rc}, jobs.Outbox{Client: rc}, log)
	chat := &search.Chat{Pool: pool, Model: "rules"}
	if cfg.LLMBaseURL != "" {
		chat.LLM, chat.Model = app.LLM(cfg, log), cfg.LLMModel
	}
	app.GateCloudFallback(fl, deps.AI, chat.LLM)
	if err := catalog.Sync(ctx, dbq.New(pool)); err != nil {
		return fmt.Errorf("sync attribute catalog: %w", err)
	}
	if cfg.SeedRuian {
		if n, err := ruian.SeedSample(ctx, pool); err != nil {
			return fmt.Errorf("seed RÚIAN sample: %w", err)
		} else if n > 0 {
			log.Info("loaded RÚIAN sample addresses", "count", n)
		}
		if n, err := search.SeedFromRuian(ctx, pool); err != nil {
			return fmt.Errorf("seed admin units: %w", err)
		} else if n > 0 {
			log.Info("derived dev administrative units from the RÚIAN sample", "count", n)
		}
	}

	httpClient := &http.Client{Timeout: 3 * time.Second}
	checker := health.New(3 * time.Second)
	checker.Add("database", func(ctx context.Context) error { return pool.Ping(ctx) })
	checker.Add("worker", health.WorkerHeartbeat(dbq.New(pool), jobs.HeartbeatKey, 90*time.Second))
	checker.Add("vision", health.HTTPCheck(httpClient, joinURL(cfg.VisionURL, "/healthz")))
	checker.Add("centrifugo", health.HTTPCheck(httpClient, centrifugoHealth(cfg.CentrifugoURL)))

	// Prometheus /metrics on an internal listener, only when METRICS_ADDR is set.
	var metrics *prometheus.Registry
	if addr := telemetry.MetricsAddr(); addr != "" {
		metrics = telemetry.NewRegistry("terra-api")
		metrics.MustRegister(telemetry.NewPoolCollector(pool))
		stopMetrics, err := telemetry.ServeMetrics(addr, metrics, log)
		if err != nil {
			return fmt.Errorf("METRICS_ADDR: %w", err)
		}
		defer stopMetrics(context.Background())
	}

	trusted, err := httpx.ParsePrefixes(cfg.TrustedProxies)
	if err != nil {
		return fmt.Errorf("TRUSTED_PROXIES: %w", err)
	}
	srv := &http.Server{
		Addr: cfg.HTTPAddr,
		Handler: httpx.Metrics(metrics)(api.NewRouter(
			api.NewServer(pool, checker, api.Services{Account: accounts, Orgs: orgs, IDP: deps.IDP, Listings: listings, Engine: &search.Engine{Pool: pool}, Chat: chat, Messages: messages, Applications: apps, Leases: leases, Portfolio: app.Portfolio(deps, pool), Billing: bill.Service, VAPIDPublicKey: deps.WebPush.VAPIDPublic(), Flags: fl, StaffRequireMFA: cfg.StaffRequireMFA, RateBurst: cfg.RateBurst}),
			api.RouterConfig{Log: log, CORSOrigins: cfg.CORSOrigins, TrustedProxies: trusted,
				Sessions: dbq.New(pool), SessionTTL: accounts.TTL, MockIdP: deps.MockIdP, DevBank: devBank(cfg, leases, mockBank),
				DevLeases: devLeases(cfg, leases), MockStripe: bill.MockStripe, MockRevolut: bill.MockRevolut,
				RateLimits: api.RateLimits{Search: cfg.RateSearch, Chat: cfg.RateChat, Webhook: cfg.RateWebhook,
					Apply: cfg.RateApply, Message: cfg.RateMessage, Report: cfg.RateReport}})),
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}
	errCh := make(chan error, 1)
	go func() { errCh <- srv.ListenAndServe() }()

	select {
	case err := <-errCh:
		if !errors.Is(err, http.ErrServerClosed) {
			return err
		}
	case <-ctx.Done():
		log.Info("shutting down")
	}
	shCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancel()
	return srv.Shutdown(shCtx)
}

func joinURL(base, path string) string {
	if base == "" {
		return ""
	}
	return base + path
}

// centrifugoHealth derives the /health URL from the API URL (http://host:8000/api).
func centrifugoHealth(apiURL string) string {
	if apiURL == "" {
		return ""
	}
	const suffix = "/api"
	if len(apiURL) > len(suffix) && apiURL[len(apiURL)-len(suffix):] == suffix {
		return apiURL[:len(apiURL)-len(suffix)] + "/health"
	}
	return apiURL + "/health"
}

// devBank exposes the mock bank's transaction injection in dev/test.
func devBank(cfg config.Config, leases *leasing.Service, mock *leasing.MockBank) http.Handler {
	if mock == nil || (cfg.Env != "dev" && cfg.Env != "test") {
		return nil
	}
	return leases.DevBankHandler(mock)
}

// devLeases exposes lease lifecycle shortcuts (simulated escalation) in dev/test.
func devLeases(cfg config.Config, leases *leasing.Service) http.Handler {
	if cfg.Env != "dev" && cfg.Env != "test" {
		return nil
	}
	return leases.DevEscalateHandler()
}
