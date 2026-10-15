package search

import (
	"context"
	"errors"
	"math"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"

	"github.com/terrareality/terrareality/services/api/internal/catalog"
)

func testSchema(t *testing.T) *catalog.Schema {
	t.Helper()
	c, err := catalog.Embedded()
	if err != nil {
		t.Fatal(err)
	}
	return c.Schema()
}

func f(v float64) *float64 { return &v }

func TestValidateRejectsBadQueries(t *testing.T) {
	schema := testSchema(t)
	yes := true
	for name, q := range map[string]Query{
		"admin path injection":  {AdminPath: "cz.praha'; DROP"},
		"admin path empty part": {AdminPath: "cz..praha"},
		"bbox length":           {BBox: []float64{1, 2, 3}},
		"bbox inverted":         {BBox: []float64{15, 50, 14, 51}},
		"bbox out of range":     {BBox: []float64{-200, 50, 14, 51}},
		"bbox NaN":              {BBox: []float64{math.NaN(), 50, 14, 51}},
		"area infinite":         {AreaMin: f(math.Inf(1))},
		"min on bool":           {Attributes: map[string]AttrFilter{"balcony": {Min: f(1)}}},
		"max on enum":           {Attributes: map[string]AttrFilter{"heating": {Max: f(3)}}},
		"bool on int":           {Attributes: map[string]AttrFilter{"floor": {Bool: &yes}}},
		"NaN bound":             {Attributes: map[string]AttrFilter{"floor": {Min: f(math.NaN())}}},
	} {
		err := q.Validate(schema)
		var inv *InvalidQueryError
		if !errors.As(err, &inv) {
			t.Errorf("%s: %v", name, err)
		}
	}
	if err := (Query{Attributes: map[string]AttrFilter{"nope": {}}}).Validate(schema); err == nil ||
		!strings.Contains(err.Error(), "unknown attribute") {
		t.Fatalf("unknown attribute: %v", err)
	}
}

func TestValidateAcceptsGoodQueries(t *testing.T) {
	schema := testSchema(t)
	yes := true
	for name, q := range map[string]Query{
		"empty":      {},
		"admin path": {AdminPath: "cz.hlavni_mesto_praha.praha_6"},
		"bbox":       {BBox: []float64{14.2, 49.9, 14.7, 50.2}},
		"int range":  {Attributes: map[string]AttrFilter{"floor": {Min: f(1), Max: f(5)}}},
		"bool":       {Attributes: map[string]AttrFilter{"balcony": {Bool: &yes}}},
		"enum":       {Attributes: map[string]AttrFilter{"heating": {Values: []string{"gas"}}}},
	} {
		if err := q.Validate(schema); err != nil {
			t.Errorf("%s: %v", name, err)
		}
	}
}

func TestBuildGuardsNumericCast(t *testing.T) {
	b, err := build(Query{Attributes: map[string]AttrFilter{"floor": {Min: f(2)}}}, testSchema(t), "")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(b.sql(), "jsonb_typeof") {
		t.Fatalf("numeric filter casts without a type guard: %s", b.sql())
	}
	if _, err := build(Query{Attributes: map[string]AttrFilter{"balcony": {Min: f(1)}}}, testSchema(t), ""); err == nil {
		t.Fatal("numeric bound on a bool attribute built")
	}
}

func TestDigestUsesFirstPublication(t *testing.T) {
	since := time.Now()
	b, err := build(Query{PublishedAfter: &since}, testSchema(t), "")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(b.sql(), "first_published_at") || strings.Contains(b.sql(), "s.published_at >") {
		t.Fatalf("digest filter: %s", b.sql())
	}
}

func TestAsInvalidMapsDataErrors(t *testing.T) {
	var inv *InvalidQueryError
	if !errors.As(asInvalid(&pgconn.PgError{Code: "22P02", Message: "invalid input syntax"}), &inv) {
		t.Fatal("data exception not mapped to 400")
	}
	if !errors.As(asInvalid(&pgconn.PgError{Code: "42601", Message: "syntax error"}), &inv) {
		t.Fatal("ltree syntax error not mapped")
	}
	if errors.As(asInvalid(&pgconn.PgError{Code: "53300", Message: "too many connections"}), &inv) {
		t.Fatal("server error mapped to 400")
	}
}

func TestEngineSlotsBoundParallelism(t *testing.T) {
	e := &Engine{MaxParallel: 2}
	ctx := t.Context()
	r1, err := e.acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	r2, err := e.acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	done, cancel := ctxWithTimeout(t, 50*time.Millisecond)
	defer cancel()
	if _, err := e.acquire(done); err == nil {
		t.Fatal("third slot granted beyond MaxParallel")
	}
	r1()
	r3, err := e.acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	r2()
	r3()
}

func ctxWithTimeout(t *testing.T, d time.Duration) (context.Context, context.CancelFunc) {
	t.Helper()
	return context.WithTimeout(t.Context(), d)
}
