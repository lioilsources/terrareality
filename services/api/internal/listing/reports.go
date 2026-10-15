package listing

import (
	"context"
	"errors"
	"net/mail"
	"slices"
	"strings"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// DSA notice-and-action (Regulation (EU) 2022/2065, art. 16 and 17). Anyone
// can report a published listing; the report is a moderation case of kind
// "listing" in the staff queue. Staff decide (ADR 0003): nothing here acts
// on a report without a human decision.

// Report reasons and staff decisions for listing cases.
var (
	ReportReasons   = []string{"illegal_content", "fraud", "discrimination", "wrong_info", "other"}
	ReportDecisions = []string{"keep", "unpublish", "request_change"}
)

const (
	minExplanation = 20
	maxExplanation = 2000
)

// ReportInput is a notice about a listing.
type ReportInput struct {
	Reason      string
	Explanation string
	Email       string // anonymous reporters only
	Name        string // optional, anonymous reporters
	Locale      string // cs | en, anonymous reporters
}

var reasonLabels = map[string]map[string]string{
	"cs": {"illegal_content": "nezákonný obsah", "fraud": "podvod", "discrimination": "diskriminace",
		"wrong_info": "nepravdivé nebo zavádějící údaje", "other": "jiný důvod"},
	"en": {"illegal_content": "illegal content", "fraud": "fraud", "discrimination": "discrimination",
		"wrong_info": "false or misleading information", "other": "other"},
}

var decisionLabels = map[string]map[string]string{
	"cs": {"keep": "inzerát ponecháváme zveřejněný, porušení jsme neshledali",
		"unpublish":      "inzerát jsme stáhli z veřejné nabídky",
		"request_change": "inzerát zůstává zveřejněný, inzerenta jsme požádali o úpravu"},
	"en": {"keep": "the listing stays published, we found no violation",
		"unpublish":      "we removed the listing from public view",
		"request_change": "the listing stays published, we asked the advertiser to change it"},
}

func label(m map[string]map[string]string, locale, key string) string {
	if l, ok := m[locale]; ok {
		return l[key]
	}
	return m["cs"][key]
}

func titleIn(t I18n, locale string) string {
	if locale == "en" && t.EN != "" {
		return t.EN
	}
	return t.CS
}

// PublicListingLink is the public listing page on the web.
func (s *Service) PublicListingLink(id uuid.UUID) string {
	return s.WebBaseURL + "/inzerat/" + id.String()
}

// Report files a notice about a published listing. p is nil for anonymous
// visitors, who must give an e-mail address for the acknowledgement and the
// statement of reasons.
func (s *Service) Report(ctx context.Context, p *auth.Principal, listingID uuid.UUID, in ReportInput) (uuid.UUID, error) {
	if !slices.Contains(ReportReasons, in.Reason) {
		return uuid.Nil, apperr.Unprocessable("invalid_reason", "unknown report reason")
	}
	in.Explanation = strings.TrimSpace(in.Explanation)
	if n := utf8.RuneCountInString(in.Explanation); n < minExplanation || n > maxExplanation {
		return uuid.Nil, apperr.Unprocessable("invalid_explanation", "explain the report in 20 to 2000 characters")
	}
	in.Name = strings.TrimSpace(in.Name)
	if utf8.RuneCountInString(in.Name) > 200 {
		return uuid.Nil, apperr.Unprocessable("invalid_name", "name is too long")
	}
	if in.Locale != "en" {
		in.Locale = "cs"
	}
	if p == nil {
		in.Email = strings.TrimSpace(in.Email)
		a, err := mail.ParseAddress(in.Email)
		if in.Email == "" || err != nil || a.Address != in.Email || len(in.Email) > 254 {
			return uuid.Nil, apperr.Unprocessable("reporter_email_required", "anonymous reports need a valid e-mail address")
		}
	}
	var caseID uuid.UUID
	err := s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		l, err := q.ListingForConversation(ctx, listingID) // published, not deleted
		if errors.Is(err, pgx.ErrNoRows) {
			return errListingNotFound
		}
		if err != nil {
			return err
		}
		params := db.CreateListingReportParams{ListingID: &listingID, Reason: in.Reason, Note: &in.Explanation,
			ReporterLocale: in.Locale}
		to, name, locale := in.Email, in.Name, in.Locale
		if p != nil {
			u, err := q.GetUser(ctx, p.UserID)
			if err != nil {
				return err
			}
			params.ReporterID = &p.UserID
			params.ReporterLocale = u.Locale
			to, locale, name = u.Email, u.Locale, u.DisplayName
		} else {
			params.ReporterContactEmail = &in.Email
			if in.Name != "" {
				params.ReporterContactName = &in.Name
			}
		}
		caseID, err = q.CreateListingReport(ctx, params)
		if err != nil {
			return err
		}
		if err := audit.Record(ctx, q, audit.Event{OrgID: &l.OrgID, Entity: "listing", EntityID: &listingID,
			Action: "listing.reported", Diff: map[string]any{"case_id": caseID, "reason": in.Reason,
				"anonymous": p == nil}}); err != nil {
			return err
		}
		if s.Outbox == nil {
			return nil
		}
		m, err := s.Render.Render(notify.Email, to, locale, "listing_report_received", map[string]any{
			"Name": name, "Title": titleIn(i18n(l.Title), locale), "CaseID": caseID.String(),
			"Reason": label(reasonLabels, locale, in.Reason), "Explanation": in.Explanation,
			"Link": s.PublicListingLink(listingID)})
		if err != nil {
			return err
		}
		return s.Outbox.Enqueue(ctx, tx, m)
	})
	return caseID, err
}

// DecideReport resolves a listing case. This is the human decision (ADR
// 0003): keep, unpublish (back to draft; a new version needs review) or
// request_change. The reporter gets the decision with a statement of
// reasons; on unpublish or a change request the owners get it too. Unpublish
// and request_change need a note (the reasons).
func (s *Service) DecideReport(ctx context.Context, staff *auth.Principal, caseID uuid.UUID, decision, note string) error {
	if !slices.Contains(ReportDecisions, decision) {
		return apperr.Unprocessable("invalid_decision", "listing reports take keep, unpublish or request_change")
	}
	note = strings.TrimSpace(note)
	if decision != "keep" && note == "" {
		return apperr.Unprocessable("note_required", "give the reasons for the decision")
	}
	return s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		c, err := q.GetModerationCase(ctx, caseID)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("case_not_found", "case not found")
		}
		if err != nil {
			return err
		}
		if c.Kind != "listing" || c.ListingID == nil {
			return apperr.Unprocessable("invalid_decision", "this case is not a listing report")
		}
		var notePtr *string
		if note != "" {
			notePtr = &note
		}
		n, err := q.DecideModerationCase(ctx, db.DecideModerationCaseParams{ID: caseID, Decision: &decision,
			DecisionNote: notePtr, DecidedBy: &staff.UserID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("case_resolved", "this case was already resolved")
		}
		l, err := q.ListingForReport(ctx, *c.ListingID)
		if errors.Is(err, pgx.ErrNoRows) {
			return errListingNotFound
		}
		if err != nil {
			return err
		}
		if decision == "unpublish" && (l.Status == "published" || l.Status == "paused") {
			if err := q.SystemSetListingStatus(ctx, db.SystemSetListingStatusParams{ID: l.ID, Status: "draft"}); err != nil {
				return err
			}
			if err := q.WithdrawPendingVersionsForModeration(ctx, l.ID); err != nil {
				return err
			}
			if err := s.index(ctx, q, l.ID); err != nil {
				return err
			}
			if err := audit.Record(ctx, q, audit.Event{OrgID: &l.OrgID, Entity: "listing", EntityID: &l.ID,
				Action: "listing.unpublished_by_moderation", Diff: map[string]any{"status": []string{l.Status, "draft"},
					"case_id": caseID, "note": note}}); err != nil {
				return err
			}
		}
		if err := audit.Record(ctx, q, audit.Event{OrgID: &l.OrgID, Entity: "moderation_case", EntityID: &caseID,
			Action: "moderation.decide", Diff: map[string]any{"kind": "listing", "listing_id": l.ID,
				"decision": decision, "note": note}}); err != nil {
			return err
		}
		if s.Outbox == nil {
			return nil
		}
		title := i18n(l.Title)
		// Statement of reasons to the reporter.
		if c.ReporterEmail != "" {
			locale := c.ReporterLocale
			if c.ReporterID != nil {
				if u, err := q.GetUser(ctx, *c.ReporterID); err == nil {
					locale = u.Locale
				}
			}
			m, err := s.Render.Render(notify.Email, c.ReporterEmail, locale, "listing_report_decided", map[string]any{
				"Name": c.ReporterName, "Title": titleIn(title, locale), "CaseID": caseID.String(),
				"Decision": label(decisionLabels, locale, decision), "Note": note})
			if err != nil {
				return err
			}
			if err := s.Outbox.Enqueue(ctx, tx, m); err != nil {
				return err
			}
		}
		if decision == "keep" {
			return nil
		}
		key := "listing_unpublished_report"
		if decision == "request_change" {
			key = "listing_change_requested_report"
		}
		owners, err := q.ListingOwnerRecipients(ctx, l.OrgID)
		if err != nil {
			return err
		}
		link := s.WebBaseURL + "/admin/orgs/" + l.OrgID.String() + "/listings/" + l.ID.String()
		for _, o := range owners {
			m, err := s.Render.Render(notify.Email, o.Email, o.Locale, key, map[string]any{
				"Title": titleIn(title, o.Locale), "CaseID": caseID.String(),
				"Reason": label(reasonLabels, o.Locale, c.Reason), "Note": note, "Link": link})
			if err != nil {
				return err
			}
			if err := s.Outbox.Enqueue(ctx, tx, m); err != nil {
				return err
			}
		}
		return nil
	})
}
