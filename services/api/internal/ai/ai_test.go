package ai

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/terrareality/terrareality/services/api/internal/catalog"
)

func attrs(t *testing.T) []catalog.Attribute {
	c, err := catalog.Embedded()
	if err != nil {
		t.Fatal(err)
	}
	var out []catalog.Attribute
	for _, a := range c.Attributes {
		if len(a.AppliesTo) == 0 || a.AppliesTo[0] == "apartment" || a.AppliesTo[0] == "room" && false {
			out = append(out, a)
		}
	}
	return out
}

func TestMockExtract(t *testing.T) {
	text := "Světlý byt 2+kk, 54 m2 ve 3. patře, cihlový dům s výtahem, balkon, myčka a pračka. " +
		"Bez parkování. Pejsek vítán. Vytápění krbová kamna."
	res, err := Mock{}.ExtractAttributes(context.Background(), ExtractRequest{Text: text, UnitKind: "apartment",
		Attrs: attrs(t), PhotoTags: []string{"terrace", "balcony"}})
	if err != nil {
		t.Fatal(err)
	}
	v := res.Values
	checks := map[string]any{"layout": "2+kk", "floor_area": 54.0, "floor": 3.0, "elevator": true, "balcony": true,
		"washing_machine": true, "terrace": true, "building_type": "brick", "heating": "stove"}
	for k, want := range checks {
		if v[k] != want {
			t.Errorf("%s = %v, want %v", k, v[k], want)
		}
	}
	if p, _ := v["pets"].([]string); len(p) != 1 || p[0] != "dogs" {
		t.Errorf("pets %v", v["pets"])
	}
	if len(res.NewOptions) != 1 || res.NewOptions[0].Value != "stove" {
		t.Errorf("new options %v", res.NewOptions)
	}
}

func TestMockDraft(t *testing.T) {
	f := int32(3)
	d, _ := Mock{}.DraftText(context.Background(), DraftRequest{UnitKind: "apartment", Layout: "2+kk", FloorArea: 54,
		Floor: &f, Location: "Praha 6 – Dejvice", Features: map[string]string{"Balkon": ""}, FeaturesEN: map[string]string{"Balcony": ""}})
	if d.Title.CS != "Pronájem bytu 2+kk, 54 m², Praha 6 – Dejvice" || !strings.Contains(d.Description.EN, "- Balcony") {
		t.Fatalf("draft %+v", d)
	}
}

func TestClientParsesSchemaOutput(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var req chatRequest
		_ = json.NewDecoder(r.Body).Decode(&req)
		if req.Model != "terra" || req.ResponseFormat["type"] != "json_object" {
			t.Errorf("request %+v", req)
		}
		content := "<think>hmm</think>```json\n{\"values\": {\"balcony\": true, \"layout\": \"3+1\"}, " +
			"\"new_options\": [{\"key\": \"heating\", \"value\": \"stove\", \"label\": {\"cs\": \"kamna\", \"en\": \"stove\"}}, " +
			"{\"key\": \"balcony\", \"value\": \"x\", \"label\": {\"cs\": \"x\", \"en\": \"x\"}}]}\n```"
		_ = json.NewEncoder(w).Encode(map[string]any{"choices": []any{map[string]any{"message": map[string]any{"content": content}}}})
	}))
	defer srv.Close()
	c := NewClient(srv.URL, "k", "terra")
	res, err := c.ExtractAttributes(context.Background(), ExtractRequest{Text: "x", UnitKind: "apartment", Attrs: attrs(t)})
	if err != nil {
		t.Fatal(err)
	}
	if res.Values["balcony"] != true || res.Model != "terra" || len(res.NewOptions) != 1 {
		t.Fatalf("result %+v", res)
	}
}
