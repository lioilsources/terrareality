package integration

import (
	"context"
	"sort"
	"testing"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/catalog"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/ruian"
	"github.com/terrareality/terrareality/services/api/internal/search"
)

func ptr[T any](v T) *T { return &v }

// Acceptance M3: p95 of search (items, facets, area aggregates and map
// points) stays under 300 ms on 50 000 listings.
func TestSearchPerformance(t *testing.T) {
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
	if _, err := search.Synthetic(ctx, pool, 50_000); err != nil {
		t.Fatal(err)
	}
	schema, err := catalog.Load(ctx, db.New(pool))
	if err != nil {
		t.Fatal(err)
	}
	var praha6 string
	if err := pool.QueryRow(ctx, "SELECT path::text FROM admin_units WHERE name = 'Praha 6' AND level = 3").Scan(&praha6); err != nil {
		t.Fatal(err)
	}
	yes := true
	queries := []search.Query{
		{},
		{Kinds: []string{"apartment"}},
		{Kinds: []string{"apartment"}, RentMax: ptr(int64(1_800_000)), Layouts: []string{"2+kk"}},
		{AdminPath: praha6},
		{AdminPath: praha6, Kinds: []string{"apartment"}, RentMax: ptr(int64(1_800_000)), Attributes: map[string]search.AttrFilter{"pets": {Values: []string{"dogs"}}}},
		{BBox: []float64{14.38, 50.07, 14.45, 50.11}},
		{Attributes: map[string]search.AttrFilter{"balcony": {Bool: &yes}, "elevator": {Bool: &yes}}},
		{Attributes: map[string]search.AttrFilter{"furnished": {Values: []string{"full"}}, "floor": {Min: ptr(2.0)}}},
		{Text: "dejvice"},
		{Kinds: []string{"room"}, Sort: "price_asc"},
		{AreaMin: ptr(60.0), Sort: "area_desc", Offset: 48},
		{Kinds: []string{"apartment", "house"}, RentMin: ptr(int64(2_500_000)), Sort: "price_desc"},
	}
	engine := &search.Engine{Pool: pool}
	var durations []time.Duration
	for round := 0; round < 4; round++ {
		for i, q := range queries {
			start := time.Now()
			res, err := engine.Search(ctx, q, schema)
			if err != nil {
				t.Fatalf("%+v: %v", q, err)
			}
			durations = append(durations, time.Since(start))
			if round == 0 && i == 0 && res.Total < 50_000 {
				t.Fatalf("expected at least 50k listings, got %d", res.Total)
			}
		}
	}
	sort.Slice(durations, func(i, j int) bool { return durations[i] < durations[j] })
	p95 := durations[len(durations)*95/100]
	t.Logf("search over 50k listings: p50 %v, p95 %v, max %v", durations[len(durations)/2], p95, durations[len(durations)-1])
	if p95 > 300*time.Millisecond {
		t.Fatalf("p95 %v exceeds 300 ms", p95)
	}
}
