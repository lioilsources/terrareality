package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"image"
	"image/color"
	"image/jpeg"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync/atomic"
	"testing"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/vision"
)

// visionPeople makes the fake vision report a visible person.
var visionPeople atomic.Bool

// visionDown makes the fake vision fail redactions.
var visionDown atomic.Bool

// fakeVision implements the services/vision contract: photos get a kitchen
// caption and tags; with visionPeople set they also need a privacy review.
func fakeVision(t *testing.T) *httptest.Server {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var req struct {
			ImageURL string `json:"image_url"`
		}
		_ = json.NewDecoder(r.Body).Decode(&req)
		switch r.URL.Path {
		case "/v1/photos/analyze":
			a := vision.Analysis{RoomType: "kitchen", Tags: []string{"kitchen", "dishwasher", "balcony"},
				Caption: "Kuchyň s myčkou", Model: "fake", Mock: true}
			if visionPeople.Load() {
				a.Tags = append(a.Tags, "people_visible")
				a.NeedsPrivacyReview = true
				a.Regions = []vision.Region{{Label: "face", Box: [4]float64{0.1, 0.1, 0.3, 0.3}}}
			}
			_ = json.NewEncoder(w).Encode(a)
		case "/v1/photos/redact":
			if visionDown.Load() {
				http.Error(w, "down", http.StatusServiceUnavailable)
				return
			}
			w.Header().Set("Content-Type", "image/jpeg")
			_, _ = w.Write(jpegBytes(t, 400, 300))
		default:
			http.NotFound(w, r)
		}
	}))
	t.Cleanup(srv.Close)
	return srv
}

func jpegBytes(t *testing.T, w, h int) []byte {
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for x := 0; x < w; x++ {
		img.Set(x, x%h, color.RGBA{30, 120, 80, 255})
	}
	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, img, nil); err != nil {
		t.Fatal(err)
	}
	return buf.Bytes()
}

type listingDTO struct {
	ID          uuid.UUID      `json:"id"`
	Status      string         `json:"status"`
	Attributes  map[string]any `json:"attributes"`
	Title       map[string]string
	Description map[string]string
	Unit        struct {
		ID       uuid.UUID  `json:"id"`
		Kind     string     `json:"kind"`
		ParentID *uuid.UUID `json:"parent_id"`
	} `json:"unit"`
	Media []struct {
		ID     uuid.UUID         `json:"id"`
		Status string            `json:"status"`
		URLs   map[string]string `json:"urls"`
		Tags   []string          `json:"tags"`
	} `json:"media"`
	Suggestions []struct {
		ID      uuid.UUID      `json:"id"`
		Kind    string         `json:"kind"`
		Status  string         `json:"status"`
		Payload map[string]any `json:"payload"`
	} `json:"suggestions"`
	Versions []struct {
		ID      uuid.UUID `json:"id"`
		Version int       `json:"version"`
		Status  string    `json:"status"`
	} `json:"versions"`
	PublishedVersion *int `json:"published_version"`
	PendingReview    bool `json:"pending_review"`
	DepositMaxMonths int  `json:"deposit_max_months"`
}

// ownerOrg registers a verified owner and returns token and personal org id.
func (e *env) ownerOrg(prefix string) (string, uuid.UUID) {
	em := uniqueEmail(prefix)
	tok := e.register(em)
	e.verifyEmail(em)
	var m me
	e.must(200, "GET", "/v1/me", tok, nil, &m)
	return tok, m.Organizations[0].Organization.ID
}

// uploadPhoto runs the upload flow; the worker step is executed inline.
func (e *env) uploadPhoto(tok string, orgID, listingID uuid.UUID, name string) uuid.UUID {
	e.t.Helper()
	data := jpegBytes(e.t, 640, 480)
	var up struct {
		Media     struct{ ID uuid.UUID } `json:"media"`
		UploadURL string                 `json:"upload_url"`
	}
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/listings/"+listingID.String()+"/media", tok,
		map[string]any{"filename": name, "content_type": "image/jpeg", "size": len(data)}, &up)
	key := up.UploadURL[len("http://blob.test/"):strings.Index(up.UploadURL, "?")]
	if err := e.blob.Put(context.Background(), key, "image/jpeg", data); err != nil {
		e.t.Fatal(err)
	}
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/media/"+up.Media.ID.String()+"/complete", tok, nil, nil)
	if err := e.listings.ProcessMedia(context.Background(), up.Media.ID); err != nil {
		e.t.Fatal(err)
	}
	return up.Media.ID
}

func (e *env) runSuggestions() {
	e.t.Helper()
	e.jobs.mu.Lock()
	ids := e.jobs.suggestions
	e.jobs.suggestions = nil
	e.jobs.mu.Unlock()
	for _, id := range ids {
		if err := e.listings.RunSuggestion(context.Background(), id); err != nil {
			e.t.Fatal(err)
		}
	}
}

// Acceptance M2: an owner creates listings of a flat and of a room with
// photos, gets AI suggestions for attributes and text, submits them for
// review; the backoffice approves; the version is stored.
func TestCatalogAcceptance(t *testing.T) {
	e := newEnv(t)
	// The test approves the mock's "stove" heating option; start without it.
	if _, err := e.pool.Exec(context.Background(), `
		UPDATE filter_schemas SET options = (SELECT coalesce(jsonb_agg(o), '[]') FROM jsonb_array_elements(options) o
		  WHERE o->>'value' <> 'stove') WHERE key = 'heating';
		DELETE FROM filter_schema_proposals WHERE attribute_key = 'heating' AND value = 'stove';`); err != nil {
		t.Fatal(err)
	}
	tok, orgID := e.ownerOrg("catalog")
	base := "/v1/orgs/" + orgID.String()

	var addrs []struct {
		RuianID int64  `json:"ruian_id"`
		Label   string `json:"label"`
	}
	e.must(200, "GET", "/v1/addresses/search?q=dejvicka", "", nil, &addrs)
	if len(addrs) == 0 || !strings.Contains(addrs[0].Label, "Dejvická") {
		t.Fatalf("autocomplete %+v", addrs)
	}
	var schema struct {
		Attributes []struct{ Key string } `json:"attributes"`
	}
	e.must(200, "GET", "/v1/attributes", "", nil, &schema)
	if len(schema.Attributes) < 60 {
		t.Fatalf("schema has %d attributes", len(schema.Attributes))
	}

	// Flat.
	var flat listingDTO
	e.must(201, "POST", base+"/listings", tok, map[string]any{"ruian_id": addrs[0].RuianID, "unit_kind": "apartment",
		"layout": "2+kk", "floor_area": 54, "floor": 3}, &flat)
	if flat.Status != "draft" || flat.Attributes["layout"] != "2+kk" || flat.DepositMaxMonths != 3 {
		t.Fatalf("flat %+v", flat)
	}
	flatPath := base + "/listings/" + flat.ID.String()
	desc := "Světlý byt 2+kk v cihlovém domě s výtahem, balkon, pračka. Vytápění krbová kamna. Pejsek vítán."
	update := map[string]any{"title": map[string]string{"cs": "", "en": ""}, "description": map[string]string{"cs": desc, "en": ""},
		"rent_amount": 2200000, "deposit_amount": 8000000, "attributes": flat.Attributes, "location_precision": "approximate"}
	var p struct {
		Code   string `json:"code"`
		Errors []struct{ Key, Reason string }
	}
	if c := e.call("PUT", flatPath, tok, update, &p); c != 422 || p.Code != "invalid_fields" || p.Errors[0].Key != "deposit" {
		t.Fatalf("deposit over 3 rents accepted: %d %+v", c, p)
	}
	update["deposit_amount"] = 4400000
	e.must(200, "PUT", flatPath, tok, update, &flat)

	// Submitting without photos and title fails with field errors.
	if c := e.call("POST", flatPath+"/submit", tok, nil, &p); c != 422 {
		t.Fatalf("incomplete submit: %d", c)
	}
	mediaID := e.uploadPhoto(tok, orgID, flat.ID, "kitchen.jpg")
	e.must(200, "GET", flatPath, tok, nil, &flat)
	if len(flat.Media) != 1 || flat.Media[0].Status != "ready" || flat.Media[0].URLs["thumb"] == "" || len(flat.Media[0].Tags) == 0 {
		t.Fatalf("media %+v", flat.Media)
	}
	if !hasSuggestion(flat, "photo_tags", "pending") {
		t.Fatalf("no photo suggestion: %+v", flat.Suggestions)
	}
	stored, _ := e.blob.Get(context.Background(), "orgs/"+orgID.String()+"/media/"+mediaID.String()+"/original")
	if bytes.Contains(stored, []byte("Exif")) {
		t.Fatal("stored photo still has EXIF")
	}

	// AI attribute suggestion: the owner accepts only some keys.
	e.must(202, "POST", flatPath+"/suggestions", tok, map[string]string{"kind": "attributes"}, nil)
	e.runSuggestions()
	e.must(200, "GET", flatPath, tok, nil, &flat)
	sg := findSuggestion(flat, "attributes")
	values, _ := sg.Payload["values"].(map[string]any)
	if sg.Status != "pending" || values["elevator"] != true || values["balcony"] != true || values["building_type"] != "brick" {
		t.Fatalf("attribute suggestion %+v", sg)
	}
	if _, ok := values["heating"]; ok {
		t.Fatal("unapproved option suggested as a value")
	}
	if flat.Attributes["elevator"] != nil {
		t.Fatal("suggestion applied without a decision")
	}
	e.must(200, "POST", base+"/suggestions/"+sg.ID.String()+"/decision", tok, map[string]any{"accept": true, "keys": []string{"elevator", "balcony"}}, nil)
	e.must(200, "GET", flatPath, tok, nil, &flat)
	if flat.Attributes["elevator"] != true || flat.Attributes["building_type"] != nil {
		t.Fatalf("partial accept: %+v", flat.Attributes)
	}
	if s := findSuggestion(flat, "attributes"); s.Status != "partially_accepted" {
		t.Fatalf("status %s", s.Status)
	}

	// AI text suggestion accepted in full.
	e.must(202, "POST", flatPath+"/suggestions", tok, map[string]string{"kind": "text"}, nil)
	e.runSuggestions()
	e.must(200, "GET", flatPath, tok, nil, &flat)
	ts := findSuggestion(flat, "text")
	e.must(200, "POST", base+"/suggestions/"+ts.ID.String()+"/decision", tok, map[string]any{"accept": true}, nil)
	e.must(200, "GET", flatPath, tok, nil, &flat)
	if !strings.HasPrefix(flat.Title["cs"], "Pronájem bytu 2+kk") || flat.Title["en"] == "" || !strings.Contains(flat.Description["cs"], "Výtah") {
		t.Fatalf("text not applied: %+v %+v", flat.Title, flat.Description)
	}

	// Submit, review, publish.
	e.must(200, "POST", flatPath+"/submit", tok, nil, &flat)
	if flat.Status != "review" || !flat.PendingReview || len(flat.Versions) != 1 {
		t.Fatalf("after submit %+v", flat)
	}
	staffTok := e.staffToken()
	var queue []struct {
		VersionID uuid.UUID `json:"version_id"`
		ListingID uuid.UUID `json:"listing_id"`
		CoverURL  string    `json:"cover_url"`
	}
	e.must(200, "GET", "/v1/backoffice/reviews", staffTok, nil, &queue)
	var versionID uuid.UUID
	for _, q := range queue {
		if q.ListingID == flat.ID {
			versionID = q.VersionID
		}
	}
	if versionID == uuid.Nil {
		t.Fatal("version not in review queue")
	}
	if c := e.call("POST", "/v1/backoffice/reviews/"+versionID.String()+"/decision", tok, map[string]any{"approve": true}, nil); c != 403 {
		t.Fatalf("owner approved own listing: %d", c)
	}
	var detail struct {
		Snapshot map[string]any `json:"snapshot"`
		Photos   []map[string]string
	}
	e.must(200, "GET", "/v1/backoffice/reviews/"+versionID.String(), staffTok, nil, &detail)
	if len(detail.Photos) != 1 || detail.Snapshot["rent_amount"].(float64) != 2200000 {
		t.Fatalf("review detail %+v", detail)
	}
	e.must(204, "POST", "/v1/backoffice/reviews/"+versionID.String()+"/decision", staffTok, map[string]any{"approve": true}, nil)
	e.must(200, "GET", flatPath, tok, nil, &flat)
	if flat.Status != "published" || flat.PublishedVersion == nil || *flat.PublishedVersion != 1 || flat.Versions[0].Status != "approved" {
		t.Fatalf("after approval %+v", flat)
	}
	if _, ok := e.outbox.Last(e.emailOf(tok), "listing_approved"); !ok {
		t.Fatal("owner not notified")
	}

	// Editing a published listing keeps it published; resubmitting creates v2.
	update["rent_amount"] = 2300000
	update["title"] = flat.Title
	update["description"] = flat.Description
	update["attributes"] = flat.Attributes
	e.must(200, "PUT", flatPath, tok, update, &flat)
	e.must(200, "POST", flatPath+"/submit", tok, nil, &flat)
	if flat.Status != "published" || len(flat.Versions) != 2 || flat.Versions[0].Version != 2 {
		t.Fatalf("resubmit %+v", flat)
	}
	e.must(200, "POST", flatPath+"/status", tok, map[string]string{"status": "paused"}, &flat)
	if flat.Status != "paused" {
		t.Fatalf("pause %s", flat.Status)
	}

	// Room in a shared flat: parent apartment is created, rejection returns it to draft.
	var room listingDTO
	e.must(201, "POST", base+"/listings", tok, map[string]any{"ruian_id": addrs[0].RuianID, "unit_kind": "room",
		"unit_label": "Pokoj 1", "floor_area": 14, "parent_layout": "4+1", "parent_floor_area": 95}, &room)
	if room.Unit.Kind != "room" || room.Unit.ParentID == nil {
		t.Fatalf("room unit %+v", room.Unit)
	}
	roomPath := base + "/listings/" + room.ID.String()
	e.must(200, "PUT", roomPath, tok, map[string]any{"title": map[string]string{"cs": "Pokoj ve sdíleném bytě, Dejvice", "en": ""},
		"description": map[string]string{"cs": strings.Repeat("Prostorný pokoj s vlastní koupelnou. ", 3), "en": ""},
		"rent_amount": 950000, "attributes": map[string]any{"room_lockable": true, "flatmates": 3},
		"location_precision": "approximate"}, &room)
	e.uploadPhoto(tok, orgID, room.ID, "room.jpg")
	e.must(200, "POST", roomPath+"/submit", tok, nil, &room)
	e.must(200, "GET", "/v1/backoffice/reviews", staffTok, nil, &queue)
	for _, q := range queue {
		if q.ListingID == room.ID {
			versionID = q.VersionID
		}
	}
	if c := e.call("POST", "/v1/backoffice/reviews/"+versionID.String()+"/decision", staffTok, map[string]any{"approve": false}, nil); c != 422 {
		t.Fatalf("rejection without note: %d", c)
	}
	e.must(204, "POST", "/v1/backoffice/reviews/"+versionID.String()+"/decision", staffTok,
		map[string]any{"approve": false, "note": "Doplňte prosím fotku koupelny."}, nil)
	e.must(200, "GET", roomPath, tok, nil, &room)
	if room.Status != "draft" || room.Versions[0].Status != "rejected" {
		t.Fatalf("after rejection %+v", room)
	}

	// The new heating option proposed by AI ingest waits for the backoffice.
	var proposals []struct {
		ID           uuid.UUID `json:"id"`
		AttributeKey string    `json:"attribute_key"`
		Value        string    `json:"value"`
	}
	e.must(200, "GET", "/v1/backoffice/filter-proposals", staffTok, nil, &proposals)
	var stove uuid.UUID
	for _, pr := range proposals {
		if pr.AttributeKey == "heating" && pr.Value == "stove" {
			stove = pr.ID
		}
	}
	if stove == uuid.Nil {
		t.Fatalf("no stove proposal in %+v", proposals)
	}
	e.must(204, "POST", "/v1/backoffice/filter-proposals/"+stove.String()+"/decision", staffTok, map[string]any{"approve": true}, nil)
	var full struct {
		Attributes []struct {
			Key     string `json:"key"`
			Options []struct{ Value, Source string }
		} `json:"attributes"`
	}
	e.must(200, "GET", "/v1/attributes", "", nil, &full)
	found := false
	for _, a := range full.Attributes {
		for _, o := range a.Options {
			found = found || (a.Key == "heating" && o.Value == "stove" && o.Source == "ingest")
		}
	}
	if !found {
		t.Fatal("approved option missing from schema")
	}

	// Another organization sees nothing.
	otherTok, otherOrg := e.ownerOrg("intruder")
	if c := e.call("GET", base+"/listings/"+flat.ID.String(), otherTok, nil, nil); c != 404 {
		t.Fatalf("foreign org read listing: %d", c)
	}
	if c := e.call("GET", "/v1/orgs/"+otherOrg.String()+"/listings/"+flat.ID.String(), otherTok, nil, nil); c != 404 {
		t.Fatalf("listing visible through own org path: %d", c)
	}
}

func TestPrivacyBlurSuggestion(t *testing.T) {
	e := newEnv(t)
	tok, orgID := e.ownerOrg("blur")
	var addrs []struct {
		RuianID int64 `json:"ruian_id"`
	}
	e.must(200, "GET", "/v1/addresses/search?q=vinohradska", "", nil, &addrs)
	var l listingDTO
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/listings", tok, map[string]any{"ruian_id": addrs[0].RuianID, "unit_kind": "apartment"}, &l)
	visionPeople.Store(true)
	defer visionPeople.Store(false)
	id := e.uploadPhoto(tok, orgID, l.ID, "people.jpg")
	e.must(200, "GET", "/v1/orgs/"+orgID.String()+"/listings/"+l.ID.String(), tok, nil, &l)
	if !hasSuggestion(l, "privacy_blur", "pending") {
		t.Fatalf("no privacy suggestion: %+v", l.Suggestions)
	}
	key := "orgs/" + orgID.String() + "/media/" + id.String() + "/original"
	before, _ := e.blob.Get(context.Background(), key)
	sg := findSuggestion(l, "privacy_blur")
	lpath := "/v1/orgs/" + orgID.String() + "/listings/" + l.ID.String()
	e.must(200, "PUT", lpath, tok, map[string]any{"title": map[string]string{"cs": "Byt s lidmi na fotce", "en": ""},
		"description": map[string]string{"cs": strings.Repeat("Světlý byt s balkonem a výhledem do parku. ", 3), "en": ""},
		"rent_amount": 2000000, "attributes": l.Attributes, "location_precision": "approximate"}, nil)
	// An undecided privacy flag blocks the submission (S-D1).
	var p struct {
		Code   string `json:"code"`
		Errors []struct {
			Key    string `json:"key"`
			Reason string `json:"reason"`
		} `json:"errors"`
	}
	if code := e.call("POST", lpath+"/submit", tok, nil, &p); code != 422 || len(p.Errors) != 1 ||
		p.Errors[0].Reason != "privacy_review_pending" {
		t.Fatalf("submitted with an undecided privacy flag: %d %+v", code, p)
	}
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/suggestions/"+sg.ID.String()+"/decision", tok, map[string]any{"accept": true}, nil)
	// Accepted but not applied yet: still pending, photo unchanged (V-6).
	e.must(200, "GET", lpath, tok, nil, &l)
	if !hasSuggestion(l, "privacy_blur", "pending") {
		t.Fatalf("suggestion not pending before redaction: %+v", l.Suggestions)
	}
	if now, _ := e.blob.Get(context.Background(), key); !bytes.Equal(before, now) {
		t.Fatal("photo changed before the job ran")
	}
	if code := e.call("POST", lpath+"/submit", tok, nil, nil); code != 422 {
		t.Fatalf("submitted while the redaction is queued: %d", code)
	}
	e.jobs.mu.Lock()
	queued := append([]uuid.UUID(nil), e.jobs.redactions...)
	e.jobs.mu.Unlock()
	if len(queued) != 1 || queued[0] != sg.ID {
		t.Fatalf("redaction jobs %v", queued)
	}
	// A failing vision service leaves everything as it was; River retries.
	visionDown.Store(true)
	if err := e.listings.RedactMedia(context.Background(), sg.ID); err == nil {
		t.Fatal("redaction failure swallowed")
	}
	visionDown.Store(false)
	e.must(200, "GET", lpath, tok, nil, &l)
	if !hasSuggestion(l, "privacy_blur", "pending") {
		t.Fatalf("failed redaction marked the suggestion: %+v", l.Suggestions)
	}
	if err := e.listings.RedactMedia(context.Background(), sg.ID); err != nil {
		t.Fatal(err)
	}
	// Idempotent: a duplicate job does nothing.
	if err := e.listings.RedactMedia(context.Background(), sg.ID); err != nil {
		t.Fatal(err)
	}
	after, _ := e.blob.Get(context.Background(), key)
	cfg, err := jpeg.DecodeConfig(bytes.NewReader(after))
	if err != nil || bytes.Equal(before, after) || cfg.Width != 400 {
		t.Fatalf("photo not redacted: %v %dx%d", err, cfg.Width, cfg.Height)
	}
	e.must(200, "GET", lpath, tok, nil, &l)
	if !hasSuggestion(l, "privacy_blur", "accepted") {
		t.Fatalf("suggestion not accepted after redaction: %+v", l.Suggestions)
	}
	// The media row describes the stored (re-sanitized) bytes.
	var size int64
	var ct string
	var sum []byte
	if err := e.pool.QueryRow(context.Background(), "SELECT size_bytes, content_type, sha256 FROM media WHERE id = $1", id).
		Scan(&size, &ct, &sum); err != nil {
		t.Fatal(err)
	}
	if size != int64(len(after)) || ct != "image/jpeg" || len(sum) != 32 {
		t.Fatalf("media metadata %d %s (stored %d)", size, ct, len(after))
	}
	e.must(200, "POST", lpath+"/submit", tok, nil, nil)
}

func hasSuggestion(l listingDTO, kind, status string) bool {
	for _, s := range l.Suggestions {
		if s.Kind == kind && s.Status == status {
			return true
		}
	}
	return false
}

func findSuggestion(l listingDTO, kind string) struct {
	ID      uuid.UUID      `json:"id"`
	Kind    string         `json:"kind"`
	Status  string         `json:"status"`
	Payload map[string]any `json:"payload"`
} {
	for _, s := range l.Suggestions {
		if s.Kind == kind {
			return s
		}
	}
	return struct {
		ID      uuid.UUID      `json:"id"`
		Kind    string         `json:"kind"`
		Status  string         `json:"status"`
		Payload map[string]any `json:"payload"`
	}{}
}

// staffToken registers a staff member.
func (e *env) staffToken() string {
	em := uniqueEmail("staff")
	tok := e.register(em)
	if _, err := e.pool.Exec(context.Background(), "UPDATE users SET is_staff = true WHERE email = $1", em); err != nil {
		e.t.Fatal(err)
	}
	return tok
}

func (e *env) emailOf(tok string) string {
	var m me
	e.must(200, "GET", "/v1/me", tok, nil, &m)
	return m.Email
}

// Contract test against the real services/vision (mock or Spark-backed),
// enabled with TEST_VISION_URL=http://localhost:8001.
func TestVisionServiceContract(t *testing.T) {
	u := os.Getenv("TEST_VISION_URL")
	if u == "" {
		t.Skip("TEST_VISION_URL not set")
	}
	img := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "image/jpeg")
		_, _ = w.Write(jpegBytes(t, 640, 480))
	}))
	defer img.Close()
	c := vision.New(u)
	a, err := c.Analyze(context.Background(), img.URL+"/photo.jpg", "cs")
	if err != nil {
		t.Fatal(err)
	}
	if a.RoomType == "" || a.Model == "" {
		t.Fatalf("analysis %+v", a)
	}
	out, err := c.Redact(context.Background(), img.URL+"/photo.jpg", []vision.Region{{Label: "face", Box: [4]float64{0.1, 0.1, 0.4, 0.4}}})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := jpeg.Decode(bytes.NewReader(out)); err != nil {
		t.Fatalf("redacted image: %v", err)
	}
}
