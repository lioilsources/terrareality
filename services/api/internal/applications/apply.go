package applications

import (
	"context"
	"encoding/json"
	"errors"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/messaging"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/textscan"
)

// Statuses.
const (
	StatusPendingConsent = "pending_consent"
	StatusSubmitted      = "submitted"
	StatusInvited        = "invited"
	StatusAccepted       = "accepted"
	StatusRejected       = "rejected"
	StatusWithdrawn      = "withdrawn"
)

// RejectReasons is the code list landlords choose from (no free-text
// reasons, so protected characteristics cannot become a stated reason).
var RejectReasons = []string{"other_applicant_chosen", "income_insufficient", "move_in_mismatch", "duration_mismatch",
	"incomplete", "listing_withdrawn", "other"}

var errAppNotFound = apperr.NotFound("application_not_found", "application not found")

// ApplyInput is a new application.
type ApplyInput struct {
	ListingID      uuid.UUID
	GroupID        *uuid.UUID
	Message        string
	Answers        map[string]string
	PreferredFrom  *time.Time
	DurationMonths *int32
	HouseholdSize  int32
}

// Apply files an application. A group application waits for the consent of
// every joined member before the landlord sees it.
func (s *Service) Apply(ctx context.Context, p *auth.Principal, in ApplyInput) (uuid.UUID, error) {
	sys := db.New(s.Pool)
	l, err := sys.ListingForConversation(ctx, in.ListingID)
	if errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, apperr.NotFound("listing_not_found", "listing not found")
	}
	if err != nil {
		return uuid.Nil, err
	}
	if _, err := sys.GetMembership(ctx, db.GetMembershipParams{OrgID: l.OrgID, UserID: p.UserID}); err == nil {
		return uuid.Nil, apperr.Conflict("own_listing", "you cannot apply for your own listing")
	}
	var questions []messaging.PrescreenQuestion
	_ = json.Unmarshal(l.Prescreen, &questions)
	answers, err := messaging.MatchAnswers(questions, in.Answers)
	if err != nil {
		return uuid.Nil, err
	}
	rawAnswers, _ := json.Marshal(answers)
	msg := strings.TrimSpace(in.Message)
	if utf8.RuneCountInString(msg) > 4000 {
		return uuid.Nil, apperr.Unprocessable("message_too_long", "messages are limited to 4000 characters")
	}
	msg, _ = textscan.Scan(msg)
	if in.DurationMonths != nil && (*in.DurationMonths < 1 || *in.DurationMonths > 120) {
		return uuid.Nil, apperr.Unprocessable("invalid_duration", "duration is 1 to 120 months")
	}
	var from pgtype.Date
	if in.PreferredFrom != nil {
		from = pgtype.Date{Time: *in.PreferredFrom, Valid: true}
	}

	var app db.Application
	var others []uuid.UUID
	err = s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		status := StatusSubmitted
		household := max(in.HouseholdSize, 1)
		var members []uuid.UUID
		if in.GroupID != nil {
			if _, err := q.GetGroupMember(ctx, db.GetGroupMemberParams{GroupID: *in.GroupID, UserID: &p.UserID}); err != nil {
				return errGroupNotFound
			}
			rows, err := q.ListGroupMembers(ctx, *in.GroupID)
			if err != nil {
				return err
			}
			for _, m := range rows {
				if m.UserID != nil && m.JoinedAt != nil {
					members = append(members, *m.UserID)
				}
			}
			if len(members) > 1 {
				status = StatusPendingConsent
			}
			household = max(household, int32(len(members)))
		}
		var submittedAt *time.Time
		if status == StatusSubmitted {
			now := time.Now()
			submittedAt = &now
		}
		app, err = q.InsertApplication(ctx, db.InsertApplicationParams{ListingID: in.ListingID, OrgID: l.OrgID,
			ApplicantID: p.UserID, GroupID: in.GroupID, Status: status, Message: msg, Answers: rawAnswers,
			PreferredFrom: from, DurationMonths: in.DurationMonths, HouseholdSize: household, SubmittedAt: submittedAt})
		if err != nil {
			var pgErr interface{ SQLState() string }
			if errors.As(err, &pgErr) && pgErr.SQLState() == "23505" {
				return apperr.Conflict("already_applied", "you already have an open application for this listing")
			}
			return err
		}
		now := time.Now()
		for _, m := range members {
			var at *time.Time
			if m == p.UserID {
				at = &now
			} else {
				others = append(others, m)
			}
			if err := q.InsertApplicationConsent(ctx, db.InsertApplicationConsentParams{ApplicationID: app.ID, UserID: m,
				ConsentedAt: at}); err != nil {
				return err
			}
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &l.OrgID, Entity: "application", EntityID: &app.ID,
			Action: "application.create", Diff: map[string]any{"listing_id": in.ListingID, "group_id": in.GroupID, "status": status}})
	})
	if err != nil {
		return uuid.Nil, err
	}
	return app.ID, s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		if app.Status == StatusSubmitted {
			return s.onSubmitted(ctx, q, tx, app.ID)
		}
		var to []recipient
		for _, id := range others {
			u, err := q.GetUser(ctx, id)
			if err == nil && u.PseudonymizedAt == nil {
				to = append(to, recipient{ID: u.ID, Email: u.Email, Locale: u.Locale})
			}
		}
		applicant, _ := q.GetUser(ctx, p.UserID)
		return s.notifyAll(ctx, q, tx, to, "application_consent", s.WebBaseURL+"/zadosti/"+app.ID.String(),
			map[string]any{"ListingTitle": i18n(l.Title), "Applicant": applicant.DisplayName})
	})
}

// onSubmitted notifies the landlord and asks the AI for a summary.
func (s *Service) onSubmitted(ctx context.Context, q *db.Queries, tx pgx.Tx, id uuid.UUID) error {
	a, err := q.SystemGetApplication(ctx, id)
	if err != nil {
		return err
	}
	members, err := q.OrgMessagingMembers(ctx, a.OrgID)
	if err != nil {
		return err
	}
	to := make([]recipient, 0, len(members))
	for _, m := range members {
		to = append(to, recipient{ID: m.ID, Email: m.Email, Locale: m.Locale})
	}
	link := s.WebBaseURL + "/admin/orgs/" + a.OrgID.String() + "/listings/" + a.ListingID.String() + "/zajemci"
	if err := s.notifyAll(ctx, q, tx, to, "application_received", link,
		map[string]any{"ListingTitle": i18n(a.ListingTitle), "Household": a.HouseholdSize}); err != nil {
		return err
	}
	if s.Jobs != nil {
		return s.Jobs.SummarizeApplication(ctx, tx, id)
	}
	return nil
}

// Consent records the caller's consent to a group application; the last
// consent submits it.
func (s *Service) Consent(ctx context.Context, p *auth.Principal, id uuid.UUID) error {
	var submitted bool
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		a, err := q.GetApplication(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			return errAppNotFound
		}
		if err != nil {
			return err
		}
		if a.Status != StatusPendingConsent {
			return apperr.Conflict("not_pending_consent", "this application is no longer waiting for consent")
		}
		n, err := q.GiveConsent(ctx, db.GiveConsentParams{ApplicationID: id, UserID: p.UserID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("no_consent_needed", "your consent is not needed or was already given")
		}
		if err := audit.Record(ctx, q, audit.Event{OrgID: &a.OrgID, Entity: "application", EntityID: &id,
			Action: "application.consent"}); err != nil {
			return err
		}
		missing, err := q.CountMissingConsents(ctx, id)
		if err != nil || missing > 0 {
			return err
		}
		n, err = q.SubmitApplication(ctx, id)
		submitted = n == 1
		return err
	})
	if err != nil || !submitted {
		return err
	}
	return s.system(ctx, func(q *db.Queries, tx pgx.Tx) error { return s.onSubmitted(ctx, q, tx, id) })
}

// Withdraw cancels the caller's own application.
func (s *Service) Withdraw(ctx context.Context, p *auth.Principal, id uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		a, err := q.GetApplication(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && a.ApplicantID != p.UserID) {
			return errAppNotFound
		}
		if err != nil {
			return err
		}
		n, err := q.WithdrawApplication(ctx, id)
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("application_closed", "this application is already closed")
		}
		if err := q.CancelApplicationBookings(ctx, id); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &a.OrgID, Entity: "application", EntityID: &id, Action: "application.withdraw"})
	})
}

// MyApplications lists the caller's applications (own and group ones).
func (s *Service) MyApplications(ctx context.Context, p *auth.Principal) ([]db.ListMyApplicationsRow, error) {
	var out []db.ListMyApplicationsRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		out, err = q.ListMyApplications(ctx, p.UserID)
		return err
	})
	return out, err
}

// Detail is an application as its applicants see it.
type Detail struct {
	db.GetApplicationRow
	Consents []db.ListApplicationConsentsRow
	Slots    []db.SlotsWithAvailabilityRow // bookable while submitted or invited
	Booking  *db.MyViewingsRow
}

// Application returns one of the caller's applications.
func (s *Service) Application(ctx context.Context, p *auth.Principal, id uuid.UUID) (Detail, error) {
	var out Detail
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		a, err := q.GetApplication(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			return errAppNotFound
		}
		if err != nil {
			return err
		}
		out.GetApplicationRow = a
		if out.Consents, err = q.ListApplicationConsents(ctx, id); err != nil {
			return err
		}
		views, err := q.MyViewings(ctx, p.UserID)
		if err != nil {
			return err
		}
		for i := range views {
			if views[i].ApplicationID == id {
				out.Booking = &views[i]
			}
		}
		return nil
	})
	if err != nil {
		return out, err
	}
	if out.Status == StatusSubmitted || out.Status == StatusInvited {
		out.Slots, err = db.New(s.Pool).SlotsWithAvailability(ctx, out.ListingID)
	}
	return out, err
}

// ---------------------------------------------------------------------------
// Landlord side.

// Person is one applicant with passport facts as the landlord sees them.
type Person struct {
	ID           uuid.UUID
	Name         string
	Verification string
	IncomeProof  string // download URL, empty when not uploaded
	IncomeName   string
	Insolvency   string
}

// Applicant is a row of the landlord's overview.
type Applicant struct {
	db.ListListingApplicationsRow
	People []Person
}

// Applicants lists submitted applications for a listing, verified people
// first. Passport facts are read in system context after the RLS check.
func (s *Service) Applicants(ctx context.Context, p *auth.Principal, orgID, listingID uuid.UUID) ([]Applicant, error) {
	var rows []db.ListListingApplicationsRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermMessages); err != nil {
			return err
		}
		var err error
		rows, err = q.ListListingApplications(ctx, db.ListListingApplicationsParams{ListingID: listingID, OrgID: orgID})
		return err
	})
	if err != nil {
		return nil, err
	}
	out := make([]Applicant, 0, len(rows))
	sys := db.New(s.Pool)
	for _, r := range rows {
		people, err := s.people(ctx, sys, r.ID)
		if err != nil {
			return nil, err
		}
		out = append(out, Applicant{ListListingApplicationsRow: r, People: people})
	}
	return out, nil
}

func (s *Service) people(ctx context.Context, q *db.Queries, appID uuid.UUID) ([]Person, error) {
	rows, err := q.ApplicationPeople(ctx, appID)
	if err != nil {
		return nil, err
	}
	out := make([]Person, 0, len(rows))
	for _, r := range rows {
		pp := Person{ID: r.ID, Name: r.DisplayName, Verification: r.VerificationLevel, Insolvency: r.IsirStatus}
		if r.IncomeKey != nil {
			pp.IncomeProof, _ = s.Blob.PresignGet(ctx, *r.IncomeKey, 15*time.Minute)
			if r.IncomeFilename != nil {
				pp.IncomeName = *r.IncomeFilename
			}
		}
		out = append(out, pp)
	}
	return out, nil
}

// Decide is the landlord's decision: invite to a viewing, accept (all other
// applicants get an automatic answer) or reject with a reason code.
func (s *Service) Decide(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID, action, reason string) error {
	var to, from string
	var reasonPtr *string
	switch action {
	case "invite":
		to, from = StatusInvited, StatusSubmitted
	case "accept":
		to, from = StatusAccepted, StatusSubmitted+","+StatusInvited
	case "reject":
		if !slices.Contains(RejectReasons, reason) || reason == "other_applicant_chosen" {
			return apperr.Unprocessable("invalid_reason", "choose a reason from the list")
		}
		to, from, reasonPtr = StatusRejected, StatusSubmitted+","+StatusInvited, &reason
	default:
		return apperr.Unprocessable("invalid_action", "action is invite, accept or reject")
	}
	var a db.GetApplicationRow
	var rejected []uuid.UUID
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermMessages); err != nil {
			return err
		}
		var err error
		if a, err = q.GetApplication(ctx, id); errors.Is(err, pgx.ErrNoRows) || (err == nil && a.OrgID != orgID) {
			return errAppNotFound
		} else if err != nil {
			return err
		}
		n, err := q.DecideApplication(ctx, db.DecideApplicationParams{Status: to, RejectReason: reasonPtr, ID: id,
			OrgID: orgID, FromStatus: strings.Split(from, ",")})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("application_closed", "this application cannot change to "+to)
		}
		if to == StatusAccepted {
			if rejected, err = q.RejectOtherApplications(ctx, db.RejectOtherApplicationsParams{ListingID: a.ListingID, ID: id}); err != nil {
				return err
			}
		}
		if to == StatusRejected {
			if err := q.CancelApplicationBookings(ctx, id); err != nil {
				return err
			}
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "application", EntityID: &id,
			Action: "application." + action, Diff: map[string]any{"reason": reason, "auto_rejected": len(rejected)}})
	})
	if err != nil {
		return err
	}
	return s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		key := map[string]string{StatusInvited: "application_invited", StatusAccepted: "application_accepted",
			StatusRejected: "application_rejected"}[to]
		if err := s.notifyApplicants(ctx, q, tx, id, key, reason); err != nil {
			return err
		}
		for _, other := range rejected {
			if err := q.CancelApplicationBookings(ctx, other); err != nil {
				return err
			}
			if err := s.notifyApplicants(ctx, q, tx, other, "application_rejected", "other_applicant_chosen"); err != nil {
				return err
			}
		}
		return nil
	})
}

func (s *Service) notifyApplicants(ctx context.Context, q *db.Queries, tx pgx.Tx, id uuid.UUID, key, reason string) error {
	a, err := q.SystemGetApplication(ctx, id)
	if err != nil {
		return err
	}
	people, err := q.ApplicationPeople(ctx, id)
	if err != nil {
		return err
	}
	to := make([]recipient, 0, len(people))
	for _, pp := range people {
		to = append(to, recipient{ID: pp.ID, Email: pp.Email, Locale: pp.Locale})
	}
	return s.notifyAll(ctx, q, tx, to, key, s.WebBaseURL+"/zadosti/"+id.String(),
		map[string]any{"ListingTitle": i18n(a.ListingTitle), "Reason": reason})
}
