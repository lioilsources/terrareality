package leasing

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
)

// Push notifications about leases and payments. They are queued in the
// system transaction that records the change or enqueues its e-mails
// (notify.Pushes): a job delivers them after commit and a failure never
// fails the change.

func (s *Service) pushes() notify.Pushes { return notify.NewPushes(s.Outbox, s.Pusher, s.Log) }

func (s *Service) warn(msg string, err error) {
	if s.Log != nil {
		s.Log.Warn(msg, "err", err)
	}
}

// partyUser is the account of a tenant-side party: the linked user, or the
// account with the party's e-mail once that e-mail is verified (parties are
// linked to it on first access, ClaimLeaseParties, which may not have
// happened yet). An unverified account with the address is never used.
func partyUser(ctx context.Context, q *db.Queries, p db.LeaseParty) (db.User, bool) {
	var u db.User
	var err error
	switch {
	case p.UserID != nil:
		u, err = q.GetUser(ctx, *p.UserID)
	case p.Email != nil:
		u, err = q.GetUserByEmail(ctx, *p.Email)
		if err == nil && u.EmailVerifiedAt == nil {
			return u, false
		}
	default:
		return u, false
	}
	return u, err == nil && u.PseudonymizedAt == nil
}

// pushParties queues a lease event for the tenant side (parties with an
// account) and, when landlord is true, for the landlord's members.
func (s *Service) pushParties(ctx context.Context, q *db.Queries, tx pgx.Tx, l db.Lease, key string, landlord bool) {
	ps := s.pushes()
	if !ps.Enabled() || notify.PushTitles[key] == nil {
		return
	}
	title := notify.PushTitles[key]
	parties, err := q.ListLeaseParties(ctx, l.ID)
	if err != nil {
		s.warn("push lease", err)
		return
	}
	for _, p := range parties {
		if p.Role == "landlord" || key == "lease_changes_requested" { // the tenants asked for the changes
			continue
		}
		u, ok := partyUser(ctx, q, p)
		if !ok {
			continue
		}
		ps.Send(ctx, tx, u.ID, notify.Push{Title: title.Pick(u.Locale), Body: l.PropertyAddress,
			Link: s.WebBaseURL + "/smlouvy/" + l.ID.String(),
			Data: notify.PushData(notify.PushLease, l.ID.String(), map[string]string{"state": l.State})})
	}
	if !landlord {
		return
	}
	members, err := q.OrgMessagingMembers(ctx, l.OrgID)
	if err != nil {
		s.warn("push lease", err)
		return
	}
	for _, m := range members {
		ps.Send(ctx, tx, m.ID, notify.Push{Title: title.Pick(m.Locale), Body: l.PropertyAddress,
			Link: s.WebBaseURL + "/admin/orgs/" + l.OrgID.String() + "/smlouvy/" + l.ID.String(),
			Data: notify.PushData(notify.PushLease, l.ID.String(), map[string]string{"state": l.State,
				"audience": "landlord", "org_id": l.OrgID.String()})})
	}
}

// pushReminders queues a payment reminder stage for the tenants behind the
// unpaid shares; the escalation also goes to the landlord's members.
func (s *Service) pushReminders(ctx context.Context, q *db.Queries, tx pgx.Tx, l db.Lease, rows []db.OverdueSplitsForReminderRow, key string, day time.Time) {
	ps := s.pushes()
	if !ps.Enabled() || notify.PushTitles[key] == nil {
		return
	}
	due := day.Format("2. 1. 2006")
	for _, r := range rows {
		if r.UserID == nil {
			continue
		}
		locale := "cs"
		if r.Locale != nil {
			locale = *r.Locale
		}
		ps.Send(ctx, tx, *r.UserID, notify.Push{Title: notify.PushTitles[key].Pick(locale),
			Body: money(r.Amount-r.PaidAmount, l.Currency) + " · " + due, Link: s.WebBaseURL + "/smlouvy/" + l.ID.String(),
			Data: notify.PushData(notify.PushObligation, r.ID.String(), map[string]string{"lease_id": l.ID.String(),
				"due_on": day.Format("2006-01-02"), "stage": key})})
	}
	if key != "payment_escalation" {
		return
	}
	members, err := q.OrgMessagingMembers(ctx, l.OrgID)
	if err != nil {
		s.warn("push reminder", err)
		return
	}
	for _, m := range members {
		ps.Send(ctx, tx, m.ID, notify.Push{Title: notify.PushTitles["payment_escalation_landlord"].Pick(m.Locale),
			Body: l.PropertyAddress + " · " + due, Link: s.WebBaseURL + "/admin/orgs/" + l.OrgID.String() + "/smlouvy/" + l.ID.String(),
			Data: notify.PushData(notify.PushObligation, l.ID.String(), map[string]string{"lease_id": l.ID.String(),
				"due_on": day.Format("2006-01-02"), "stage": key, "audience": "landlord", "org_id": l.OrgID.String()})})
	}
}

// pushPayment queues a push to the paying tenant that a payment of their
// share was recorded (bank match, confirmed match or the landlord's manual
// entry), in the transaction that books it.
func (s *Service) pushPayment(ctx context.Context, q *db.Queries, tx pgx.Tx, splitID uuid.UUID, amount int64) {
	ps := s.pushes()
	if !ps.Enabled() {
		return
	}
	sp, err := q.GetSplit(ctx, splitID)
	if err != nil {
		s.warn("push payment", err)
		return
	}
	parties, err := q.ListLeaseParties(ctx, sp.LeaseID)
	if err != nil {
		s.warn("push payment", err)
		return
	}
	for _, p := range parties {
		if p.ID != sp.PartyID {
			continue
		}
		u, ok := partyUser(ctx, q, p)
		if !ok {
			return
		}
		locale := u.Locale
		body := money(amount, sp.Currency) + " · " + sp.Period
		if sp.Kind == "deposit" {
			body = money(amount, sp.Currency) + " · " + notify.Text{"cs": "kauce", "en": "deposit"}.Pick(locale)
		}
		ps.Send(ctx, tx, u.ID, notify.Push{Title: notify.PushTitles["payment_received"].Pick(locale),
			Body: body, Link: s.WebBaseURL + "/smlouvy/" + sp.LeaseID.String(),
			Data: notify.PushData(notify.PushObligation, splitID.String(), map[string]string{"lease_id": sp.LeaseID.String(),
				"paid": boolStr(sp.PaidAmount >= sp.Amount)})})
	}
}

func boolStr(b bool) string {
	if b {
		return "true"
	}
	return "false"
}
