package jobs

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/riverqueue/river"
	"go.temporal.io/sdk/client"

	"github.com/terrareality/terrareality/services/api/internal/workflows"
)

// StartLeaseArgs starts the Temporal lifecycle of a signed lease. Enqueued
// in the signing transaction, so the workflow starts if and only if the
// lease was signed.
type StartLeaseArgs struct {
	LeaseID uuid.UUID `json:"lease_id"`
}

// Kind implements river.JobArgs.
func (StartLeaseArgs) Kind() string { return "start_lease_workflow" }

// StartLeaseWorker runs StartLeaseArgs.
type StartLeaseWorker struct {
	river.WorkerDefaults[StartLeaseArgs]
	Temporal client.Client // set once connected
	Enabled  bool          // Temporal is configured (TEMPORAL_ADDRESS)
	Log      *slog.Logger
}

// Work implements river.Worker. Starting is idempotent: the workflow id is
// derived from the lease id.
func (w *StartLeaseWorker) Work(ctx context.Context, j *river.Job[StartLeaseArgs]) error {
	if w.Temporal == nil {
		if w.Enabled {
			return errors.New("temporal client not connected yet")
		}
		w.Log.Warn("Temporal disabled, lease lifecycle not started", "lease", j.Args.LeaseID)
		return nil
	}
	_, err := w.Temporal.ExecuteWorkflow(ctx, client.StartWorkflowOptions{ID: workflows.LeaseWorkflowID(j.Args.LeaseID),
		TaskQueue: workflows.TaskQueue}, workflows.LeaseLifecycle, j.Args.LeaseID, time.Time{})
	return err
}

// BankSyncArgs fetches and matches bank transactions of all linked accounts.
type BankSyncArgs struct{}

// Kind implements river.JobArgs.
func (BankSyncArgs) Kind() string { return "bank_sync" }

// BankSyncer is implemented by leasing.Service.
type BankSyncer interface {
	SyncAll(ctx context.Context) error
}

// BankSyncWorker runs BankSyncArgs.
type BankSyncWorker struct {
	river.WorkerDefaults[BankSyncArgs]
	Syncer BankSyncer
}

// Work implements river.Worker.
func (w *BankSyncWorker) Work(ctx context.Context, _ *river.Job[BankSyncArgs]) error {
	return w.Syncer.SyncAll(ctx)
}

// Timeout covers several accounts.
func (w *BankSyncWorker) Timeout(*river.Job[BankSyncArgs]) time.Duration { return 10 * time.Minute }

// LeaseJobs implements leasing.Jobs with River.
type LeaseJobs struct{ Client *river.Client[pgx.Tx] }

// StartLifecycle implements leasing.Jobs.
func (l LeaseJobs) StartLifecycle(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
	_, err := l.Client.InsertTx(ctx, tx, StartLeaseArgs{LeaseID: id}, nil)
	return err
}
