package notify

import (
	"context"
	"log/slog"

	"github.com/google/uuid"
	kit "github.com/lioilsources/ol1n_platform_kit/notify"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

// PushDevices lists and prunes the push devices of a user (*db.Queries in
// system context).
type PushDevices interface {
	SystemPushDevices(ctx context.Context, userID uuid.UUID) ([]db.PushDevice, error)
	DeletePushDeviceByToken(ctx context.Context, arg db.DeletePushDeviceByTokenParams) error
}

// devices adapts TerraReality's sqlc types to the kit (identical fields).
type devices struct{ q PushDevices }

func (d devices) SystemPushDevices(ctx context.Context, userID uuid.UUID) ([]kit.Device, error) {
	rows, err := d.q.SystemPushDevices(ctx, userID)
	out := make([]kit.Device, len(rows))
	for i, r := range rows {
		out[i] = kit.Device(r)
	}
	return out, err
}

func (d devices) DeletePushDeviceByToken(ctx context.Context, arg kit.DeleteDeviceParams) error {
	return d.q.DeletePushDeviceByToken(ctx, db.DeletePushDeviceByTokenParams(arg))
}

func adapt(q PushDevices) kit.PushDevices {
	if q == nil {
		return nil
	}
	return devices{q}
}

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

// PushUser sends p to every registered device of a user (see kit.PushUser).
func PushUser(ctx context.Context, q PushDevices, pusher Pusher, log *slog.Logger, userID uuid.UUID, p Push) int {
	return kit.PushUser(ctx, adapt(q), pusher, log, userID, p)
}

// DeliverPush is PushUser for the push job (see kit.DeliverPush).
func DeliverPush(ctx context.Context, q PushDevices, pusher Pusher, log *slog.Logger, userID uuid.UUID, p Push) (int, error) {
	return kit.DeliverPush(ctx, adapt(q), pusher, log, userID, p)
}
