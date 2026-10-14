package jobs

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/riverqueue/river"
)

// ProcessMediaArgs sanitizes, scans and analyzes an uploaded photo.
type ProcessMediaArgs struct {
	MediaID uuid.UUID `json:"media_id"`
}

// Kind implements river.JobArgs.
func (ProcessMediaArgs) Kind() string { return "process_media" }

// SuggestionArgs generates an AI suggestion.
type SuggestionArgs struct {
	SuggestionID uuid.UUID `json:"suggestion_id"`
}

// Kind implements river.JobArgs.
func (SuggestionArgs) Kind() string { return "ai_suggestion" }

// InsertOpts: AI calls can be slow; few retries.
func (SuggestionArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{MaxAttempts: 3} }

// CatalogRunner is implemented by listing.Service.
type CatalogRunner interface {
	ProcessMedia(ctx context.Context, mediaID uuid.UUID) error
	RunSuggestion(ctx context.Context, suggestionID uuid.UUID) error
}

// ProcessMediaWorker runs ProcessMediaArgs. Runner is set after the client exists.
type ProcessMediaWorker struct {
	river.WorkerDefaults[ProcessMediaArgs]
	Runner CatalogRunner
}

// Work implements river.Worker.
func (w *ProcessMediaWorker) Work(ctx context.Context, j *river.Job[ProcessMediaArgs]) error {
	return w.Runner.ProcessMedia(ctx, j.Args.MediaID)
}

// Timeout covers download, scan, vision and upload of one photo.
func (w *ProcessMediaWorker) Timeout(*river.Job[ProcessMediaArgs]) time.Duration {
	return 5 * time.Minute
}

// SuggestionWorker runs SuggestionArgs.
type SuggestionWorker struct {
	river.WorkerDefaults[SuggestionArgs]
	Runner CatalogRunner
}

// Work implements river.Worker.
func (w *SuggestionWorker) Work(ctx context.Context, j *river.Job[SuggestionArgs]) error {
	return w.Runner.RunSuggestion(ctx, j.Args.SuggestionID)
}

// Timeout leaves room for local LLM inference.
func (w *SuggestionWorker) Timeout(*river.Job[SuggestionArgs]) time.Duration { return 5 * time.Minute }

// CatalogJobs implements listing.Jobs with River.
type CatalogJobs struct{ Client *river.Client[pgx.Tx] }

// ProcessMedia implements listing.Jobs.
func (c CatalogJobs) ProcessMedia(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
	_, err := c.Client.InsertTx(ctx, tx, ProcessMediaArgs{MediaID: id}, nil)
	return err
}

// RunSuggestion implements listing.Jobs.
func (c CatalogJobs) RunSuggestion(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
	_, err := c.Client.InsertTx(ctx, tx, SuggestionArgs{SuggestionID: id}, nil)
	return err
}
