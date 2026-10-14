package jobs

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/riverqueue/river"
)

// MessageNotifyArgs notifies the recipients of a message who have not read
// it after a short delay.
type MessageNotifyArgs struct {
	MessageID uuid.UUID `json:"message_id"`
}

// Kind implements river.JobArgs.
func (MessageNotifyArgs) Kind() string { return "message_notify" }

// InsertOpts: notifications are only useful for a few hours.
func (MessageNotifyArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{MaxAttempts: 5} }

// VerdictArgs asks the AI for a moderation verdict suggestion.
type VerdictArgs struct {
	CaseID uuid.UUID `json:"case_id"`
}

// Kind implements river.JobArgs.
func (VerdictArgs) Kind() string { return "moderation_verdict" }

// InsertOpts: same retry window as the other LLM jobs (Spark schedule).
func (VerdictArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{MaxAttempts: 10} }

// MessagesDigestArgs e-mails daily summaries of unread messages.
type MessagesDigestArgs struct{}

// Kind implements river.JobArgs.
func (MessagesDigestArgs) Kind() string { return "messages_digest" }

// MessagingRunner is implemented by messaging.Notifier and messaging.Verdicts.
type MessagingRunner interface {
	MessageCreated(ctx context.Context, messageID uuid.UUID) error
	Digest(ctx context.Context) (int, error)
}

// VerdictRunner is implemented by messaging.Verdicts.
type VerdictRunner interface {
	Suggest(ctx context.Context, caseID uuid.UUID, final bool) error
}

// MessageNotifyWorker runs MessageNotifyArgs.
type MessageNotifyWorker struct {
	river.WorkerDefaults[MessageNotifyArgs]
	Runner MessagingRunner
}

// Work implements river.Worker.
func (w *MessageNotifyWorker) Work(ctx context.Context, j *river.Job[MessageNotifyArgs]) error {
	return w.Runner.MessageCreated(ctx, j.Args.MessageID)
}

// MessagesDigestWorker runs MessagesDigestArgs.
type MessagesDigestWorker struct {
	river.WorkerDefaults[MessagesDigestArgs]
	Runner MessagingRunner
}

// Work implements river.Worker.
func (w *MessagesDigestWorker) Work(ctx context.Context, _ *river.Job[MessagesDigestArgs]) error {
	_, err := w.Runner.Digest(ctx)
	return err
}

// VerdictWorker runs VerdictArgs.
type VerdictWorker struct {
	river.WorkerDefaults[VerdictArgs]
	Runner VerdictRunner
}

// Work implements river.Worker.
func (w *VerdictWorker) Work(ctx context.Context, j *river.Job[VerdictArgs]) error {
	return w.Runner.Suggest(ctx, j.Args.CaseID, j.Attempt >= j.MaxAttempts)
}

// Timeout leaves room for local LLM inference.
func (w *VerdictWorker) Timeout(*river.Job[VerdictArgs]) time.Duration { return 5 * time.Minute }

// MessagingJobs implements messaging.Jobs with River.
type MessagingJobs struct{ Client *river.Client[pgx.Tx] }

// NotifyMessage implements messaging.Jobs.
func (m MessagingJobs) NotifyMessage(ctx context.Context, tx pgx.Tx, id uuid.UUID, delay time.Duration) error {
	_, err := m.Client.InsertTx(ctx, tx, MessageNotifyArgs{MessageID: id}, &river.InsertOpts{ScheduledAt: time.Now().Add(delay)})
	return err
}

// SuggestVerdict implements messaging.Jobs.
func (m MessagingJobs) SuggestVerdict(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
	_, err := m.Client.InsertTx(ctx, tx, VerdictArgs{CaseID: id}, nil)
	return err
}

// dailyAt is a periodic schedule that fires once a day at a local time.
type dailyAt struct {
	hour int
	loc  *time.Location
}

// Next implements river.PeriodicSchedule.
func (d dailyAt) Next(t time.Time) time.Time {
	l := t.In(d.loc)
	next := time.Date(l.Year(), l.Month(), l.Day(), d.hour, 0, 0, 0, d.loc)
	if !next.After(l) {
		next = next.AddDate(0, 0, 1)
	}
	return next
}
