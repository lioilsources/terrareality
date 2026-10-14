package jobs

import (
	"context"

	"github.com/riverqueue/river"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

// RefreshAggregatesArgs refreshes listing_aggregates.
type RefreshAggregatesArgs struct{}

// Kind implements river.JobArgs.
func (RefreshAggregatesArgs) Kind() string { return "refresh_aggregates" }

// RefreshAggregatesWorker refreshes the materialized view.
type RefreshAggregatesWorker struct {
	river.WorkerDefaults[RefreshAggregatesArgs]
	Q db.Querier
}

// Work implements river.Worker.
func (w *RefreshAggregatesWorker) Work(ctx context.Context, _ *river.Job[RefreshAggregatesArgs]) error {
	return w.Q.RefreshListingAggregates(ctx)
}

// DigestArgs sends saved-search digests.
type DigestArgs struct{}

// Kind implements river.JobArgs.
func (DigestArgs) Kind() string { return "saved_search_digest" }

// DigestRunner is implemented by search.Digest.
type DigestRunner interface {
	Run(ctx context.Context) (int, error)
}

// DigestWorker runs DigestArgs.
type DigestWorker struct {
	river.WorkerDefaults[DigestArgs]
	Runner DigestRunner
}

// Work implements river.Worker.
func (w *DigestWorker) Work(ctx context.Context, _ *river.Job[DigestArgs]) error {
	_, err := w.Runner.Run(ctx)
	return err
}
