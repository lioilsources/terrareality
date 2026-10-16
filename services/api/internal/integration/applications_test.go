package integration

import (
	"context"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/notify"
)

// bankID verifies the user's identity through the mock BankID provider.
func (e *env) bankID(tok, given, family string) {
	e.t.Helper()
	redirect := redirectBase + "identity"
	var start struct {
		AuthorizationURL string `json:"authorization_url"`
	}
	e.must(200, "POST", "/v1/me/identity/start", tok, map[string]string{"redirect_uri": redirect}, &start)
	code, state := e.followMock(start.AuthorizationURL, url.Values{"given_name": {given}, "family_name": {family},
		"birthdate": {"1995-03-02"}, "sub": {"bankid-" + uuid.NewString()}})
	e.must(200, "POST", "/v1/me/identity/callback", tok, map[string]string{"code": code, "state": state, "redirect_uri": redirect}, nil)
}

type appDTO struct {
	ID            uuid.UUID `json:"id"`
	Status        string    `json:"status"`
	RejectReason  *string   `json:"reject_reason"`
	HouseholdSize int       `json:"household_size"`
	ConsentNeeded bool      `json:"consent_needed"`
}

type appDetail struct {
	Application appDTO `json:"application"`
	Consents    []struct {
		ConsentedAt *time.Time `json:"consented_at"`
	} `json:"consents"`
	Slots []struct {
		ID     uuid.UUID `json:"id"`
		Booked int       `json:"booked"`
	} `json:"slots"`
	Booking *struct {
		ID uuid.UUID `json:"id"`
	} `json:"booking"`
}

// Acceptance M5: a group of three files one application with everyone's
// consent; the landlord picks it and the other applicants get an automatic
// answer; a viewing is booked.
func TestApplicationsAcceptance(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("app-owner")
	e.pushDevice(ownerTok)
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt pro tři "+uuid.NewString()[:6], "approximate")
	lpath := "/v1/orgs/" + orgID.String() + "/listings/" + listingID.String()

	// Three flatmates form a group: Anna invites Ben and Cyril, who join.
	emails := []string{uniqueEmail("anna"), uniqueEmail("ben"), uniqueEmail("cyril")}
	toks := make([]string, 3)
	for i, em := range emails {
		toks[i] = e.register(em)
	}
	// Groups match invitations by e-mail, so only confirmed addresses may
	// create, list invitations or join (B-2).
	if code := e.call("POST", "/v1/groups", toks[0], map[string]any{"name": "Unverified"}, nil); code != 403 {
		t.Fatalf("unverified creates a group: %d", code)
	}
	for _, em := range emails {
		e.verifyEmail(em)
	}
	e.pushDevice(toks[0])
	annaID := e.userID(toks[0])
	var g struct {
		ID      uuid.UUID `json:"id"`
		Members []struct {
			Joined bool `json:"joined"`
		} `json:"members"`
	}
	e.must(201, "POST", "/v1/groups", toks[0], map[string]any{"name": "Dejvice trio", "invite": emails[1:]}, &g)
	if len(g.Members) != 3 || !g.Members[0].Joined || g.Members[1].Joined {
		t.Fatalf("group %+v", g)
	}
	if _, ok := e.outbox.Last(emails[1], "group_invitation"); !ok {
		t.Fatal("no invitation e-mail")
	}
	gpath := "/v1/groups/" + g.ID.String()
	var groups []struct {
		ID     uuid.UUID `json:"id"`
		Joined bool      `json:"joined"`
	}
	e.must(200, "GET", "/v1/groups", toks[1], nil, &groups)
	if len(groups) != 1 || groups[0].Joined {
		t.Fatalf("invitee groups %+v", groups)
	}
	// An invitee cannot post before joining.
	if code := e.call("POST", gpath+"/messages", toks[1], map[string]string{"body": "ahoj"}, nil); code != 404 {
		t.Fatalf("invitee posted: %d", code)
	}
	e.must(204, "POST", gpath+"/join", toks[1], nil, nil)
	e.must(204, "POST", gpath+"/join", toks[2], nil, nil)
	e.must(201, "POST", gpath+"/messages", toks[1], map[string]string{"body": "Ten byt v Dejvicích vypadá dobře!"}, nil)
	stranger := e.register(uniqueEmail("stranger"))
	if code := e.call("GET", gpath, stranger, nil, nil); code != 404 {
		t.Fatalf("stranger sees group: %d", code)
	}

	// Anna applies for the group: pending until Ben and Cyril consent.
	var d appDetail
	e.must(201, "POST", "/v1/applications", toks[0], map[string]any{"listing_id": listingID, "group_id": g.ID,
		"message": "Jsme tři kamarádi, pracujeme v Praze 6 a hledáme byt dlouhodobě.", "duration_months": 24,
		"preferred_from": time.Now().AddDate(0, 1, 0).Format("2006-01-02")}, &d)
	appID := d.Application.ID
	apath := "/v1/applications/" + appID.String()
	if d.Application.Status != "pending_consent" || d.Application.HouseholdSize != 3 || len(d.Consents) != 3 {
		t.Fatalf("pending application %+v", d)
	}
	if _, ok := e.outbox.Last(emails[2], "application_consent"); !ok {
		t.Fatal("no consent request e-mail")
	}
	var list []appDTO
	e.must(200, "GET", lpath+"/applications", ownerTok, nil, &list)
	if len(list) != 0 {
		t.Fatalf("landlord sees unconsented application: %+v", list)
	}
	e.must(204, "POST", apath+"/consent", toks[1], nil, nil)
	if code := e.call("POST", apath+"/consent", toks[1], nil, nil); code != 409 {
		t.Fatalf("double consent: %d", code)
	}
	if code := e.call("POST", apath+"/consent", stranger, nil, nil); code != 404 {
		t.Fatalf("stranger consent: %d", code)
	}
	e.must(204, "POST", apath+"/consent", toks[2], nil, nil)
	e.must(200, "GET", apath, toks[2], nil, &d)
	if d.Application.Status != "submitted" {
		t.Fatalf("not submitted after all consents: %+v", d.Application)
	}
	ownerEmail := e.emailOf(ownerTok)
	if _, ok := e.outbox.Last(ownerEmail, "application_received"); !ok {
		t.Fatal("landlord not notified")
	}
	// The landlord's phone gets a push about the new application (admin
	// screens are on the web, so it is marked for the landlord audience).
	ownerID := e.userID(ownerTok)
	if ps := e.pusher.of(ownerID, notify.PushApplication); len(ps) != 1 || ps[0].Data["id"] != appID.String() ||
		ps[0].Data["audience"] != "landlord" || ps[0].Data["org_id"] != orgID.String() || ps[0].Title != "Nová žádost o nájem" {
		t.Fatalf("landlord application push %+v", ps)
	}
	if ps := e.pusher.of(annaID, notify.PushApplication); len(ps) != 0 {
		t.Fatalf("applicant pushed on submit %+v", ps)
	}

	// Two other applicants; one is verified with BankID and passes ISIR.
	solo := e.register(uniqueEmail("solo"))
	e.pushDevice(solo)
	e.bankID(solo, "Dana", "Dobrá")
	var pass struct {
		Insolvency string `json:"insolvency"`
	}
	e.must(200, "POST", "/v1/me/passport/insolvency-check", solo, nil, &pass)
	if pass.Insolvency != "clear" {
		t.Fatalf("isir %+v", pass)
	}
	var up struct {
		Key       string `json:"key"`
		UploadURL string `json:"upload_url"`
	}
	pdf := []byte("%PDF-1.4\n% income\n%%EOF\n")
	e.must(201, "POST", "/v1/me/passport/income", solo, map[string]any{"content_type": "application/pdf", "size_bytes": len(pdf)}, &up)
	if err := e.blob.Put(context.Background(), up.Key, "application/pdf", pdf); err != nil {
		t.Fatal(err)
	}
	e.must(200, "POST", "/v1/me/passport/income/complete", solo, map[string]string{"key": up.Key, "filename": "vyplatni-paska.pdf"}, nil)
	var soloApp appDetail
	e.must(201, "POST", "/v1/applications", solo, map[string]any{"listing_id": listingID, "message": "Dobrý den, mám zájem."}, &soloApp)
	unverified := e.register(uniqueEmail("unverified"))
	var otherApp appDetail
	e.must(201, "POST", "/v1/applications", unverified, map[string]any{"listing_id": listingID}, &otherApp)
	if code := e.call("POST", "/v1/applications", unverified, map[string]any{"listing_id": listingID}, nil); code != 409 {
		t.Fatalf("second open application: %d", code)
	}
	// A person without BankID cannot run the insolvency check.
	var p problem
	if code := e.call("POST", "/v1/me/passport/insolvency-check", unverified, nil, &p); code != 422 || p.Code != "identity_required" {
		t.Fatalf("isir without identity: %d %+v", code, p)
	}

	// AI summaries (mock) for all three submitted applications.
	e.appJobs.mu.Lock()
	ids := e.appJobs.summaries
	e.appJobs.mu.Unlock()
	if len(ids) != 3 {
		t.Fatalf("summary jobs %d", len(ids))
	}
	for _, id := range ids {
		if err := e.summary.Summarize(context.Background(), id, false); err != nil {
			t.Fatal(err)
		}
	}

	// The landlord's overview: verified applicant first, passport facts, summary.
	var applicants []struct {
		Application       appDTO `json:"application"`
		VerificationLevel string `json:"verification_level"`
		People            []struct {
			HasIncomeProof bool   `json:"has_income_proof"`
			Insolvency     string `json:"insolvency"`
		} `json:"people"`
		AiSummary *struct {
			Summary string `json:"summary"`
		} `json:"ai_summary"`
	}
	e.must(200, "GET", lpath+"/applications", ownerTok, nil, &applicants)
	if len(applicants) != 3 || applicants[0].Application.ID != soloApp.Application.ID || applicants[0].VerificationLevel != "identity" {
		t.Fatalf("order %+v", applicants)
	}
	if !applicants[0].People[0].HasIncomeProof || applicants[0].People[0].Insolvency != "clear" || applicants[0].AiSummary == nil {
		t.Fatalf("passport facts %+v", applicants[0])
	}
	for _, a := range applicants {
		if a.Application.ID == appID && (len(a.People) != 3 || !strings.Contains(a.AiSummary.Summary, "Skupina 3")) {
			t.Fatalf("group applicant %+v", a)
		}
	}
	if code := e.call("GET", lpath+"/applications", toks[0], nil, nil); code != 404 {
		t.Fatalf("seeker reads applicants: %d", code)
	}

	// Viewing: the landlord offers a slot for one, invites the group, Ben books.
	var slot struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", lpath+"/viewing-slots", ownerTok, map[string]any{"starts_at": time.Now().Add(72 * time.Hour).Format(time.RFC3339),
		"capacity": 1, "note": "Zvonek Novák"}, &slot)
	e.must(204, "POST", "/v1/orgs/"+orgID.String()+"/applications/"+appID.String()+"/decision", ownerTok, map[string]string{"action": "invite"}, nil)
	if _, ok := e.outbox.Last(emails[0], "application_invited"); !ok {
		t.Fatal("no invitation to viewing")
	}
	if ps := e.pusher.of(annaID, notify.PushApplication); len(ps) != 1 || ps[0].Data["id"] != appID.String() ||
		ps[0].Data["status"] != "invited" || ps[0].Link != "http://web.test/zadosti/"+appID.String() {
		t.Fatalf("invitation push %+v", ps)
	}
	e.must(200, "GET", apath, toks[1], nil, &d)
	if d.Application.Status != "invited" || len(d.Slots) != 1 {
		t.Fatalf("invited detail %+v", d)
	}
	e.must(201, "POST", apath+"/bookings", toks[1], map[string]any{"slot_id": slot.ID}, nil)
	if code := e.call("POST", "/v1/applications/"+soloApp.Application.ID.String()+"/bookings", solo, map[string]any{"slot_id": slot.ID}, &p); code != 409 || p.Code != "slot_full" {
		t.Fatalf("overbooked: %d %+v", code, p)
	}
	e.appJobs.mu.Lock()
	reminders := len(e.appJobs.reminders)
	e.appJobs.mu.Unlock()
	if reminders != 2 {
		t.Fatalf("reminders %d", reminders)
	}
	if _, ok := e.outbox.Last(ownerEmail, "viewing_booked"); !ok {
		t.Fatal("landlord not told about the booking")
	}
	var views []struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(200, "GET", "/v1/me/viewings", toks[2], nil, &views)
	if len(views) != 1 {
		t.Fatalf("group member viewings %+v", views)
	}

	// Rejecting needs a reason from the code list.
	if code := e.call("POST", "/v1/orgs/"+orgID.String()+"/applications/"+otherApp.Application.ID.String()+"/decision", ownerTok,
		map[string]string{"action": "reject"}, nil); code != 422 {
		t.Fatalf("reject without reason: %d", code)
	}
	// The landlord accepts the group: the others are answered automatically.
	e.must(204, "POST", "/v1/orgs/"+orgID.String()+"/applications/"+appID.String()+"/decision", ownerTok, map[string]string{"action": "accept"}, nil)
	e.must(200, "GET", apath, toks[0], nil, &d)
	if d.Application.Status != "accepted" {
		t.Fatalf("accepted %+v", d.Application)
	}
	for _, tk := range []string{solo, unverified} {
		var mine []appDTO
		e.must(200, "GET", "/v1/applications", tk, nil, &mine)
		if len(mine) != 1 || mine[0].Status != "rejected" || mine[0].RejectReason == nil || *mine[0].RejectReason != "other_applicant_chosen" {
			t.Fatalf("auto answer %+v", mine)
		}
	}
	m, ok := e.outbox.Last(e.emailOf(solo), "application_rejected")
	if !ok || !strings.Contains(m.Text, "vybral jiného zájemce") {
		t.Fatalf("auto rejection e-mail %+v", m)
	}
	if _, ok := e.outbox.Last(emails[2], "application_accepted"); !ok {
		t.Fatal("group member not told about acceptance")
	}
	if ps := e.pusher.of(annaID, notify.PushApplication); len(ps) != 2 || ps[1].Data["status"] != "accepted" || ps[1].Data["id"] != appID.String() {
		t.Fatalf("acceptance push %+v", ps)
	}
	if ps := e.pusher.of(e.userID(solo), notify.PushApplication); len(ps) != 1 || ps[0].Data["status"] != "rejected" ||
		ps[0].Data["id"] != soloApp.Application.ID.String() || !strings.Contains(ps[0].Body, "vybral jiného zájemce") {
		t.Fatalf("auto rejection push %+v", ps)
	}
}

func TestRoommateMatching(t *testing.T) {
	e := newEnv(t)
	var praha6 string
	if err := e.pool.QueryRow(context.Background(), "SELECT path::text FROM admin_units WHERE name = 'Praha 6' AND level = 3").Scan(&praha6); err != nil {
		t.Fatal(err)
	}
	a := e.register(uniqueEmail("rm-a"))
	b := e.register(uniqueEmail("rm-b"))
	c := e.register(uniqueEmail("rm-c"))
	tag := uuid.NewString()[:6]
	e.must(200, "PUT", "/v1/me/roommate-profile", a, map[string]any{"active": true, "admin_path": praha6, "budget_max": 1_000_000,
		"lifestyle": []string{"non_smoker", "quiet", "tidy"}, "has_room": false, "about": "Hledám klidné spolubydlení " + tag + ", tel. 777 123 456"}, nil)
	e.must(200, "PUT", "/v1/me/roommate-profile", b, map[string]any{"active": true, "admin_path": praha6, "budget_max": 950_000,
		"lifestyle": []string{"non_smoker", "quiet"}, "has_room": true, "about": "Mám volný pokoj " + tag}, nil)
	e.must(200, "PUT", "/v1/me/roommate-profile", c, map[string]any{"active": true, "admin_path": praha6, "budget_max": 1_000_000,
		"lifestyle": []string{"smoker", "social"}, "has_room": false, "about": "Party " + tag}, nil)
	var mine struct {
		About string `json:"about"`
	}
	e.must(200, "GET", "/v1/me/roommate-profile", a, nil, &mine)
	if strings.Contains(mine.About, "777") {
		t.Fatalf("contact not masked: %q", mine.About)
	}
	var matches []struct {
		UserID  uuid.UUID `json:"user_id"`
		Score   int       `json:"score"`
		Profile struct {
			About string `json:"about"`
		} `json:"profile"`
	}
	e.must(200, "GET", "/v1/roommates", a, nil, &matches)
	bi, ci := -1, -1
	for i, m := range matches {
		if strings.Contains(m.Profile.About, "Mám volný pokoj "+tag) {
			bi = i
		}
		if strings.Contains(m.Profile.About, "Party "+tag) {
			ci = i
		}
	}
	if bi < 0 || ci < 0 || matches[bi].Score <= matches[ci].Score {
		t.Fatalf("ranking b=%d c=%d %+v", bi, ci, matches)
	}
	if code := e.call("GET", "/v1/roommates", "", nil, nil); code != 401 {
		t.Fatalf("anonymous: %d", code)
	}
}
