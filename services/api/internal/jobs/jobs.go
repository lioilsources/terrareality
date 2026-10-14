// Package jobs defines River background jobs and the shared River client setup.
// River stores its queue in PostgreSQL, so no Redis is required.
package jobs

import (
	"context"
	"encoding/json"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"github.com/riverqueue/river/rivermigrate"
	_ "time/tzdata" // Europe/Prague for the daily digest in minimal images

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
)

// HeartbeatKey is the app_meta key the worker refreshes; /healthz reads it.
const HeartbeatKey = "worker_heartbeat"

// HeartbeatArgs is a periodic job proving the worker is alive.
type HeartbeatArgs struct{}

// Kind implements river.JobArgs.
func (HeartbeatArgs) Kind() string { return "heartbeat" }

// HeartbeatWorker writes the current time into app_meta.
type HeartbeatWorker struct {
	river.WorkerDefaults[HeartbeatArgs]
	Q db.Querier
}

// Work implements river.Worker.
func (w *HeartbeatWorker) Work(ctx context.Context, _ *river.Job[HeartbeatArgs]) error {
	v, _ := json.Marshal(map[string]string{"at": time.Now().UTC().Format(time.RFC3339)})
	return w.Q.UpsertAppMeta(ctx, db.UpsertAppMetaParams{Key: HeartbeatKey, Value: v})
}

// MigrateRiver applies River's own schema migrations.
func MigrateRiver(ctx context.Context, pool *pgxpool.Pool) error {
	m, err := rivermigrate.New(riverpgxv5.New(pool), nil)
	if err != nil {
		return err
	}
	_, err = m.Migrate(ctx, rivermigrate.DirectionUp, nil)
	return err
}

// WorkerDeps are the collaborators of job workers.
type WorkerDeps struct {
	Sender      notify.Sender
	GDPR        *GDPRWorker
	Media       *ProcessMediaWorker
	Suggestions *SuggestionWorker
	Digest      *DigestWorker
	Messages    *MessageNotifyWorker
	MsgDigest   *MessagesDigestWorker
	Verdicts    *VerdictWorker
	Summaries   *ApplicationSummaryWorker
	Reminders   *ViewingReminderWorker
}

// NewWorkerClient builds a River client that processes jobs. Completed jobs
// are kept only briefly because message jobs carry one-time links.
func NewWorkerClient(pool *pgxpool.Pool, log *slog.Logger, deps WorkerDeps) (*river.Client[pgx.Tx], error) {
	workers := river.NewWorkers()
	river.AddWorker(workers, &HeartbeatWorker{Q: db.New(pool)})
	river.AddWorker(workers, &SendMessageWorker{Sender: deps.Sender})
	river.AddWorker(workers, deps.GDPR)
	river.AddWorker(workers, &CleanupWorker{Q: db.New(pool)})
	river.AddWorker(workers, deps.Media)
	river.AddWorker(workers, deps.Suggestions)
	river.AddWorker(workers, &RefreshAggregatesWorker{Q: db.New(pool)})
	river.AddWorker(workers, deps.Digest)
	river.AddWorker(workers, deps.Messages)
	river.AddWorker(workers, deps.MsgDigest)
	river.AddWorker(workers, deps.Verdicts)
	river.AddWorker(workers, deps.Summaries)
	river.AddWorker(workers, deps.Reminders)
	prague, err := time.LoadLocation("Europe/Prague")
	if err != nil {
		prague = time.UTC
	}
	return river.NewClient[pgx.Tx](riverpgxv5.New(pool), &river.Config{
		Logger:                      log,
		Queues:                      map[string]river.QueueConfig{river.QueueDefault: {MaxWorkers: 20}},
		Workers:                     workers,
		CompletedJobRetentionPeriod: time.Hour,
		PeriodicJobs: []*river.PeriodicJob{
			river.NewPeriodicJob(river.PeriodicInterval(30*time.Second),
				func() (river.JobArgs, *river.InsertOpts) { return HeartbeatArgs{}, nil },
				&river.PeriodicJobOpts{RunOnStart: true}),
			river.NewPeriodicJob(river.PeriodicInterval(time.Hour),
				func() (river.JobArgs, *river.InsertOpts) { return CleanupArgs{}, nil }, nil),
			river.NewPeriodicJob(river.PeriodicInterval(15*time.Minute),
				func() (river.JobArgs, *river.InsertOpts) { return RefreshAggregatesArgs{}, nil }, &river.PeriodicJobOpts{RunOnStart: true}),
			river.NewPeriodicJob(river.PeriodicInterval(time.Hour),
				func() (river.JobArgs, *river.InsertOpts) { return DigestArgs{}, nil }, nil),
			river.NewPeriodicJob(dailyAt{hour: 18, loc: prague},
				func() (river.JobArgs, *river.InsertOpts) { return MessagesDigestArgs{}, nil }, nil),
		},
	})
}

// NewInsertOnlyClient builds a River client for the API process, which only
// enqueues jobs and never works them.
func NewInsertOnlyClient(pool *pgxpool.Pool) (*river.Client[pgx.Tx], error) {
	return river.NewClient[pgx.Tx](riverpgxv5.New(pool), &river.Config{})
}
