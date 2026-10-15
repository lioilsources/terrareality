package jobs

import (
	"context"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/riverqueue/river"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
)

// SendMessageArgs delivers one rendered e-mail or SMS.
type SendMessageArgs struct {
	Message notify.Message `json:"message"`
}

// Kind implements river.JobArgs.
func (SendMessageArgs) Kind() string { return "send_message" }

// InsertOpts retries delivery for about a day.
func (SendMessageArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{MaxAttempts: 12} }

// SendMessageWorker hands messages to the configured sender.
type SendMessageWorker struct {
	river.WorkerDefaults[SendMessageArgs]
	Sender notify.Sender
}

// Work implements river.Worker.
func (w *SendMessageWorker) Work(ctx context.Context, j *river.Job[SendMessageArgs]) error {
	return w.Sender.Send(ctx, j.Args.Message)
}

// Timeout bounds one SMTP conversation.
func (w *SendMessageWorker) Timeout(*river.Job[SendMessageArgs]) time.Duration {
	return 30 * time.Second
}

// Outbox implements notify.Outbox with a River job in the caller's transaction.
type Outbox struct{ Client *river.Client[pgx.Tx] }

// Enqueue implements notify.Outbox.
func (o Outbox) Enqueue(ctx context.Context, tx pgx.Tx, m notify.Message) error {
	_, err := o.Client.InsertTx(ctx, tx, SendMessageArgs{Message: m}, nil)
	return err
}

// EnqueuePush implements notify.PushQueue: the push becomes a job in the
// caller's transaction.
func (o Outbox) EnqueuePush(ctx context.Context, tx pgx.Tx, userID uuid.UUID, p notify.Push) error {
	_, err := o.Client.InsertTx(ctx, tx, SendPushArgs{UserID: userID, Push: p}, nil)
	return err
}

// SendPushArgs delivers one push notification to every device of a user.
type SendPushArgs struct {
	UserID uuid.UUID   `json:"user_id"`
	Push   notify.Push `json:"push"`
}

// Kind implements river.JobArgs.
func (SendPushArgs) Kind() string { return "send_push" }

// InsertOpts retries briefly: a late push is worth less than none.
func (SendPushArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{MaxAttempts: 5} }

// SendPushWorker delivers queued pushes (leases, payments, applications).
type SendPushWorker struct {
	river.WorkerDefaults[SendPushArgs]
	Q      notify.PushDevices
	Pusher notify.Pusher // nil: pushes are dropped
	Log    *slog.Logger
}

// Work implements river.Worker. Only the device lookup is retried; failures
// per device are logged (a retry would repeat delivered pushes).
func (w *SendPushWorker) Work(ctx context.Context, j *river.Job[SendPushArgs]) error {
	_, err := notify.DeliverPush(ctx, w.Q, w.Pusher, w.Log, j.Args.UserID, j.Args.Push)
	return err
}

// Timeout bounds the FCM / web push calls of one user.
func (w *SendPushWorker) Timeout(*river.Job[SendPushArgs]) time.Duration {
	return 30 * time.Second
}

// GDPRArgs runs a data export or an erasure.
type GDPRArgs struct {
	RequestID uuid.UUID `json:"request_id"`
	Erasure   bool      `json:"erasure"`
}

// Kind implements river.JobArgs.
func (GDPRArgs) Kind() string { return "gdpr_request" }

// GDPRRunner is implemented by account.Service.
type GDPRRunner interface {
	RunExport(ctx context.Context, requestID uuid.UUID) error
	RunErasure(ctx context.Context, requestID uuid.UUID) error
}

// GDPRWorker executes GDPR requests. Runner is set after the River client
// exists because the account service enqueues through that client.
type GDPRWorker struct {
	river.WorkerDefaults[GDPRArgs]
	Runner GDPRRunner
}

// Work implements river.Worker.
func (w *GDPRWorker) Work(ctx context.Context, j *river.Job[GDPRArgs]) error {
	if j.Args.Erasure {
		return w.Runner.RunErasure(ctx, j.Args.RequestID)
	}
	return w.Runner.RunExport(ctx, j.Args.RequestID)
}

// Scheduler implements account.Scheduler.
type Scheduler struct{ Client *river.Client[pgx.Tx] }

// ScheduleExport implements account.Scheduler.
func (s Scheduler) ScheduleExport(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
	_, err := s.Client.InsertTx(ctx, tx, GDPRArgs{RequestID: id}, nil)
	return err
}

// ScheduleErasure implements account.Scheduler.
func (s Scheduler) ScheduleErasure(ctx context.Context, tx pgx.Tx, id uuid.UUID, at time.Time) error {
	_, err := s.Client.InsertTx(ctx, tx, GDPRArgs{RequestID: id, Erasure: true}, &river.InsertOpts{ScheduledAt: at})
	return err
}

// CleanupArgs removes expired one-time tokens.
type CleanupArgs struct{}

// Kind implements river.JobArgs.
func (CleanupArgs) Kind() string { return "cleanup_tokens" }

// CleanupWorker deletes expired auth tokens and long-dead sessions.
type CleanupWorker struct {
	river.WorkerDefaults[CleanupArgs]
	Q db.Querier
}

// Work implements river.Worker.
func (w *CleanupWorker) Work(ctx context.Context, _ *river.Job[CleanupArgs]) error {
	if _, err := w.Q.DeleteExpiredAuthTokens(ctx); err != nil {
		return err
	}
	_, err := w.Q.DeleteExpiredSessions(ctx)
	return err
}
