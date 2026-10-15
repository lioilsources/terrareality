package applications

import (
	"context"

	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
)

// Push notifications about applications are queued in the system
// transaction that enqueues the e-mails of the same event (notify.Pushes):
// a job delivers them after commit and a failure never fails the change.
// Titles come from notify.PushTitles under the e-mail template key.

// pushStatus is the application status a decision key leads to.
var pushStatus = map[string]string{"application_invited": StatusInvited, "application_accepted": StatusAccepted,
	"application_rejected": StatusRejected}

func (s *Service) pushes() notify.Pushes { return notify.NewPushes(s.Outbox, s.Pusher, s.Log) }

// pushOrgSubmitted queues a new application for the landlord's members who
// handle messages.
func (s *Service) pushOrgSubmitted(ctx context.Context, tx pgx.Tx, a db.SystemGetApplicationRow, members []db.OrgMessagingMembersRow) {
	ps := s.pushes()
	if !ps.Enabled() {
		return
	}
	title := notify.Text(i18n(a.ListingTitle))
	link := s.WebBaseURL + "/admin/orgs/" + a.OrgID.String() + "/listings/" + a.ListingID.String() + "/zajemci"
	for _, m := range members {
		ps.Send(ctx, tx, m.ID, notify.Push{
			Title: notify.PushTitles["application_received"].Pick(m.Locale), Body: title.Pick(m.Locale), Link: link,
			Data: notify.PushData(notify.PushApplication, a.ID.String(), map[string]string{"audience": "landlord",
				"org_id": a.OrgID.String(), "listing_id": a.ListingID.String(), "status": StatusSubmitted})})
	}
}

// pushApplicants queues a decision (key application_invited, _accepted or
// _rejected) for the applicant and joined group members.
func (s *Service) pushApplicants(ctx context.Context, tx pgx.Tx, a db.SystemGetApplicationRow, people []db.ApplicationPeopleRow, key, reason string) {
	ps := s.pushes()
	if !ps.Enabled() || notify.PushTitles[key] == nil {
		return
	}
	title := notify.Text(i18n(a.ListingTitle))
	link := s.WebBaseURL + "/zadosti/" + a.ID.String()
	for _, p := range people {
		body := title.Pick(p.Locale)
		if reason != "" && reasonTexts[reason] != nil {
			body += " · " + notify.Text(reasonTexts[reason]).Pick(p.Locale)
		}
		ps.Send(ctx, tx, p.ID, notify.Push{
			Title: notify.PushTitles[key].Pick(p.Locale), Body: body, Link: link,
			Data: notify.PushData(notify.PushApplication, a.ID.String(), map[string]string{"status": pushStatus[key]})})
	}
}
