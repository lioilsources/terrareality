package integration

import (
	"context"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/applications"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/search"
)

// verifiedUser registers a user with a confirmed e-mail address.
func (e *env) confirmedUser(prefix string) (string, string) {
	e.t.Helper()
	em := uniqueEmail(prefix)
	tok := e.register(em)
	e.verifyEmail(em)
	return tok, em
}

// together runs fns at the same moment and returns their status codes.
func together(fns ...func() int) []int {
	codes := make([]int, len(fns))
	var start, done sync.WaitGroup
	start.Add(1)
	for i, fn := range fns {
		done.Add(1)
		go func() {
			defer done.Done()
			start.Wait()
			codes[i] = fn()
		}()
	}
	start.Done()
	done.Wait()
	return codes
}

// V-7: two members consenting at the same time must still submit the
// application (the last consent sees all others).
func TestConcurrentConsentsSubmit(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("consent-owner")
	staff := e.staffToken()
	for round := 0; round < 3; round++ {
		listingID := e.publishFlat(ownerTok, orgID, staff, "Byt souhlasy "+uuid.NewString()[:6], "approximate")
		anna, _ := e.confirmedUser("anna")
		ben, benEmail := e.confirmedUser("ben")
		cyril, cyrilEmail := e.confirmedUser("cyril")
		var g struct {
			ID uuid.UUID `json:"id"`
		}
		e.must(201, "POST", "/v1/groups", anna, map[string]any{"name": "Trio", "invite": []string{benEmail, cyrilEmail}}, &g)
		e.must(204, "POST", "/v1/groups/"+g.ID.String()+"/join", ben, nil, nil)
		e.must(204, "POST", "/v1/groups/"+g.ID.String()+"/join", cyril, nil, nil)
		var d appDetail
		e.must(201, "POST", "/v1/applications", anna, map[string]any{"listing_id": listingID, "group_id": g.ID,
			"message": "Tři kamarádi hledají byt."}, &d)
		apath := "/v1/applications/" + d.Application.ID.String()
		codes := together(
			func() int { return e.call("POST", apath+"/consent", ben, nil, nil) },
			func() int { return e.call("POST", apath+"/consent", cyril, nil, nil) },
		)
		if codes[0] != 204 || codes[1] != 204 {
			t.Fatalf("round %d: consents %v", round, codes)
		}
		e.must(200, "GET", apath, anna, nil, &d)
		if d.Application.Status != "submitted" {
			t.Fatalf("round %d: stuck in %s after concurrent consents", round, d.Application.Status)
		}
	}
}

// S-D9: two concurrent accepts on one listing: exactly one wins.
func TestConcurrentAcceptOneWins(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("accept-owner")
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt přijetí "+uuid.NewString()[:6], "approximate")
	var ids [2]uuid.UUID
	for i := range ids {
		tok := e.register(uniqueEmail("applicant"))
		var d appDetail
		e.must(201, "POST", "/v1/applications", tok, map[string]any{"listing_id": listingID, "message": "Mám zájem."}, &d)
		ids[i] = d.Application.ID
	}
	decide := func(id uuid.UUID) func() int {
		return func() int {
			return e.call("POST", "/v1/orgs/"+orgID.String()+"/applications/"+id.String()+"/decision", ownerTok,
				map[string]string{"action": "accept"}, nil)
		}
	}
	codes := together(decide(ids[0]), decide(ids[1]))
	ok := 0
	for _, c := range codes {
		switch c {
		case 204:
			ok++
		case 409:
		default:
			t.Fatalf("decision status %v", codes)
		}
	}
	if ok != 1 {
		t.Fatalf("accepted %d applications: %v", ok, codes)
	}
	var accepted int
	if err := e.pool.QueryRow(context.Background(), "SELECT count(*) FROM applications WHERE listing_id = $1 AND status = 'accepted'",
		listingID).Scan(&accepted); err != nil || accepted != 1 {
		t.Fatalf("accepted rows %d %v", accepted, err)
	}
}

// V-8: income proofs are downloadable only for open applications, through a
// dedicated endpoint, as attachments, and every issued link is audited; the
// applicant list only says whether a proof exists.
func TestIncomeProofOnlyForOpenApplications(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("income-owner")
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt příjem "+uuid.NewString()[:6], "approximate")
	lpath := "/v1/orgs/" + orgID.String() + "/listings/" + listingID.String()
	tok := e.register(uniqueEmail("earner"))
	var up struct {
		Key string `json:"key"`
	}
	pdf := []byte("%PDF-1.4\n% income\n%%EOF\n")
	e.must(201, "POST", "/v1/me/passport/income", tok, map[string]any{"content_type": "application/pdf", "size_bytes": len(pdf)}, &up)
	if err := e.blob.Put(context.Background(), up.Key, "text/html", pdf); err != nil {
		t.Fatal(err)
	}
	e.must(200, "POST", "/v1/me/passport/income/complete", tok, map[string]string{"key": up.Key, "filename": "pasky.pdf"}, nil)
	var d appDetail
	e.must(201, "POST", "/v1/applications", tok, map[string]any{"listing_id": listingID}, &d)

	type applicant struct {
		People []struct {
			ID             uuid.UUID `json:"user_id"`
			HasIncomeProof bool      `json:"has_income_proof"`
			IncomeProofURL *string   `json:"income_proof_url"`
		} `json:"people"`
	}
	viewed := func(uid uuid.UUID) int {
		var n int
		if err := e.pool.QueryRow(context.Background(), "SELECT count(*) FROM audit_events WHERE action = 'passport.income_viewed' AND entity_id = $1 AND org_id = $2",
			uid, orgID).Scan(&n); err != nil {
			t.Fatal(err)
		}
		return n
	}
	var list []applicant
	e.must(200, "GET", lpath+"/applications", ownerTok, nil, &list)
	if len(list) != 1 || !list[0].People[0].HasIncomeProof || list[0].People[0].IncomeProofURL != nil {
		t.Fatalf("open application: %+v", list)
	}
	uid := list[0].People[0].ID
	if n := viewed(uid); n != 0 {
		t.Fatalf("listing applicants audited %d downloads", n)
	}
	ipath := "/v1/orgs/" + orgID.String() + "/applications/" + d.Application.ID.String() + "/people/" + uid.String() + "/income-proof"
	var link struct {
		URL       string    `json:"url"`
		Filename  string    `json:"filename"`
		ExpiresAt time.Time `json:"expires_at"`
	}
	e.must(200, "GET", ipath, ownerTok, nil, &link)
	u, err := url.Parse(link.URL)
	if err != nil || !strings.HasPrefix(u.Query().Get("response-content-disposition"), "attachment") ||
		u.Query().Get("response-content-type") != "application/octet-stream" {
		t.Fatalf("income link renders inline: %s", link.URL)
	}
	if link.Filename != "pasky.pdf" || time.Until(link.ExpiresAt) > applications.IncomeProofTTL+time.Minute {
		t.Fatalf("link %+v", link)
	}
	e.must(200, "GET", ipath, ownerTok, nil, &link)
	if n := viewed(uid); n != 2 {
		t.Fatalf("income view audit %d, want one per download", n)
	}
	// The applicant is not a member of the landlord's organization.
	var p problem
	if code := e.call("GET", ipath, tok, nil, &p); code != 403 && code != 404 {
		t.Fatalf("applicant downloads through the landlord endpoint: %d", code)
	}
	e.must(204, "POST", "/v1/orgs/"+orgID.String()+"/applications/"+d.Application.ID.String()+"/decision", ownerTok,
		map[string]string{"action": "reject", "reason": "incomplete"}, nil)
	list = nil
	e.must(200, "GET", lpath+"/applications", ownerTok, nil, &list)
	if len(list) != 1 || list[0].People[0].HasIncomeProof {
		t.Fatalf("rejected applicant's income still offered: %+v", list)
	}
	if code := e.call("GET", ipath, ownerTok, nil, &p); code != 404 || p.Code != "income_proof_not_found" {
		t.Fatalf("rejected applicant's income downloadable: %d %+v", code, p)
	}
}

// S-D4: deleting an upcoming slot with bookings cancels them and tells every
// booked applicant (e-mail, in-app notification, push) in the same change.
func TestDeleteBookedSlot(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("slot-owner")
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt prohlídka "+uuid.NewString()[:6], "approximate")
	lpath := "/v1/orgs/" + orgID.String() + "/listings/" + listingID.String()
	viewerEmail := uniqueEmail("viewer")
	tok := e.register(viewerEmail)
	e.pushDevice(tok)
	var me struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(200, "GET", "/v1/me", tok, nil, &me)
	var d appDetail
	e.must(201, "POST", "/v1/applications", tok, map[string]any{"listing_id": listingID}, &d)
	var slot struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", lpath+"/viewing-slots", ownerTok, map[string]any{"starts_at": time.Now().Add(48 * time.Hour).Format(time.RFC3339),
		"capacity": 2}, &slot)
	var booking struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", "/v1/applications/"+d.Application.ID.String()+"/bookings", tok, map[string]any{"slot_id": slot.ID}, &booking)
	spath := "/v1/orgs/" + orgID.String() + "/viewing-slots/" + slot.ID.String()
	// Someone outside the organization cannot delete it.
	var p problem
	if code := e.call("DELETE", spath, tok, nil, &p); code != 403 && code != 404 {
		t.Fatalf("applicant deleted the slot: %d %+v", code, p)
	}
	pushesBefore := len(e.pusher.of(me.ID, "application"))
	e.must(204, "DELETE", spath, ownerTok, nil, nil)
	if n := len(e.outbox.All(viewerEmail, "viewing_cancelled")); n != 1 {
		t.Fatalf("viewing_cancelled e-mails: %d", n)
	}
	if got := e.pusher.of(me.ID, "application"); len(got) != pushesBefore+1 || got[len(got)-1].Title != "Prohlídka byla zrušena" {
		t.Fatalf("viewing_cancelled push: %+v", got)
	}
	var notified int
	if err := e.pool.QueryRow(context.Background(), "SELECT count(*) FROM notifications WHERE user_id = $1 AND kind = 'viewing_cancelled'",
		me.ID).Scan(&notified); err != nil || notified != 1 {
		t.Fatalf("in-app notification %d %v", notified, err)
	}
	var detail appDetail
	e.must(200, "GET", "/v1/applications/"+d.Application.ID.String(), tok, nil, &detail)
	if detail.Booking != nil {
		t.Fatalf("booking survived its slot: %+v", detail.Booking)
	}
	if code := e.call("DELETE", spath, ownerTok, nil, &p); code != 404 || p.Code != "slot_not_found" {
		t.Fatalf("second delete: %d %+v", code, p)
	}
}

// B-2: an unconfirmed registration with an invitee's address neither sees
// nor joins the group; after confirming the address it can.
func TestGroupInvitationNeedsVerifiedEmail(t *testing.T) {
	e := newEnv(t)
	anna, _ := e.confirmedUser("anna")
	inviteeEmail := uniqueEmail("invitee")
	var g struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", "/v1/groups", anna, map[string]any{"name": "Dvojice", "invite": []string{inviteeEmail}}, &g)
	squatter := e.register(inviteeEmail)
	var groups []struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(200, "GET", "/v1/groups", squatter, nil, &groups)
	if len(groups) != 0 {
		t.Fatalf("unverified sees invitations: %+v", groups)
	}
	if code := e.call("POST", "/v1/groups/"+g.ID.String()+"/join", squatter, nil, nil); code != 403 {
		t.Fatalf("unverified joined: %d", code)
	}
	if code := e.call("POST", "/v1/groups/"+g.ID.String()+"/invitations", squatter, map[string]string{"email": "x@example.com"}, nil); code == 201 || code == 204 {
		t.Fatalf("unverified invited: %d", code)
	}
	e.verifyEmail(inviteeEmail)
	e.must(200, "GET", "/v1/groups", squatter, nil, &groups)
	if len(groups) != 1 || groups[0].ID != g.ID {
		t.Fatalf("verified invitee groups %+v", groups)
	}
	e.must(204, "POST", "/v1/groups/"+g.ID.String()+"/join", squatter, nil, nil)
}

// S-D5: invitations per person and day are capped.
func TestGroupInvitationDailyCap(t *testing.T) {
	e := newEnv(t)
	anna, _ := e.confirmedUser("spammer")
	annaID := e.userID(anna)
	var g struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", "/v1/groups", anna, map[string]any{"name": "Spam"}, &g)
	if _, err := e.pool.Exec(context.Background(), `INSERT INTO audit_events (actor_id, entity, entity_id, action)
		SELECT $1, 'tenant_group', $2, 'group.invite' FROM generate_series(1, $3::int)`, annaID, g.ID, applications.MaxInvitesPerDay); err != nil {
		t.Fatal(err)
	}
	if code := e.call("POST", "/v1/groups/"+g.ID.String()+"/invitations", anna, map[string]string{"email": uniqueEmail("victim")}, nil); code != 429 {
		t.Fatalf("invitation over the daily cap: %d", code)
	}
}

// S-D2: editing a listing under review withdraws the pending version, so
// staff cannot approve the old snapshot.
func TestEditWithdrawsPendingVersion(t *testing.T) {
	e := newEnv(t)
	tok, orgID := e.ownerOrg("editor")
	staff := e.staffToken()
	var addrs []struct {
		RuianID int64 `json:"ruian_id"`
	}
	e.must(200, "GET", "/v1/addresses/search?q=dejvicka", "", nil, &addrs)
	var l listingDTO
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/listings", tok, map[string]any{"ruian_id": addrs[0].RuianID, "unit_kind": "apartment",
		"layout": "2+kk", "floor_area": 54}, &l)
	path := "/v1/orgs/" + orgID.String() + "/listings/" + l.ID.String()
	body := map[string]any{"title": map[string]string{"cs": "Byt ke kontrole", "en": ""},
		"description": map[string]string{"cs": strings.Repeat("Světlý byt se zahrádkou a výhledem do parku. ", 2), "en": ""},
		"rent_amount": 1_750_000, "attributes": l.Attributes, "location_precision": "approximate"}
	e.must(200, "PUT", path, tok, body, nil)
	e.uploadPhoto(tok, orgID, l.ID, "a.jpg")
	e.must(200, "POST", path+"/submit", tok, nil, nil)
	body["rent_amount"] = 1_950_000
	e.must(200, "PUT", path, tok, body, nil)
	e.must(200, "GET", path, tok, nil, &l)
	if l.Status != "draft" || len(l.Versions) != 1 || l.Versions[0].Status != "withdrawn" {
		t.Fatalf("after edit: status %s versions %+v", l.Status, l.Versions)
	}
	var queue []struct {
		ListingID uuid.UUID `json:"listing_id"`
	}
	e.must(200, "GET", "/v1/backoffice/reviews", staff, nil, &queue)
	for _, q := range queue {
		if q.ListingID == l.ID {
			t.Fatal("stale version still in the review queue")
		}
	}
}

// S-D3: malformed filters answer 400, never 500.
func TestSearchRejectsInvalidFilters(t *testing.T) {
	e := newEnv(t)
	for name, q := range map[string]map[string]any{
		"admin path": {"admin_path": "cz.praha'; --"},
		"bbox":       {"bbox": []float64{15, 50, 14, 51}},
		"numeric":    {"attributes": map[string]any{"balcony": map[string]any{"min": 1}}},
	} {
		// 400 either from the contract validator or from Query.Validate.
		var p problem
		if code := e.call("POST", "/v1/search", "", q, &p); code != 400 {
			t.Errorf("%s: %d %+v", name, code, p)
		}
	}
	e.must(200, "POST", "/v1/search", "", map[string]any{"attributes": map[string]any{"floor": map[string]any{"min": 1, "max": 3}}}, nil)
	tok := e.register(uniqueEmail("saver"))
	var p problem
	if code := e.call("POST", "/v1/me/saved-searches", tok, map[string]any{"name": "Bad", "query": map[string]any{"admin_path": "a..b"}}, &p); code != 400 {
		t.Fatalf("invalid saved search stored: %d %+v", code, p)
	}
}

// N: the digest announces a listing once, on its first publication, not
// again after an approved edit bumps published_at.
func TestDigestIgnoresRepublishedListings(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("digest-owner")
	staff := e.staffToken()
	unique := "digestbyt" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
	id := e.publishFlat(ownerTok, orgID, staff, "Byt "+unique, "approximate")
	// The listing was first published a week ago.
	if _, err := e.pool.Exec(context.Background(), "UPDATE listings SET first_published_at = now() - interval '7 days' WHERE id = $1", id); err != nil {
		t.Fatal(err)
	}
	tok := e.register(uniqueEmail("digest"))
	var saved struct{ ID uuid.UUID }
	e.must(201, "POST", "/v1/me/saved-searches", tok, map[string]any{"name": "Digest", "query": map[string]any{"text": unique}}, &saved)
	if _, err := e.pool.Exec(context.Background(), "UPDATE saved_searches SET last_notified_at = now() - interval '2 days' WHERE id = $1", saved.ID); err != nil {
		t.Fatal(err)
	}
	// An approved edit today bumps listings.published_at and the index.
	if _, err := e.pool.Exec(context.Background(), "UPDATE listing_search SET published_at = now() WHERE listing_id = $1", id); err != nil {
		t.Fatal(err)
	}
	digest := &search.Digest{Engine: &search.Engine{Pool: e.pool}, Outbox: e.outbox, Render: e.acct.Render, WebBaseURL: "http://web.test"}
	if _, err := digest.Run(context.Background()); err != nil {
		t.Fatal(err)
	}
	if m, ok := e.outbox.Last(e.emailOf(tok), "saved_search_digest"); ok {
		t.Fatalf("republished listing announced as new: %+v", m)
	}
}

// N: unblocking an organization's block is not tied to the person who set
// it; a report without a message names the organization's last writer.
func TestBlockAndReportOnOrganizationSide(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("block-owner")
	ownerID := e.userID(ownerTok)
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt blok "+uuid.NewString()[:6], "approximate")
	colleague, _ := e.confirmedUser("colleague")
	if _, err := e.pool.Exec(context.Background(), "INSERT INTO memberships (org_id, user_id, role) VALUES ($1, $2, 'agent')",
		orgID, e.userID(colleague)); err != nil {
		t.Fatal(err)
	}
	seeker := e.register(uniqueEmail("seeker"))
	var sent sentDTO
	e.must(201, "POST", "/v1/conversations", seeker, map[string]any{"listing_id": listingID, "body": "Dobrý den, mám zájem."}, &sent)
	cpath := "/v1/conversations/" + sent.ConversationID.String()
	e.must(201, "POST", cpath+"/messages", ownerTok, map[string]string{"body": "Dobrý den, kdy se vám hodí prohlídka?"}, nil)

	var rep struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", cpath+"/reports", seeker, map[string]any{"reason": "harassment"}, &rep)
	var reported *uuid.UUID
	if err := e.pool.QueryRow(context.Background(), "SELECT reported_id FROM moderation_cases WHERE id = $1", rep.ID).Scan(&reported); err != nil {
		t.Fatal(err)
	}
	if reported == nil || *reported != ownerID {
		t.Fatalf("reported %v, want the owner %s", reported, ownerID)
	}

	e.must(204, "PUT", cpath+"/block", ownerTok, map[string]bool{"blocked": true}, nil)
	if code := e.call("PUT", cpath+"/block", seeker, map[string]bool{"blocked": false}, nil); code != 403 {
		t.Fatalf("seeker lifted the organization's block: %d", code)
	}
	e.must(204, "PUT", cpath+"/block", colleague, map[string]bool{"blocked": false}, nil)
}

// N: a message notification job retried after a partial failure counts the
// message once and does not e-mail twice.
func TestMessageNotificationIdempotent(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("idem-owner")
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt notifikace "+uuid.NewString()[:6], "approximate")
	ownerEmail := e.emailOf(ownerTok)
	seeker := e.register(uniqueEmail("seeker"))
	e.must(201, "POST", "/v1/conversations", seeker, map[string]any{"listing_id": listingID, "body": "Dobrý den, mám zájem."}, nil)
	e.msgJobs.mu.Lock()
	ids := append([]uuid.UUID(nil), e.msgJobs.messages...)
	e.msgJobs.messages = nil
	e.msgJobs.mu.Unlock()
	if len(ids) != 1 {
		t.Fatalf("jobs %v", ids)
	}
	for range 2 { // the retry
		if err := e.notifier.MessageCreated(context.Background(), ids[0]); err != nil {
			t.Fatal(err)
		}
	}
	var count int
	if err := e.pool.QueryRow(context.Background(), `SELECT coalesce(sum((data->>'count')::int), 0) FROM notifications n
		JOIN users u ON u.id = n.user_id WHERE u.email = $1 AND n.kind = 'message'`, ownerEmail).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("message counted %d times", count)
	}
	if n := len(e.outbox.All(ownerEmail, "new_message")); n != 1 {
		t.Fatalf("new_message e-mails %d", n)
	}
}

// N: a viewing reminder job retried after the e-mails were committed sends
// nothing twice.
func TestViewingReminderIdempotent(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("remind-owner")
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt připomínka "+uuid.NewString()[:6], "approximate")
	lpath := "/v1/orgs/" + orgID.String() + "/listings/" + listingID.String()
	em := uniqueEmail("reminded")
	tok := e.register(em)
	var d appDetail
	e.must(201, "POST", "/v1/applications", tok, map[string]any{"listing_id": listingID}, &d)
	var slot struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", lpath+"/viewing-slots", ownerTok, map[string]any{"starts_at": time.Now().Add(30 * time.Hour).Format(time.RFC3339)}, &slot)
	var booking struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", "/v1/applications/"+d.Application.ID.String()+"/bookings", tok, map[string]any{"slot_id": slot.ID}, &booking)
	render, err := notify.NewRenderer()
	if err != nil {
		t.Fatal(err)
	}
	r := &applications.Reminders{Pool: e.svc, Outbox: e.outbox, Render: render, WebBaseURL: "http://web.test"}
	for range 2 {
		if err := r.Remind(context.Background(), booking.ID); err != nil {
			t.Fatal(err)
		}
	}
	if n := len(e.outbox.All(em, "viewing_reminder")); n != 1 {
		t.Fatalf("reminders sent %d", n)
	}
}

// N: photos kept for a published version are deleted once no published or
// pending version shows them.
func TestOrphanPhotoCleanup(t *testing.T) {
	e := newEnv(t)
	tok, orgID := e.ownerOrg("cleanup")
	staff := e.staffToken()
	listingID := e.publishFlat(tok, orgID, staff, "Byt úklid "+uuid.NewString()[:6], "approximate")
	path := "/v1/orgs/" + orgID.String() + "/listings/" + listingID.String()
	var l listingDTO
	e.must(200, "GET", path, tok, nil, &l)
	old := l.Media[0].ID
	key := "orgs/" + orgID.String() + "/media/" + old.String() + "/original"
	e.uploadPhoto(tok, orgID, listingID, "b.jpg")
	e.must(204, "DELETE", "/v1/orgs/"+orgID.String()+"/media/"+old.String(), tok, nil, nil)
	backdate := func() {
		if _, err := e.pool.Exec(context.Background(), "UPDATE audit_events SET occurred_at = now() - interval '2 hours' WHERE action = 'media.deleted' AND entity_id = $1", old); err != nil {
			t.Fatal(err)
		}
	}
	backdate()
	// Still shown by the published version: kept.
	if _, err := e.listings.CleanupMediaBlobs(context.Background()); err != nil {
		t.Fatal(err)
	}
	if _, err := e.blob.Get(context.Background(), key); err != nil {
		t.Fatalf("published photo deleted: %v", err)
	}
	// A new version without the photo is approved: now it goes.
	e.must(200, "POST", path+"/submit", tok, nil, nil)
	var queue []struct {
		VersionID uuid.UUID `json:"version_id"`
		ListingID uuid.UUID `json:"listing_id"`
	}
	e.must(200, "GET", "/v1/backoffice/reviews", staff, nil, &queue)
	for _, q := range queue {
		if q.ListingID == listingID {
			e.must(204, "POST", "/v1/backoffice/reviews/"+q.VersionID.String()+"/decision", staff, map[string]any{"approve": true}, nil)
		}
	}
	n, err := e.listings.CleanupMediaBlobs(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := e.blob.Get(context.Background(), key); err == nil || n < 1 {
		t.Fatalf("orphan photo kept (deleted %d)", n)
	}
}
