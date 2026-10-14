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

	"github.com/terrareality/terrareality/services/api/internal/api"
	dbq "github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/health"
	"github.com/terrareality/terrareality/services/api/internal/jobs"
	"github.com/terrareality/terrareality/services/api/internal/platform/buildinfo"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	"github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/httpx"
	"github.com/terrareality/terrareality/services/api/internal/platform/logx"
	"github.com/terrareality/terrareality/services/api/internal/platform/telemetry"
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
	}

	httpClient := &http.Client{Timeout: 3 * time.Second}
	checker := health.New(3 * time.Second)
	checker.Add("database", func(ctx context.Context) error { return pool.Ping(ctx) })
	checker.Add("worker", health.WorkerHeartbeat(dbq.New(pool), jobs.HeartbeatKey, 90*time.Second))
	checker.Add("vision", health.HTTPCheck(httpClient, joinURL(cfg.VisionURL, "/healthz")))
	checker.Add("centrifugo", health.HTTPCheck(httpClient, centrifugoHealth(cfg.CentrifugoURL)))

	trusted, err := httpx.ParsePrefixes(cfg.TrustedProxies)
	if err != nil {
		return fmt.Errorf("TRUSTED_PROXIES: %w", err)
	}
	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           api.NewRouter(api.NewServer(pool, checker), api.RouterConfig{Log: log, CORSOrigins: cfg.CORSOrigins, TrustedProxies: trusted}),
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
