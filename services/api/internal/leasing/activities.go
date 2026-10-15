package leasing

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/portfolio"
)

// Activities are the Temporal activities of the lease lifecycle workflow.
type Activities struct {
	S *Service
}

// Info is the lifecycle-relevant state of a lease.
type Info struct {
	State    string
	StartsOn time.Time  // 00:00 Prague
	EndsOn   *time.Time // 00:00 Prague of the day after the last day
	Stages   []Stage    // reminder stages from the lease rules (empty = ReminderStages)
}

// Stage is a reminder offset in days relative to the due date.
type Stage struct {
	Name   string
	Offset int
}

// ReminderStages are the default reminder stages (CZ jurisdiction).
var ReminderStages = []Stage{{"upcoming", -3}, {"overdue", 1}, {"escalation", 7}}

// StagesFor returns the reminder stages of rules stored in lease terms
// (rules per municipality or group, M6b).
func StagesFor(terms []byte) []Stage {
	r := portfolio.LeaseRules(terms)
	return []Stage{{"upcoming", -*r.ReminderBeforeDays}, {"overdue", *r.OverdueDays}, {"escalation", *r.EscalationDays}}
}

func atPrague(d time.Time, hour int) time.Time {
	return time.Date(d.Year(), d.Month(), d.Day(), hour, 0, 0, 0, prague)
}

// Info implements an activity.
func (a *Activities) Info(ctx context.Context, leaseID uuid.UUID) (Info, error) {
	l, err := db.New(a.S.Pool).GetLease(ctx, leaseID)
	if err != nil {
		return Info{}, err
	}
	out := Info{State: l.State, StartsOn: atPrague(l.StartsOn.Time, 0), Stages: StagesFor(l.Terms)}
	if l.EndsOn.Valid {
		end := atPrague(l.EndsOn.Time, 0).AddDate(0, 0, 1)
		out.EndsOn = &end
	}
	return out, nil
}

// Activate implements an activity: signed -> active on the start date.
func (a *Activities) Activate(ctx context.Context, leaseID uuid.UUID) error {
	return a.S.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		n, err := q.SetLeaseState(ctx, db.SetLeaseStateParams{State: "active", ID: leaseID, FromStates: []string{"signed"}})
		if err != nil || n == 0 {
			return err
		}
		l, err := q.GetLease(ctx, leaseID)
		if err != nil {
			return err
		}
		_, err = appendEvent(ctx, q, l, "activated", nil, map[string]any{})
		return err
	})
}

// DueDates implements an activity: open due dates on or after from, as the
// time reminders are anchored to (09:00 Prague on the due day).
func (a *Activities) DueDates(ctx context.Context, leaseID uuid.UUID, from time.Time) ([]time.Time, error) {
	rows, err := db.New(a.S.Pool).LeaseDueDates(ctx, db.LeaseDueDatesParams{LeaseID: leaseID, DueOn: date(&from)})
	if err != nil {
		return nil, err
	}
	out := make([]time.Time, 0, len(rows))
	for _, r := range rows {
		out = append(out, atPrague(r.Time, 9))
	}
	return out, nil
}

// Remind implements an activity: it notifies about the unpaid shares due on
// a day and returns how many are unpaid (0 ends the reminders for that day).
// The escalation also tells the landlord and is recorded in the event log.
func (a *Activities) Remind(ctx context.Context, leaseID uuid.UUID, due time.Time, stage string) (int, error) {
	day := time.Date(due.Year(), due.Month(), due.Day(), 0, 0, 0, 0, time.UTC)
	q := db.New(a.S.Pool)
	rows, err := q.OverdueSplitsForReminder(ctx, db.OverdueSplitsForReminderParams{LeaseID: leaseID, DueOn: date(&day)})
	if err != nil || len(rows) == 0 {
		return 0, err
	}
	l, err := q.GetLease(ctx, leaseID)
	if err != nil {
		return 0, err
	}
	if l.State != "signed" && l.State != "active" && l.State != "notice_given" {
		return 0, nil
	}
	key := map[string]string{"upcoming": "payment_upcoming", "overdue": "payment_overdue", "escalation": "payment_escalation"}[stage]
	err = a.S.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		var names []string
		for _, r := range rows {
			names = append(names, r.Name)
			if r.Email == nil || a.S.Outbox == nil {
				continue
			}
			locale := "cs"
			if r.Locale != nil {
				locale = *r.Locale
			}
			m, err := a.S.Mail.Render(notify.Email, *r.Email, locale, key, map[string]any{"Code": l.Code,
				"Address": l.PropertyAddress, "Amount": money(r.Amount-r.PaidAmount, l.Currency),
				"Due": day.Format("2. 1. 2006"), "Link": a.S.WebBaseURL + "/smlouvy/" + leaseID.String()})
			if err != nil {
				return err
			}
			if err := a.S.Outbox.Enqueue(ctx, tx, m); err != nil {
				return err
			}
		}
		if stage != "escalation" {
			return nil
		}
		if _, err := appendEvent(ctx, q, l, "payment_escalated", nil, map[string]any{"due_on": day.Format("2006-01-02"),
			"unpaid": len(rows), "parties": names}); err != nil {
			return err
		}
		members, err := q.OrgMessagingMembers(ctx, l.OrgID)
		if err != nil || a.S.Outbox == nil {
			return err
		}
		for _, m := range members {
			msg, err := a.S.Mail.Render(notify.Email, m.Email, m.Locale, "payment_escalation_landlord", map[string]any{
				"Code": l.Code, "Address": l.PropertyAddress, "Due": day.Format("2. 1. 2006"), "Count": len(rows),
				"Link": a.S.WebBaseURL + "/admin/orgs/" + l.OrgID.String() + "/smlouvy/" + leaseID.String()})
			if err != nil {
				return err
			}
			if err := a.S.Outbox.Enqueue(ctx, tx, msg); err != nil {
				return err
			}
		}
		return nil
	})
	return len(rows), err
}

// Extend implements an activity: an indefinite lease gets the next months
// scheduled once fewer than two months are left. It reports new items.
func (a *Activities) Extend(ctx context.Context, leaseID uuid.UUID) (bool, error) {
	q := db.New(a.S.Pool)
	l, err := q.GetLease(ctx, leaseID)
	if err != nil || l.EndsOn.Valid || (l.State != "active" && l.State != "signed") {
		return false, err
	}
	last, err := q.LastRentPeriod(ctx, leaseID)
	if err != nil {
		return false, err
	}
	lastMonth, err := time.Parse("2006-01", last)
	if err != nil {
		return false, err
	}
	if lastMonth.After(a.S.now().AddDate(0, 2, 0)) {
		return false, nil
	}
	err = a.S.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		return a.S.schedule(ctx, q, l, lastMonth.AddDate(0, 1, 0))
	})
	return err == nil, err
}

// Finish implements an activity: after the last day the lease is terminated.
func (a *Activities) Finish(ctx context.Context, leaseID uuid.UUID) (bool, error) {
	q := db.New(a.S.Pool)
	l, err := q.GetLease(ctx, leaseID)
	if errors.Is(err, pgx.ErrNoRows) {
		return true, nil
	}
	if err != nil {
		return false, err
	}
	switch l.State {
	case "terminated", "settled", "cancelled":
		return true, nil
	}
	if !l.EndsOn.Valid || !a.S.now().After(atPrague(l.EndsOn.Time, 0).AddDate(0, 0, 1)) {
		return false, nil
	}
	return true, a.S.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		if err := q.SystemSetLeaseState(ctx, db.SystemSetLeaseStateParams{ID: leaseID, State: "terminated"}); err != nil {
			return err
		}
		_, err := appendEvent(ctx, q, l, "terminated", nil, map[string]any{"ends_on": l.EndsOn.Time.Format("2006-01-02")})
		return err
	})
}
