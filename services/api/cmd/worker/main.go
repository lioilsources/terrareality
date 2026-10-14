// Command worker runs River background jobs and Temporal workflow workers.
// It shares all domain code with the api binary (same Go module).
package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/app"
	"github.com/terrareality/terrareality/services/api/internal/applications"
	"github.com/terrareality/terrareality/services/api/internal/jobs"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/messaging"
	"github.com/terrareality/terrareality/services/api/internal/platform/buildinfo"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	"github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/logx"
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
	log.Info("starting worker", "version", buildinfo.Version, "env", cfg.Env)

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
	if err != nil {
		return err
	}
	gdpr := &jobs.GDPRWorker{}
	mediaW, suggestW, digestW := &jobs.ProcessMediaWorker{}, &jobs.SuggestionWorker{}, &jobs.DigestWorker{}
	notifyW, msgDigestW, verdictW := &jobs.MessageNotifyWorker{}, &jobs.MessagesDigestWorker{}, &jobs.VerdictWorker{}
	summaryW, reminderW := &jobs.ApplicationSummaryWorker{}, &jobs.ViewingReminderWorker{}
	rc, err := jobs.NewWorkerClient(pool, log, jobs.WorkerDeps{Sender: deps.Sender, GDPR: gdpr, Media: mediaW,
		Suggestions: suggestW, Digest: digestW, Messages: notifyW, MsgDigest: msgDigestW, Verdicts: verdictW,
		Summaries: summaryW, Reminders: reminderW})
	if err != nil {
		return err
	}
	gdpr.Runner = &account.Service{Pool: pool, Box: deps.Box, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer,
		IDP: deps.IDP, Blob: deps.Blob, Scheduler: jobs.Scheduler{Client: rc}, Cfg: app.AccountConfig(cfg)}
	listings := &listing.Service{Pool: pool, Blob: deps.Blob, Img: deps.Img, Scanner: deps.Scanner, Vision: deps.Vision, AI: deps.AI,
		Jobs: jobs.CatalogJobs{Client: rc}, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer, Flags: app.ListingFlags(cfg),
		WebBaseURL: cfg.WebBaseURL, Search: search.Indexer{}}
	mediaW.Runner, suggestW.Runner = listings, listings
	digestW.Runner = &search.Digest{Engine: &search.Engine{Pool: pool}, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer,
		WebBaseURL: cfg.WebBaseURL}
	notifier := &messaging.Notifier{Pool: pool, RT: deps.RT, Pusher: deps.Pusher, Outbox: jobs.Outbox{Client: rc},
		Render: deps.Renderer, WebBaseURL: cfg.WebBaseURL, Log: log}
	notifyW.Runner, msgDigestW.Runner = notifier, notifier
	verdictW.Runner = &messaging.Verdicts{Pool: pool, AI: deps.Moderator(), Enabled: cfg.Flag("ai.moderation")}
	summaryW.Runner = &applications.Summaries{Pool: pool, AI: deps.Summarizer(), Enabled: cfg.Flag("ai.applications")}
	reminderW.Runner = &applications.Reminders{Pool: pool, Outbox: jobs.Outbox{Client: rc}, Render: deps.Renderer,
		Pusher: deps.Pusher, WebBaseURL: cfg.WebBaseURL}
	if err := rc.Start(ctx); err != nil {
		return err
	}
	defer rc.Stop(context.Background())

	if cfg.TemporalAddress != "" {
		tc, err := client.Dial(client.Options{HostPort: cfg.TemporalAddress, Namespace: cfg.TemporalNS, Logger: log})
		if err != nil {
			return err
		}
		defer tc.Close()
		w := worker.New(tc, workflows.TaskQueue, worker.Options{})
		w.RegisterWorkflow(workflows.Ping)
		w.RegisterActivity(workflows.PingActivity)
		if err := w.Start(); err != nil {
			return err
		}
		defer w.Stop()
		log.Info("temporal worker started", "address", cfg.TemporalAddress, "queue", workflows.TaskQueue)
	} else {
		log.Warn("TEMPORAL_ADDRESS not set, Temporal worker disabled")
	}

	<-ctx.Done()
	log.Info("shutting down worker")
	return nil
}
