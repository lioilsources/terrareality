// Command worker runs River background jobs and Temporal workflow workers.
// It shares all domain code with the api binary (same Go module).
package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/app"
	"github.com/terrareality/terrareality/services/api/internal/applications"
	"github.com/terrareality/terrareality/services/api/internal/jobs"
	"github.com/terrareality/terrareality/services/api/internal/leasing"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/messaging"
	"github.com/terrareality/terrareality/services/api/internal/platform/buildinfo"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	"github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/logx"
	"github.com/terrareality/terrareality/services/api/internal/platform/telemetry"
	"github.com/terrareality/terrareality/services/api/internal/portfolio"
	"github.com/terrareality/terrareality/services/api/internal/search"
	"github.com/terrareality/terrareality/services/api/internal/workflows"
)

func main() {
	if err := run(); err != nil {
		os.Stderr.WriteString("worker: " + err.Error() + "\n")
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
	app.LogWarnings(cfg, log)
	log.Info("starting worker", "version", buildinfo.Version, "env", cfg.Env)

	shutdownTracing, err := telemetry.Setup(ctx, "terra-worker", cfg.OTLPEndpoint, cfg.Env)
	if err != nil {
		return err
	}
	defer shutdownTracing(context.Background())

	if err := app.MigrateOnStart(ctx, cfg); err != nil {
		return err
	}
	pool, err := db.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()
	deps, err := app.Build(cfg, log)
	if err != nil {
		return err
	}
	fl := app.Flags(cfg, pool)
	app.GateCloudFallback(fl, deps.AI)
	gdpr := &jobs.GDPRWorker{}
	mediaW, suggestW, digestW := &jobs.ProcessMediaWorker{}, &jobs.SuggestionWorker{}, &jobs.DigestWorker{}
	notifyW, msgDigestW, verdictW := &jobs.MessageNotifyWorker{}, &jobs.MessagesDigestWorker{}, &jobs.VerdictWorker{}
	summaryW, reminderW := &jobs.ApplicationSummaryWorker{}, &jobs.ViewingReminderWorker{}
	startLeaseW, bankSyncW := &jobs.StartLeaseWorker{Log: log, Enabled: cfg.TemporalAddress != ""}, &jobs.BankSyncWorker{}
	riskW := &jobs.LeaseRiskWorker{Scorer: &portfolio.Scorer{Pool: pool}}
	promoW, invoiceW := &jobs.PromoRecomputeWorker{}, &jobs.InvoiceDeliveryWorker{}
	rc, err := jobs.NewWorkerClient(pool, log, jobs.WorkerDeps{Sender: deps.Sender, Pusher: deps.Pusher, GDPR: gdpr, Media: mediaW,
		Suggestions: suggestW, Digest: digestW, Messages: notifyW, MsgDigest: msgDigestW, Verdicts: verdictW,
		Summaries: summaryW, Reminders: reminderW, StartLease: startLeaseW, BankSync: bankSyncW, LeaseRisk: riskW,
		Promos: promoW, Invoices: invoiceW})
	if err != nil {
		return err
	}
	gdpr.Runner = &account.Service{Pool: pool, Box: deps.Box, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer,
		IDP: deps.IDP, Blob: deps.Blob, Scheduler: jobs.Scheduler{Client: rc}, Cfg: app.AccountConfig(cfg)}
	listings := &listing.Service{Pool: pool, Blob: deps.Blob, Img: deps.Img, Scanner: deps.Scanner, Vision: deps.Vision, AI: deps.AI,
		Jobs: jobs.CatalogJobs{Client: rc}, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer, Flags: app.ListingFlags(fl),
		WebBaseURL: cfg.WebBaseURL, Search: search.Indexer{}}
	mediaW.Runner, suggestW.Runner = listings, listings
	digestW.Runner = &search.Digest{Engine: &search.Engine{Pool: pool}, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer,
		WebBaseURL: cfg.WebBaseURL}
	notifier := &messaging.Notifier{Pool: pool, RT: deps.RT, Pusher: deps.Pusher, Outbox: jobs.Outbox{Client: rc},
		Render: deps.Renderer, WebBaseURL: cfg.WebBaseURL, Log: log}
	notifyW.Runner, msgDigestW.Runner = notifier, notifier
	verdictW.Runner = &messaging.Verdicts{Pool: pool, AI: deps.Moderator(), Flags: fl}
	summaryW.Runner = &applications.Summaries{Pool: pool, AI: deps.Summarizer(), Flags: fl}
	reminderW.Runner = &applications.Reminders{Pool: pool, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer,
		Pusher: deps.Pusher, WebBaseURL: cfg.WebBaseURL}
	leases, _ := app.Leasing(cfg, deps, pool, jobs.LeaseJobs{Client: rc}, jobs.Outbox{Client: rc}, log)
	bankSyncW.Syncer = leases
	bill := app.Billing(cfg, deps, pool, fl, jobs.BillingJobs{Client: rc}, jobs.Outbox{Client: rc}, log)
	promoW.Runner, invoiceW.Runner = bill.Service, bill.Service
	// Prometheus /metrics on an internal listener, only when METRICS_ADDR is set.
	if addr := telemetry.MetricsAddr(); addr != "" {
		metrics := telemetry.NewRegistry("terra-worker")
		metrics.MustRegister(telemetry.NewPoolCollector(pool), telemetry.NewRiverQueueCollector(pool))
		events, unsubscribe := rc.Subscribe(telemetry.RiverEvents...)
		defer unsubscribe()
		go telemetry.ObserveRiver(ctx, metrics, events)
		stopMetrics, err := telemetry.ServeMetrics(addr, metrics, log)
		if err != nil {
			return err
		}
		defer stopMetrics(context.Background())
	}
	if err := rc.Start(ctx); err != nil {
		return err
	}
	defer rc.Stop(context.Background())

	if cfg.TemporalAddress != "" {
		// Connect in the background and keep retrying: River jobs do not need
		// Temporal, and exiting here turned a stuck Temporal into a restart loop
		// that hammered the database. Lease jobs retry until the client is set.
		temporalDone := make(chan struct{})
		go func() {
			defer close(temporalDone)
			stop := runTemporalWorker(ctx, cfg.TemporalAddress, cfg.TemporalNS, log, leases, startLeaseW)
			<-ctx.Done()
			stop()
		}()
		defer func() { <-temporalDone }()
	} else {
		log.Warn("TEMPORAL_ADDRESS not set, Temporal worker disabled")
	}

	<-ctx.Done()
	log.Info("shutting down worker")
	return nil
}

// runTemporalWorker dials Temporal and starts the workflow worker, retrying
// with backoff (2 s doubling up to a minute) until it succeeds or ctx ends.
// The returned func stops the worker and closes the client.
func runTemporalWorker(ctx context.Context, addr, ns string, log *slog.Logger, leases *leasing.Service,
	startLeaseW *jobs.StartLeaseWorker) func() {
	for backoff := 2 * time.Second; ; backoff = min(backoff*2, time.Minute) {
		tc, err := client.Dial(client.Options{HostPort: addr, Namespace: ns, Logger: log})
		if err == nil {
			w := worker.New(tc, workflows.TaskQueue, worker.Options{})
			w.RegisterWorkflow(workflows.Ping)
			w.RegisterActivity(workflows.PingActivity)
			w.RegisterWorkflow(workflows.LeaseLifecycle)
			w.RegisterActivity(&leasing.Activities{S: leases})
			if err = w.Start(); err == nil {
				startLeaseW.SetTemporal(tc)
				log.Info("temporal worker started", "address", addr, "queue", workflows.TaskQueue)
				return func() { w.Stop(); tc.Close() }
			}
			tc.Close()
		}
		log.Warn("waiting for Temporal", "err", err, "retry_in", backoff)
		select {
		case <-ctx.Done():
			return func() {}
		case <-time.After(backoff):
		}
	}
}
