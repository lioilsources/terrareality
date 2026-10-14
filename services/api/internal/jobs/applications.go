package jobs

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/riverqueue/river"
)

// ApplicationSummaryArgs asks the AI to summarize an application.
type ApplicationSummaryArgs struct {
	ApplicationID uuid.UUID `json:"application_id"`
}

// Kind implements river.JobArgs.
func (ApplicationSummaryArgs) Kind() string { return "application_summary" }

// InsertOpts: same retry window as the other LLM jobs (Spark schedule).
func (ApplicationSummaryArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{MaxAttempts: 10} }

// ViewingReminderArgs reminds applicants of a booked viewing.
type ViewingReminderArgs struct {
	BookingID uuid.UUID `json:"booking_id"`
}

// Kind implements river.JobArgs.
func (ViewingReminderArgs) Kind() string { return "viewing_reminder" }

// SummaryRunner is implemented by applications.Summaries.
type SummaryRunner interface {
	Summarize(ctx context.Context, id uuid.UUID, final bool) error
}

// ReminderRunner is implemented by applications.Reminders.
type ReminderRunner interface {
	Remind(ctx context.Context, bookingID uuid.UUID) error
}

// ApplicationSummaryWorker runs ApplicationSummaryArgs.
type ApplicationSummaryWorker struct {
	river.WorkerDefaults[ApplicationSummaryArgs]
	Runner SummaryRunner
}

// Work implements river.Worker.
func (w *ApplicationSummaryWorker) Work(ctx context.Context, j *river.Job[ApplicationSummaryArgs]) error {
	return w.Runner.Summarize(ctx, j.Args.ApplicationID, j.Attempt >= j.MaxAttempts)
}

// Timeout leaves room for local LLM inference.
func (w *ApplicationSummaryWorker) Timeout(*river.Job[ApplicationSummaryArgs]) time.Duration {
	return 5 * time.Minute
}

// ViewingReminderWorker runs ViewingReminderArgs.
type ViewingReminderWorker struct {
	river.WorkerDefaults[ViewingReminderArgs]
	Runner ReminderRunner
}

// Work implements river.Worker.
func (w *ViewingReminderWorker) Work(ctx context.Context, j *river.Job[ViewingReminderArgs]) error {
	return w.Runner.Remind(ctx, j.Args.BookingID)
}

// ApplicationJobs implements applications.Jobs with River.
type ApplicationJobs struct{ Client *river.Client[pgx.Tx] }

// SummarizeApplication implements applications.Jobs.
func (a ApplicationJobs) SummarizeApplication(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
	_, err := a.Client.InsertTx(ctx, tx, ApplicationSummaryArgs{ApplicationID: id}, nil)
	return err
}

// ViewingReminder implements applications.Jobs.
func (a ApplicationJobs) ViewingReminder(ctx context.Context, tx pgx.Tx, id uuid.UUID, at time.Time) error {
	_, err := a.Client.InsertTx(ctx, tx, ViewingReminderArgs{BookingID: id}, &river.InsertOpts{ScheduledAt: at})
	return err
}
