package integration

import (
	"context"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/realtime"
)

type msgDTO struct {
	ID          uuid.UUID  `json:"id"`
	SenderID    *uuid.UUID `json:"sender_id"`
	Body        string     `json:"body"`
	Flags       []string   `json:"flags"`
	Removed     bool       `json:"removed"`
	Attachments []struct {
		ID       uuid.UUID `json:"id"`
		Filename string    `json:"filename"`
		URL      string    `json:"url"`
	} `json:"attachments"`
}

type sentDTO struct {
	ConversationID uuid.UUID `json:"conversation_id"`
	Message        msgDTO    `json:"message"`
}

type convDTO struct {
	ID          uuid.UUID `json:"id"`
	Role        string    `json:"role"`
	OrgName     string    `json:"org_name"`
	SeekerName  string    `json:"seeker_name"`
	Unread      int       `json:"unread"`
	LastMessage string    `json:"last_message"`
	Blocked     bool      `json:"blocked"`
	BlockedByMe bool      `json:"blocked_by_me"`
	Title       struct {
		Cs string `json:"cs"`
	} `json:"listing_title"`
}

func (e *env) userID(tok string) uuid.UUID {
	var m struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(200, "GET", "/v1/me", tok, nil, &m)
	return m.ID
}

// runNotify works the queued message_notify jobs.
func (e *env) runNotify() {
	e.t.Helper()
	e.msgJobs.mu.Lock()
	ids := e.msgJobs.messages
	e.msgJobs.messages = nil
	e.msgJobs.mu.Unlock()
	for _, id := range ids {
		if err := e.notifier.MessageCreated(context.Background(), id); err != nil {
			e.t.Fatal(err)
		}
	}
}

func (e *env) runVerdicts() {
	e.t.Helper()
	e.msgJobs.mu.Lock()
	ids := e.msgJobs.cases
	e.msgJobs.cases = nil
	e.msgJobs.mu.Unlock()
	for _, id := range ids {
		if err := e.verdicts.Suggest(context.Background(), id, false); err != nil {
			e.t.Fatal(err)
		}
	}
}

// Acceptance M4: messages reach the other side in realtime, offline
// recipients get push and e-mail, reported conversations show up in the
// backoffice with an AI suggestion and staff decide.
func TestMessagingAcceptance(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("landlord")
	ownerID := e.userID(ownerTok)
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt k pronájmu "+uuid.NewString()[:6], "approximate")
	lpath := "/v1/orgs/" + orgID.String() + "/listings/" + listingID.String()

	// Pre-screening questions are public on the listing.
	var qs []struct {
		ID   string `json:"id"`
		Kind string `json:"kind"`
	}
	e.must(200, "PUT", lpath+"/prescreen", ownerTok, []map[string]any{
		{"text": map[string]string{"cs": "Máte domácí zvíře?"}, "kind": "yes_no", "required": true},
		{"text": map[string]string{"cs": "Kolik osob bude bydlet?"}, "kind": "number", "required": false},
	}, &qs)
	if len(qs) != 2 || qs[0].ID == "" || qs[0].ID == qs[1].ID {
		t.Fatalf("prescreen %+v", qs)
	}
	var pub struct {
		Prescreen []struct{ ID string } `json:"prescreen"`
	}
	e.must(200, "GET", "/v1/listings/"+listingID.String(), "", nil, &pub)
	if len(pub.Prescreen) != 2 {
		t.Fatalf("public prescreen %+v", pub)
	}

	seekerEmail := uniqueEmail("seeker")
	seekerTok := e.register(seekerEmail)
	seekerID := e.userID(seekerTok)

	// Required answers are enforced; contacts are masked, not blocked.
	var p problem
	if code := e.call("POST", "/v1/conversations", seekerTok, map[string]any{"listing_id": listingID, "body": "Dobrý den"}, &p); code != 422 || p.Code != "prescreen_incomplete" {
		t.Fatalf("missing answers: %d %+v", code, p)
	}
	var sent sentDTO
	e.must(201, "POST", "/v1/conversations", seekerTok, map[string]any{"listing_id": listingID,
		"body": "Dobrý den, mám zájem o prohlídku. Volejte na +420 777 123 456.", "prescreen_answers": map[string]string{qs[0].ID: "no", qs[1].ID: "2"}}, &sent)
	convID := sent.ConversationID
	cpath := "/v1/conversations/" + convID.String()
	if !strings.Contains(sent.Message.Body, "[•••]") || strings.Contains(sent.Message.Body, "777") ||
		!slices.Contains(sent.Message.Flags, "contact_phone") {
		t.Fatalf("masking %+v", sent.Message)
	}
	// The owner cannot message their own listing.
	if code := e.call("POST", "/v1/conversations", ownerTok, map[string]any{"listing_id": listingID, "body": "x",
		"prescreen_answers": map[string]string{qs[0].ID: "no"}}, &p); code != 409 {
		t.Fatalf("own listing: %d", code)
	}

	// Realtime: the conversation channel and the owner's user channel got it.
	if len(e.rt.Events(realtime.ConversationChannel(convID))) != 1 || len(e.rt.Events(realtime.UserChannel(ownerID))) != 1 {
		t.Fatalf("realtime events %v", e.rt.Events(realtime.UserChannel(ownerID)))
	}
	var tok struct {
		Channel string `json:"channel"`
		Token   string `json:"token"`
	}
	e.must(200, "POST", cpath+"/realtime-token", ownerTok, nil, &tok)
	if tok.Channel != realtime.ConversationChannel(convID) || tok.Token == "" {
		t.Fatalf("subscription token %+v", tok)
	}

	// Owner inbox shows the unread conversation with pre-screening answers.
	var inbox []convDTO
	e.must(200, "GET", "/v1/conversations?org_id="+orgID.String(), ownerTok, nil, &inbox)
	if len(inbox) != 1 || inbox[0].ID != convID || inbox[0].Unread != 1 || inbox[0].Role != "owner" {
		t.Fatalf("owner inbox %+v", inbox)
	}
	var detail struct {
		Conversation convDTO `json:"conversation"`
		PeerReadAt   *time.Time `json:"peer_read_at"`
		Prescreen    []struct {
			Answer string `json:"answer"`
		} `json:"prescreen"`
	}
	e.must(200, "GET", cpath, ownerTok, nil, &detail)
	if len(detail.Prescreen) != 2 || detail.Prescreen[0].Answer != "no" {
		t.Fatalf("detail %+v", detail)
	}

	// Strangers see nothing (row-level security).
	stranger := e.register(uniqueEmail("stranger"))
	if code := e.call("GET", cpath+"/messages", stranger, nil, nil); code != 404 {
		t.Fatalf("stranger read: %d", code)
	}
	if code := e.call("POST", cpath+"/messages", stranger, map[string]string{"body": "hi"}, nil); code != 404 {
		t.Fatalf("stranger send: %d", code)
	}

	// The owner is offline with a registered phone: push, in-app and one e-mail.
	e.must(201, "POST", "/v1/me/push-devices", ownerTok, map[string]string{"platform": "fcm", "token": "fcm-" + uuid.NewString(), "label": "Pixel"}, nil)
	e.runNotify()
	if e.pusher.count(ownerID) != 1 {
		t.Fatalf("pushes %+v", e.pusher.items)
	}
	ownerEmail := e.emailOf(ownerTok)
	if m, ok := e.outbox.Last(ownerEmail, "new_message"); !ok || !strings.Contains(m.Text, "/zpravy/"+convID.String()) {
		t.Fatalf("new_message e-mail %+v", m)
	}
	var notes struct {
		Items []struct {
			Data map[string]any `json:"data"`
		} `json:"items"`
		Unread int `json:"unread"`
	}
	e.must(200, "GET", "/v1/me/notifications", ownerTok, nil, &notes)
	if notes.Unread != 1 {
		t.Fatalf("notifications %+v", notes)
	}

	// A second unread message pushes again but does not send another e-mail.
	e.must(201, "POST", cpath+"/messages", seekerTok, map[string]string{"body": "Ještě dotaz: je možné parkování?"}, nil)
	before := len(e.outbox.All(ownerEmail, "new_message"))
	e.runNotify()
	if e.pusher.count(ownerID) != 2 || len(e.outbox.All(ownerEmail, "new_message")) != before {
		t.Fatalf("second message: pushes %d, e-mails %d", e.pusher.count(ownerID), len(e.outbox.All(ownerEmail, "new_message")))
	}
	e.must(200, "GET", "/v1/me/notifications", ownerTok, nil, &notes)
	if notes.Unread != 1 || notes.Items[0].Data["count"] != float64(2) {
		t.Fatalf("bumped notification %+v", notes)
	}

	// Reading clears the notification and shows a read receipt to the seeker.
	e.must(204, "POST", cpath+"/read", ownerTok, nil, nil)
	e.must(200, "GET", "/v1/me/notifications", ownerTok, nil, &notes)
	e.must(200, "GET", cpath, seekerTok, nil, &detail)
	if notes.Unread != 0 || detail.PeerReadAt == nil {
		t.Fatalf("read receipt: unread %d, peer %v", notes.Unread, detail.PeerReadAt)
	}

	// Reply from a template; the seeker is online, so no push or e-mail.
	var tpl struct {
		ID   uuid.UUID `json:"id"`
		Body string    `json:"body"`
	}
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/reply-templates", ownerTok, map[string]string{"title": "Prohlídka",
		"body": "Dobrý den, prohlídky děláme v úterý a ve čtvrtek odpoledne."}, &tpl)
	e.rt.SetOnline(realtime.UserChannel(seekerID), true)
	e.must(201, "POST", cpath+"/messages", ownerTok, map[string]string{"body": tpl.Body}, nil)
	e.runNotify()
	if e.pusher.count(seekerID) != 0 {
		t.Fatal("online seeker got a push")
	}
	if _, ok := e.outbox.Last(seekerEmail, "new_message"); ok {
		t.Fatal("online seeker got an e-mail")
	}
	e.rt.SetOnline(realtime.UserChannel(seekerID), false)

	// Attachment: reserve, upload, complete, send.
	pdf := []byte("%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF\n")
	var up struct {
		ID        uuid.UUID `json:"id"`
		UploadURL string    `json:"upload_url"`
	}
	e.must(201, "POST", cpath+"/attachments", seekerTok, map[string]any{"filename": "potvrzeni-prijmu.pdf",
		"content_type": "application/pdf", "size_bytes": len(pdf)}, &up)
	if code := e.call("POST", cpath+"/messages", seekerTok, map[string]any{"attachment_ids": []uuid.UUID{up.ID}}, &p); code != 422 {
		t.Fatalf("unscanned attachment accepted: %d", code)
	}
	key := up.UploadURL[len("http://blob.test/"):strings.Index(up.UploadURL, "?")]
	if err := e.blob.Put(context.Background(), key, "application/pdf", pdf); err != nil {
		t.Fatal(err)
	}
	e.must(200, "POST", "/v1/attachments/"+up.ID.String()+"/complete", seekerTok, nil, nil)
	e.must(201, "POST", cpath+"/messages", seekerTok, map[string]any{"body": "Posílám potvrzení příjmu.",
		"attachment_ids": []uuid.UUID{up.ID}}, &sent)
	var msgs []msgDTO
	e.must(200, "GET", cpath+"/messages", ownerTok, nil, &msgs)
	if len(msgs) != 4 || len(msgs[0].Attachments) != 1 || msgs[0].Attachments[0].Filename != "potvrzeni-prijmu.pdf" {
		t.Fatalf("messages %+v", msgs)
	}

	// A scam message is flagged automatically and gets an AI suggestion.
	e.must(201, "POST", cpath+"/messages", ownerTok, map[string]string{"body": "Jsem v zahraničí, pošlete prosím zálohu předem a klíče vám zašlu kurýrem."}, &sent)
	scamID := sent.Message.ID
	if !slices.Contains(sent.Message.Flags, "advance_payment") {
		t.Fatalf("advance payment not flagged: %+v", sent.Message)
	}
	// The seeker reports the conversation too.
	var rep struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", cpath+"/reports", seekerTok, map[string]any{"reason": "scam", "message_id": scamID, "note": "Chce peníze předem"}, &rep)
	if code := e.call("POST", cpath+"/reports", seekerTok, map[string]any{"reason": "scam", "message_id": sent.Message.ID}, nil); code != 201 {
		t.Fatalf("second report: %d", code)
	}
	e.runVerdicts()

	type caseDTO struct {
		ID           uuid.UUID `json:"id"`
		Source       string    `json:"source"`
		AiStatus     string    `json:"ai_status"`
		AiSuggestion *struct {
			Verdict string `json:"verdict"`
		} `json:"ai_suggestion"`
		ReportedID *uuid.UUID `json:"reported_id"`
	}
	var queue []caseDTO
	if code := e.call("GET", "/v1/backoffice/moderation", ownerTok, nil, nil); code != 403 {
		t.Fatalf("owner sees moderation queue: %d", code)
	}
	e.must(200, "GET", "/v1/backoffice/moderation", staff, nil, &queue)
	var auto, report *caseDTO
	for i := range queue {
		switch {
		case queue[i].Source == "auto" && queue[i].ReportedID != nil && *queue[i].ReportedID == ownerID:
			auto = &queue[i]
		case queue[i].ID == rep.ID:
			report = &queue[i]
		}
	}
	if auto == nil || report == nil || report.AiStatus != "ready" || report.AiSuggestion == nil ||
		report.AiSuggestion.Verdict != "suspend_user" {
		t.Fatalf("queue auto=%+v report=%+v", auto, report)
	}
	var detailCase struct {
		Transcript []struct {
			Role string `json:"role"`
			Body string `json:"body"`
		} `json:"transcript"`
	}
	e.must(200, "GET", "/v1/backoffice/moderation/"+rep.ID.String(), staff, nil, &detailCase)
	if len(detailCase.Transcript) != 5 || detailCase.Transcript[0].Role != "seeker" {
		t.Fatalf("transcript %+v", detailCase.Transcript)
	}

	// Staff decide: the suggestion is not applied until they do.
	if code := e.call("POST", cpath+"/messages", ownerTok, map[string]string{"body": "Tak co, pošlete to?"}, nil); code != 201 {
		t.Fatalf("send before decision: %d", code)
	}
	e.must(204, "POST", "/v1/backoffice/moderation/"+rep.ID.String()+"/decision", staff, map[string]string{"decision": "suspend_user", "note": "Podvod se zálohou"}, nil)
	e.must(204, "POST", "/v1/backoffice/moderation/"+auto.ID.String()+"/decision", staff, map[string]string{"decision": "remove_message"}, nil)
	if code := e.call("POST", "/v1/backoffice/moderation/"+rep.ID.String()+"/decision", staff, map[string]string{"decision": "dismiss"}, nil); code != 409 {
		t.Fatalf("decided twice: %d", code)
	}
	if code := e.call("POST", cpath+"/messages", ownerTok, map[string]string{"body": "Haló?"}, &p); code != 403 || p.Code != "messaging_suspended" {
		t.Fatalf("suspended owner: %d %+v", code, p)
	}
	if _, ok := e.outbox.Last(ownerEmail, "messaging_suspended"); !ok {
		t.Fatal("no suspension e-mail")
	}
	e.must(200, "GET", cpath+"/messages", seekerTok, nil, &msgs)
	if i := slices.IndexFunc(msgs, func(m msgDTO) bool { return m.ID == scamID }); i < 0 || !msgs[i].Removed || msgs[i].Body != "" {
		t.Fatalf("removed message %+v", msgs)
	}
	var audits int
	if err := e.pool.QueryRow(context.Background(), "SELECT count(*) FROM audit_events WHERE action = 'moderation.decide' AND entity_id = ANY($1)",
		[]uuid.UUID{rep.ID, auto.ID}).Scan(&audits); err != nil || audits != 2 {
		t.Fatalf("audit %d %v", audits, err)
	}

	// Blocking: the seeker blocks, the owner side cannot unblock.
	e.must(204, "PUT", cpath+"/block", seekerTok, map[string]bool{"blocked": true}, nil)
	if code := e.call("PUT", cpath+"/block", ownerTok, map[string]bool{"blocked": false}, &p); code != 403 {
		t.Fatalf("owner unblocked: %d", code)
	}
	if code := e.call("POST", cpath+"/messages", seekerTok, map[string]string{"body": "x"}, &p); code != 403 || p.Code != "conversation_blocked" {
		t.Fatalf("send while blocked: %d %+v", code, p)
	}
	e.must(200, "GET", "/v1/conversations?as=seeker", seekerTok, nil, &inbox)
	if len(inbox) != 1 || !inbox[0].Blocked || !inbox[0].BlockedByMe || inbox[0].Role != "seeker" {
		t.Fatalf("seeker inbox %+v", inbox)
	}
	e.must(204, "PUT", cpath+"/block", seekerTok, map[string]bool{"blocked": false}, nil)

	// Preferences: daily digest instead of instant e-mails.
	e.must(200, "PUT", "/v1/me/notification-preferences", seekerTok, map[string]any{"email_messages": "daily", "push_messages": false}, nil)
	var prefs struct {
		EmailMessages string `json:"email_messages"`
	}
	e.must(200, "GET", "/v1/me/notification-preferences", seekerTok, nil, &prefs)
	if prefs.EmailMessages != "daily" {
		t.Fatalf("prefs %+v", prefs)
	}
}

// The daily digest collects unread notifications of users who chose it.
func TestMessagesDigest(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("digest")
	staff := e.staffToken()
	listingID := e.publishFlat(ownerTok, orgID, staff, "Byt na digest", "approximate")
	e.must(200, "PUT", "/v1/me/notification-preferences", ownerTok, map[string]any{"email_messages": "daily", "push_messages": true}, nil)
	seeker := e.register(uniqueEmail("digest-seeker"))
	e.must(201, "POST", "/v1/conversations", seeker, map[string]any{"listing_id": listingID, "body": "Dobrý den, je byt volný?"}, nil)
	e.runNotify()
	ownerEmail := e.emailOf(ownerTok)
	if _, ok := e.outbox.Last(ownerEmail, "new_message"); ok {
		t.Fatal("instant e-mail despite daily preference")
	}
	n, err := e.notifier.Digest(context.Background())
	if err != nil || n < 1 {
		t.Fatalf("digest %d %v", n, err)
	}
	m, ok := e.outbox.Last(ownerEmail, "messages_digest")
	if !ok || !strings.Contains(m.Text, "je byt volný") {
		t.Fatalf("digest e-mail %+v", m)
	}
	if n, _ := e.notifier.Digest(context.Background()); n != 0 {
		t.Fatalf("digest sent twice: %d", n)
	}
}
