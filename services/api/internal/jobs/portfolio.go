package jobs

import (
	"context"
	"time"

	"github.com/riverqueue/river"
)

// LeaseRiskArgs rescores leases with new events (payments, escalations,
// notices), missing or day-old scores. It runs every minute, so an
// escalation shows in the portfolio within minutes (M6b acceptance: 1 h).
type LeaseRiskArgs struct{}

// Kind implements river.JobArgs.
func (LeaseRiskArgs) Kind() string { return "lease_risk" }

// RiskScorer is implemented by portfolio.Scorer.
type RiskScorer interface {
	RecomputeStale(ctx context.Context) (int, error)
}

// LeaseRiskWorker runs LeaseRiskArgs.
type LeaseRiskWorker struct {
	river.WorkerDefaults[LeaseRiskArgs]
	Scorer RiskScorer
}

// Work implements river.Worker.
func (w *LeaseRiskWorker) Work(ctx context.Context, _ *river.Job[LeaseRiskArgs]) error {
	_, err := w.Scorer.RecomputeStale(ctx)
	return err
}

// Timeout covers a full daily rescore.
func (w *LeaseRiskWorker) Timeout(*river.Job[LeaseRiskArgs]) time.Duration { return 10 * time.Minute }
