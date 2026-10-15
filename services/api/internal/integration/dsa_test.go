package integration

import (
	"context"
	"strings"
	"testing"

	"github.com/google/uuid"
)

// DSA notice-and-action (M8): anonymous and signed-in visitors report a
// listing, staff decide in the moderation queue, reporters get an
// acknowledgement and a statement of reasons, owners learn about an
// unpublish with reasons.
func TestListingReportsDSA(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("dsa")
	ownerEmail := e.emailOf(ownerTok)
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt DSA "+uuid.NewString()[:6], "approximate")
	rpath := "/v1/listings/" + listingID.String() + "/reports"
	explanation := "Inzerát požaduje platbu zálohy předem na cizí účet bez prohlídky."

	// Validation: anonymous reports need an e-mail; the explanation has a minimum length.
	var p problem
	if code := e.call("POST", rpath, "", map[string]any{"reason": "fraud", "explanation": explanation}, &p); code != 422 || p.Code != "reporter_email_required" {
		t.Fatalf("anonymous without e-mail: %d %+v", code, p)
	}
	if code := e.call("POST", rpath, "", map[string]any{"reason": "fraud", "explanation": "krátké", "email": "a@example.com"}, nil); code < 400 || code >= 500 {
		t.Fatalf("short explanation: %d", code)
	}
	if code := e.call("POST", rpath, "", map[string]any{"reason": "nonsense", "explanation": explanation, "email": "a@example.com"}, nil); code < 400 || code >= 500 {
		t.Fatalf("bad reason: %d", code)
	}
	if code := e.call("POST", "/v1/listings/"+uuid.NewString()+"/reports", "", map[string]any{"reason": "fraud",
		"explanation": explanation, "email": "a@example.com"}, nil); code != 404 {
		t.Fatalf("unknown listing: %d", code)
	}

	// Anonymous report: acknowledgement e-mail to the given address.
	anonEmail := uniqueEmail("dsa-anon")
	var anon struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", rpath, "", map[string]any{"reason": "fraud", "explanation": explanation, "email": anonEmail,
		"name": "Jana Nováková", "locale": "cs"}, &anon)
	ack, ok := e.outbox.Last(anonEmail, "listing_report_received")
	if !ok || !strings.Contains(ack.Text, anon.ID.String()) || !strings.Contains(ack.Text, "podvod") {
		t.Fatalf("acknowledgement %+v %v", ack, ok)
	}

	// Signed-in report: the account e-mail is used, a given e-mail is ignored.
	seekerEmail := uniqueEmail("dsa-seeker")
	seekerTok := e.register(seekerEmail)
	var signed struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", rpath, seekerTok, map[string]any{"reason": "wrong_info",
		"explanation": "Plocha bytu v inzerátu neodpovídá skutečnosti.", "email": "ignored@example.com"}, &signed)
	if _, ok := e.outbox.Last(seekerEmail, "listing_report_received"); !ok {
		t.Fatal("no acknowledgement to the signed-in reporter")
	}
	if _, ok := e.outbox.Last("ignored@example.com", "listing_report_received"); ok {
		t.Fatal("acknowledgement went to the body e-mail of a signed-in reporter")
	}

	// Staff see both in the moderation queue; owners do not.
	type caseDTO struct {
		ID                uuid.UUID  `json:"id"`
		Kind              string     `json:"kind"`
		ListingID         *uuid.UUID `json:"listing_id"`
		ConversationID    *uuid.UUID `json:"conversation_id"`
		Reason            string     `json:"reason"`
		Note              string     `json:"note"`
		ReporterEmail     string     `json:"reporter_email"`
		ReporterName      string     `json:"reporter_name"`
		ReporterAnonymous *bool      `json:"reporter_anonymous"`
		AiStatus          string     `json:"ai_status"`
	}
	if code := e.call("GET", "/v1/backoffice/moderation", ownerTok, nil, nil); code != 403 {
		t.Fatalf("owner sees moderation queue: %d", code)
	}
	var queue []caseDTO
	e.must(200, "GET", "/v1/backoffice/moderation", staff, nil, &queue)
	var anonCase, signedCase *caseDTO
	for i := range queue {
		switch queue[i].ID {
		case anon.ID:
			anonCase = &queue[i]
		case signed.ID:
			signedCase = &queue[i]
		}
	}
	if anonCase == nil || signedCase == nil {
		t.Fatalf("queue %+v", queue)
	}
	if anonCase.Kind != "listing" || anonCase.ListingID == nil || *anonCase.ListingID != listingID || anonCase.ConversationID != nil ||
		anonCase.Reason != "fraud" || anonCase.Note != explanation || !strings.EqualFold(anonCase.ReporterEmail, anonEmail) ||
		anonCase.ReporterName != "Jana Nováková" || anonCase.ReporterAnonymous == nil || !*anonCase.ReporterAnonymous ||
		anonCase.AiStatus != "disabled" {
		t.Fatalf("anonymous case %+v", anonCase)
	}
	if signedCase.ReporterAnonymous == nil || *signedCase.ReporterAnonymous || !strings.EqualFold(signedCase.ReporterEmail, seekerEmail) {
		t.Fatalf("signed-in case %+v", signedCase)
	}
	var detail struct {
		Case       caseDTO `json:"case"`
		Transcript []any   `json:"transcript"`
	}
	e.must(200, "GET", "/v1/backoffice/moderation/"+anon.ID.String(), staff, nil, &detail)
	if detail.Case.ID != anon.ID || len(detail.Transcript) != 0 {
		t.Fatalf("detail %+v", detail)
	}

	// Decisions are human and kind-specific; unpublish needs reasons.
	dpath := "/v1/backoffice/moderation/" + anon.ID.String() + "/decision"
	if code := e.call("POST", dpath, staff, map[string]string{"decision": "suspend_user"}, nil); code != 422 {
		t.Fatalf("conversation decision on a listing case: %d", code)
	}
	if code := e.call("POST", dpath, staff, map[string]string{"decision": "unpublish"}, &p); code != 422 || p.Code != "note_required" {
		t.Fatalf("unpublish without reasons: %d %+v", code, p)
	}
	if code := e.call("POST", dpath, ownerTok, map[string]string{"decision": "keep"}, nil); code != 403 {
		t.Fatalf("owner decided: %d", code)
	}
	// Still published until staff decide.
	e.must(200, "GET", "/v1/listings/"+listingID.String(), "", nil, nil)

	reasons := "Inzerát vyžaduje zálohu předem bez prohlídky, což odporuje podmínkám služby."
	e.must(204, "POST", dpath, staff, map[string]string{"decision": "unpublish", "note": reasons}, nil)
	if code := e.call("POST", dpath, staff, map[string]string{"decision": "keep"}, nil); code != 409 {
		t.Fatalf("decided twice: %d", code)
	}
	if code := e.call("GET", "/v1/listings/"+listingID.String(), "", nil, nil); code != 404 {
		t.Fatalf("unpublished listing is public: %d", code)
	}
	var status string
	if err := e.pool.QueryRow(context.Background(), "SELECT status FROM listings WHERE id = $1", listingID).Scan(&status); err != nil || status != "draft" {
		t.Fatalf("status %q %v", status, err)
	}
	dec, ok := e.outbox.Last(anonEmail, "listing_report_decided")
	if !ok || !strings.Contains(dec.Text, reasons) || !strings.Contains(dec.Text, anon.ID.String()) {
		t.Fatalf("statement of reasons to reporter %+v %v", dec, ok)
	}
	own, ok := e.outbox.Last(ownerEmail, "listing_unpublished_report")
	if !ok || !strings.Contains(own.Text, reasons) {
		t.Fatalf("owner notice %+v %v", own, ok)
	}

	// Keep: reporter gets the decision, the owner is not bothered.
	e.must(204, "POST", "/v1/backoffice/moderation/"+signed.ID.String()+"/decision", staff, map[string]string{"decision": "keep"}, nil)
	if _, ok := e.outbox.Last(seekerEmail, "listing_report_decided"); !ok {
		t.Fatal("no decision e-mail for keep")
	}
	if n := len(e.outbox.All(ownerEmail, "listing_change_requested_report")); n != 0 {
		t.Fatalf("owner change requests %d", n)
	}

	// Unpublished listings cannot be reported any more.
	if code := e.call("POST", rpath, "", map[string]any{"reason": "fraud", "explanation": explanation, "email": anonEmail}, nil); code != 404 {
		t.Fatalf("report on an unpublished listing: %d", code)
	}

	// Audit trail.
	var audits int
	if err := e.pool.QueryRow(context.Background(), `SELECT count(*) FROM audit_events
		WHERE (action = 'listing.reported' AND entity_id = $1)
		   OR (action = 'listing.unpublished_by_moderation' AND entity_id = $1)
		   OR (action = 'moderation.decide' AND entity_id = ANY($2))`,
		listingID, []uuid.UUID{anon.ID, signed.ID}).Scan(&audits); err != nil || audits != 5 {
		t.Fatalf("audit %d %v", audits, err)
	}
}
