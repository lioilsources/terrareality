package integration

import (
	"context"
	"math"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/search"
)

type searchResult struct {
	Total int `json:"total"`
	Items []struct {
		ID    uuid.UUID         `json:"id"`
		Title map[string]string `json:"title"`
	} `json:"items"`
	Facets map[string][]struct {
		Value string `json:"value"`
		Count int    `json:"count"`
	} `json:"facets"`
	Areas []struct {
		Path  string `json:"path"`
		Name  string `json:"name"`
		Count int    `json:"count"`
	} `json:"areas"`
}

// publishFlat creates, fills, submits and approves a flat; returns its id.
func (e *env) publishFlat(tok string, orgID uuid.UUID, staffTok, title string, precision string) uuid.UUID {
	e.t.Helper()
	var addrs []struct {
		RuianID int64 `json:"ruian_id"`
	}
	e.must(200, "GET", "/v1/addresses/search?q=dejvicka", "", nil, &addrs)
	var l listingDTO
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/listings", tok, map[string]any{"ruian_id": addrs[0].RuianID, "unit_kind": "apartment",
		"layout": "2+kk", "floor_area": 54}, &l)
	path := "/v1/orgs/" + orgID.String() + "/listings/" + l.ID.String()
	attrs := l.Attributes
	attrs["balcony"] = true
	attrs["pets"] = []string{"dogs"}
	e.must(200, "PUT", path, tok, map[string]any{"title": map[string]string{"cs": title, "en": ""},
		"description": map[string]string{"cs": strings.Repeat("Světlý byt se zahrádkou a výhledem do parku. ", 2), "en": ""},
		"rent_amount": 1_750_000, "attributes": attrs, "location_precision": precision}, nil)
	e.uploadPhoto(tok, orgID, l.ID, "a.jpg")
	e.must(200, "POST", path+"/submit", tok, nil, &l)
	var queue []struct {
		VersionID uuid.UUID `json:"version_id"`
		ListingID uuid.UUID `json:"listing_id"`
	}
	e.must(200, "GET", "/v1/backoffice/reviews", staffTok, nil, &queue)
	for _, q := range queue {
		if q.ListingID == l.ID {
			e.must(204, "POST", "/v1/backoffice/reviews/"+q.VersionID.String()+"/decision", staffTok, map[string]any{"approve": true}, nil)
		}
	}
	return l.ID
}

func TestSearchIndexAndPublicListing(t *testing.T) {
	e := newEnv(t)
	tok, orgID := e.ownerOrg("search")
	staff := e.staffToken()
	unique := "Zahradni-" + uuid.NewString()[:6]
	id := e.publishFlat(tok, orgID, staff, "Byt "+unique, "approximate")

	var praha6 string
	if err := e.pool.QueryRow(context.Background(), "SELECT path::text FROM admin_units WHERE name = 'Praha 6' AND level = 3").Scan(&praha6); err != nil {
		t.Fatal(err)
	}
	var res searchResult
	e.must(200, "POST", "/v1/search", "", map[string]any{"text": unique, "admin_path": praha6, "kinds": []string{"apartment"},
		"rent_max": 1_800_000, "attributes": map[string]any{"pets": map[string]any{"values": []string{"dogs"}}, "balcony": map[string]any{"bool": true}}}, &res)
	if res.Total != 1 || res.Items[0].ID != id {
		t.Fatalf("search %+v", res)
	}
	if len(res.Areas) == 0 || !strings.HasPrefix(res.Areas[0].Path, praha6) {
		t.Fatalf("areas %+v", res.Areas)
	}
	// Drafts and other filters do not match.
	e.must(200, "POST", "/v1/search", "", map[string]any{"text": unique, "rent_max": 1_000_000}, &res)
	if res.Total != 0 {
		t.Fatalf("rent filter ignored: %d", res.Total)
	}

	// Public detail: approved version, approximate location only.
	var pub struct {
		Location struct {
			Lat, Lng  float64
			Precision string
			Address   *string
		} `json:"location"`
		AreaNames []string            `json:"area_names"`
		Photos    []map[string]string `json:"photos"`
	}
	e.must(200, "GET", "/v1/listings/"+id.String(), "", nil, &pub)
	exactLat, exactLng := 50.1006, 14.3955
	d := math.Hypot((pub.Location.Lat-exactLat)*111_320, (pub.Location.Lng-exactLng)*71_500)
	if pub.Location.Precision != "approximate" || pub.Location.Address != nil || d < 100 || d > 400 {
		t.Fatalf("location %+v, %.0f m from the building", pub.Location, d)
	}
	if len(pub.Photos) != 1 || len(pub.AreaNames) < 3 {
		t.Fatalf("public listing %+v", pub)
	}

	// Chat endpoint returns filters, place and results in one answer.
	var chat struct {
		Query struct {
			AdminPath string `json:"admin_path"`
		} `json:"query"`
		Place  *struct{ Name string } `json:"place"`
		Result searchResult           `json:"result"`
		Model  string                 `json:"model"`
	}
	e.must(200, "POST", "/v1/search/chat", "", map[string]any{"message": "2+kk do 18 000 v Praze 6 se psem", "locale": "cs"}, &chat)
	if chat.Place == nil || chat.Place.Name != "Praha 6" || chat.Result.Total == 0 || chat.Model != "rules" {
		t.Fatalf("chat %+v", chat)
	}

	// Saved search digest e-mails new listings once.
	var saved struct{ ID uuid.UUID }
	e.must(201, "POST", "/v1/me/saved-searches", tok, map[string]any{"name": "Dejvice", "query": map[string]any{"text": unique}}, &saved)
	if _, err := e.pool.Exec(context.Background(), "UPDATE saved_searches SET last_notified_at = now() - interval '2 days' WHERE id = $1", saved.ID); err != nil {
		t.Fatal(err)
	}
	digest := &search.Digest{Engine: &search.Engine{Pool: e.pool}, Outbox: e.outbox, Render: e.acct.Render, WebBaseURL: "http://web.test"}
	if _, err := digest.Run(context.Background()); err != nil {
		t.Fatal(err)
	}
	m, ok := e.outbox.Last(e.emailOf(tok), "saved_search_digest")
	if !ok || !strings.Contains(m.Text, "/inzerat/"+id.String()) {
		t.Fatalf("digest %+v", m)
	}

	// Pausing removes the listing from search and the public page.
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/listings/"+id.String()+"/status", tok, map[string]string{"status": "paused"}, nil)
	e.must(200, "POST", "/v1/search", "", map[string]any{"text": unique}, &res)
	if res.Total != 0 {
		t.Fatalf("paused listing still found")
	}
	if c := e.call("GET", "/v1/listings/"+id.String(), "", nil, nil); c != 404 {
		t.Fatalf("paused public listing: %d", c)
	}
}
