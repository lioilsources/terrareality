package integration

import (
	"context"
	"os"
	"strings"
	"testing"

	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/catalog"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/ruian"
	"github.com/terrareality/terrareality/services/api/internal/search"
)

func chatSetup(t *testing.T) (*search.Chat, *catalog.Schema) {
	pool := setup(t)
	ctx := context.Background()
	if err := catalog.Sync(ctx, db.New(pool)); err != nil {
		t.Fatal(err)
	}
	if _, err := ruian.SeedSample(ctx, pool); err != nil {
		t.Fatal(err)
	}
	if _, err := search.SeedFromRuian(ctx, pool); err != nil {
		t.Fatal(err)
	}
	schema, err := catalog.Load(ctx, db.New(pool))
	if err != nil {
		t.Fatal(err)
	}
	return &search.Chat{Pool: pool}, schema
}

func checkPraha6Query(t *testing.T, out search.ChatOutcome) {
	t.Helper()
	q := out.Query
	if len(q.Kinds) != 1 || q.Kinds[0] != "apartment" || len(q.Layouts) != 1 || q.Layouts[0] != "2+kk" {
		t.Errorf("kind/layout %+v", q)
	}
	if q.RentMax == nil || *q.RentMax != 1_800_000 {
		t.Errorf("rent max %v", q.RentMax)
	}
	if out.Place == nil || out.Place.Name != "Praha 6" || !strings.HasSuffix(q.AdminPath, "praha_6") || len(out.Place.BBox) != 4 {
		t.Errorf("place %+v path %s", out.Place, q.AdminPath)
	}
	if f, ok := q.Attributes["pets"]; !ok || len(f.Values) == 0 || f.Values[0] != "dogs" {
		t.Errorf("pets %+v", q.Attributes)
	}
}

// Acceptance M3: "2+kk do 18 000 v Praze 6 se psem" sets filters and the map.
func TestChatRules(t *testing.T) {
	c, schema := chatSetup(t)
	ctx := context.Background()
	out := c.Ask(ctx, "2+kk do 18 000 v Praze 6 se psem", search.Query{}, schema, "cs")
	checkPraha6Query(t, out)
	if out.Model != "rules" || !strings.Contains(out.Reply, "Praha 6") {
		t.Errorf("reply %+v", out)
	}
	// Follow-up refines the current query.
	next := c.Ask(ctx, "a s balkonem v Dejvicích", out.Query, schema, "cs")
	if next.Query.RentMax == nil || next.Query.Attributes["balcony"].Bool == nil || next.Place == nil || next.Place.Name != "Dejvice" {
		t.Errorf("follow-up %+v place %+v", next.Query, next.Place)
	}
	room := c.Ask(ctx, "pokoj od 8 tis. ve Brně", search.Query{}, schema, "cs")
	if room.Query.Kinds[0] != "room" || *room.Query.RentMin != 800_000 || room.Place == nil || room.Place.Name != "Brno" {
		t.Errorf("room %+v %+v", room.Query, room.Place)
	}
}

// Same request through the Spark (TEST_LLM_URL, TEST_LLM_MODEL=openclaw-default).
func TestChatLive(t *testing.T) {
	url, model := os.Getenv("TEST_LLM_URL"), os.Getenv("TEST_LLM_MODEL")
	if url == "" || model == "" {
		t.Skip("TEST_LLM_URL / TEST_LLM_MODEL not set")
	}
	c, schema := chatSetup(t)
	c.LLM, c.Model = ai.NewClient(url, "not-needed", model), model
	out := c.Ask(context.Background(), "2+kk do 18 000 v Praze 6 se psem", search.Query{}, schema, "cs")
	t.Logf("outcome %+v place %+v reply %q", out.Query, out.Place, out.Reply)
	if out.Degraded {
		t.Fatal("LLM call failed, rules were used")
	}
	checkPraha6Query(t, out)
}
