package ai

import (
	"context"
	"os"
	"testing"
	"time"
)

// TestLiveGateway runs extraction and drafting against a real OpenAI-compatible
// gateway: TEST_LLM_URL=http://<spark>:8080/v1 TEST_LLM_MODEL=terra go test ./internal/ai -run Live -v
func TestLiveGateway(t *testing.T) {
	url, model := os.Getenv("TEST_LLM_URL"), os.Getenv("TEST_LLM_MODEL")
	if url == "" || model == "" {
		t.Skip("TEST_LLM_URL / TEST_LLM_MODEL not set")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 4*time.Minute)
	defer cancel()
	c := NewClient(url, "not-needed", model)
	text := "Pronajmu světlý byt 2+kk, 54 m2 ve 3. patře cihlového domu s výtahem. Balkon do dvora, myčka, pračka. " +
		"Vytápění krbová kamna. Pes po dohodě. Metro Dejvická 5 minut."
	res, err := c.ExtractAttributes(ctx, ExtractRequest{Text: text, UnitKind: "apartment", Attrs: attrs(t)})
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("values: %v", res.Values)
	t.Logf("new options: %v", res.NewOptions)
	if res.Values["balcony"] != true || res.Values["elevator"] != true {
		t.Errorf("model missed obvious attributes: %v", res.Values)
	}
	f := int32(3)
	d, err := c.DraftText(ctx, DraftRequest{UnitKind: "apartment", Layout: "2+kk", FloorArea: 54, Floor: &f,
		Location: "Dejvice, Praha", Rent: 22000, Currency: "CZK",
		Features: map[string]string{"Výtah": "", "Balkon": ""}, FeaturesEN: map[string]string{"Elevator": "", "Balcony": ""}})
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("title: %+v", d.Title)
	t.Logf("description cs: %s", d.Description.CS)
	if d.Title.CS == "" || d.Description.EN == "" {
		t.Errorf("empty draft %+v", d)
	}
}
