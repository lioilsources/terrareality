package notify

import (
	"context"
	"errors"
	"log/slog"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

// PushDevices lists and prunes the push devices of a user (*db.Queries in
// system context).
type PushDevices interface {
	SystemPushDevices(ctx context.Context, userID uuid.UUID) ([]db.PushDevice, error)
	DeletePushDeviceByToken(ctx context.Context, arg db.DeletePushDeviceByTokenParams) error
}

// Text is a short push text per locale.
type Text map[string]string

// PushTitles are the push titles per notification key. The keys are the
// e-mail template keys of the same events (messages/*.json), so a sender
// pushes and mails one event under one key.
var PushTitles = map[string]Text{
	"application_received":        {"cs": "Nová žádost o nájem", "en": "New rental application"},
	"application_invited":         {"cs": "Pozvánka na prohlídku", "en": "Invitation to a viewing"},
	"application_accepted":        {"cs": "Vaše žádost byla přijata", "en": "Your application was accepted"},
	"application_rejected":        {"cs": "Vaše žádost nebyla vybrána", "en": "Your application was not selected"},
	"viewing_cancelled":           {"cs": "Prohlídka byla zrušena", "en": "A viewing was cancelled"},
	"lease_proposed":              {"cs": "Smlouva čeká na váš podpis", "en": "Your lease is ready to sign"},
	"lease_changes_requested":     {"cs": "Nájemník žádá změny smlouvy", "en": "Lease changes requested"},
	"lease_signed":                {"cs": "Smlouva je podepsaná všemi stranami", "en": "The lease is fully signed"},
	"lease_notice":                {"cs": "Byla podána výpověď nájmu", "en": "Notice was given on the lease"},
	"payment_upcoming":            {"cs": "Blíží se splatnost platby", "en": "A payment is due soon"},
	"payment_overdue":             {"cs": "Platba je po splatnosti", "en": "A payment is overdue"},
	"payment_escalation":          {"cs": "Platba je stále neuhrazená", "en": "A payment is still unpaid"},
	"payment_escalation_landlord": {"cs": "Nájemník neuhradil platbu", "en": "A tenant payment is unpaid"},
	"payment_received":            {"cs": "Platba byla připsána", "en": "Payment received"},
}

// Pick returns the text in locale, falling back to Czech, then English.
func (t Text) Pick(locale string) string {
	if v := t[locale]; v != "" {
		return v
	}
	if v := t["cs"]; v != "" {
		return v
	}
	return t["en"]
}

// PushUser sends p to every registered device of a user and returns how many
// devices accepted it. Platform, token, keys and user id are filled per
// device. Failures are logged, never returned: a push must not fail the
// business operation that triggered it. Gone devices are removed.
func PushUser(ctx context.Context, q PushDevices, pusher Pusher, log *slog.Logger, userID uuid.UUID, p Push) int {
	n, err := DeliverPush(ctx, q, pusher, log, userID, p)
	if err != nil {
		logger(log).Warn("push devices", "err", err, "user", userID)
	}
	return n
}

func logger(log *slog.Logger) *slog.Logger {
	if log == nil {
		return slog.Default()
	}
	return log
}

// DeliverPush is PushUser for the push job: it returns the device lookup
// error (the job retries) while delivery failures per device are only logged
// (a retry would repeat the pushes that went through).
func DeliverPush(ctx context.Context, q PushDevices, pusher Pusher, log *slog.Logger, userID uuid.UUID, p Push) (int, error) {
	if pusher == nil || q == nil {
		return 0, nil
	}
	log = logger(log)
	devices, err := q.SystemPushDevices(ctx, userID)
	if err != nil {
		return 0, err
	}
	sent := 0
	for _, d := range devices {
		p.Platform, p.Token, p.Keys, p.UserID = d.Platform, d.Token, d.Keys, userID.String()
		err := pusher.Push(ctx, p)
		switch {
		case err == nil:
			sent++
		case errors.Is(err, ErrDeviceGone):
			if err := q.DeletePushDeviceByToken(ctx, db.DeletePushDeviceByTokenParams{Platform: d.Platform, Token: d.Token}); err != nil {
				log.Warn("push device cleanup", "err", err)
			}
		default:
			log.Warn("push", "err", err, "platform", d.Platform, "kind", p.Data["kind"])
		}
	}
	return sent, nil
}

// PushQueue enqueues a push to every device of a user in the caller's
// transaction (jobs.Outbox: a River job the worker delivers after commit).
type PushQueue interface {
	EnqueuePush(ctx context.Context, tx pgx.Tx, userID uuid.UUID, p Push) error
}

// Pushes sends the push notifications of a change from inside the
// transaction that records it (the one that also enqueues its e-mails), so
// a push is neither lost on a restart after commit nor sent for a change
// that rolled back, and the request does not wait for FCM.
type Pushes struct {
	Queue  PushQueue // nil: delivered at once with Pusher (tests, tools)
	Pusher Pusher    // nil: push notifications are off
	Log    *slog.Logger
}

// NewPushes queues through the outbox when it also queues pushes.
func NewPushes(outbox Outbox, pusher Pusher, log *slog.Logger) Pushes {
	q, _ := outbox.(PushQueue)
	return Pushes{Queue: q, Pusher: pusher, Log: log}
}

// Enabled reports whether pushes are sent at all.
func (ps Pushes) Enabled() bool { return ps.Pusher != nil }

// Send queues p for userID in tx (system context). It never fails the
// transaction: the work runs in a savepoint that is rolled back on error,
// and the error is only logged.
func (ps Pushes) Send(ctx context.Context, tx pgx.Tx, userID uuid.UUID, p Push) {
	if ps.Pusher == nil || tx == nil {
		return
	}
	sp, err := tx.Begin(ctx)
	if err == nil {
		if ps.Queue != nil {
			err = ps.Queue.EnqueuePush(ctx, sp, userID, p)
		} else {
			PushUser(ctx, db.New(sp), ps.Pusher, ps.Log, userID, p)
		}
		if err != nil {
			_ = sp.Rollback(ctx)
		} else {
			err = sp.Commit(ctx)
		}
	}
	if err != nil {
		logger(ps.Log).Warn("queue push", "err", err, "user", userID, "kind", p.Data["kind"])
	}
}
