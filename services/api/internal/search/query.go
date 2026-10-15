package search

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"regexp"
	"slices"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/sync/errgroup"

	"github.com/terrareality/terrareality/services/api/internal/catalog"
)

// AttrFilter filters one attribute: Values for enum/set (any of), Bool for
// booleans, Min/Max for numbers.
type AttrFilter struct {
	Values []string `json:"values,omitempty"`
	Bool   *bool    `json:"bool,omitempty"`
	Min    *float64 `json:"min,omitempty"`
	Max    *float64 `json:"max,omitempty"`
}

// Query is a search request. All fields are optional.
type Query struct {
	Text       string                `json:"text,omitempty"`
	Kinds      []string              `json:"kinds,omitempty"`
	RentMin    *int64                `json:"rent_min,omitempty"` // minor units
	RentMax    *int64                `json:"rent_max,omitempty"`
	AreaMin    *float64              `json:"area_min,omitempty"`
	AreaMax    *float64              `json:"area_max,omitempty"`
	Layouts    []string              `json:"layouts,omitempty"`
	AdminPath  string                `json:"admin_path,omitempty"`
	BBox       []float64             `json:"bbox,omitempty"` // west, south, east, north
	Attributes map[string]AttrFilter `json:"attributes,omitempty"`
	Sort       string                `json:"sort,omitempty"` // relevance | price_asc | price_desc | newest | area_desc
	Limit      int                   `json:"limit,omitempty"`
	// PublishedAfter limits to new listings (saved-search digests; not exposed in the API).
	PublishedAfter *time.Time `json:"-"`
	Offset         int        `json:"offset,omitempty"`
}

// Card is one result row.
type Card struct {
	ListingID        uuid.UUID
	UnitKind         string
	Layout           *string
	RentAmount       int64
	Currency         string
	FloorArea        *float64
	Title            map[string]string
	City             string
	CityPart         *string
	Lat, Lng         float64
	CoverKey         *string
	CoverOrientation int32
	PublishedAt      time.Time
	Promoted         bool // paid top placement running now (M7)
	Highlighted      bool // paid visual highlight running now (M7)
}

// FacetValue is a count per attribute value.
type FacetValue struct {
	Value string
	Count int
}

// Area is an aggregate for a child administrative unit (map drill-down).
type Area struct {
	Path       string
	Name       string
	Level      int16
	Count      int
	MedianRent int64
	Lat, Lng   float64
}

// Point is a lightweight map marker.
type Point struct {
	ListingID  uuid.UUID
	Lat, Lng   float64
	RentAmount int64
}

// Result is the full answer.
type Result struct {
	Total   int
	Items   []Card
	Facets  map[string][]FacetValue
	RentMin int64
	RentMax int64
	Areas   []Area
	Points  []Point
}

// MaxPoints bounds markers returned for the map.
const MaxPoints = 2000

// InvalidQueryError is a search request the database cannot run (bad
// filter values); handlers answer 400.
type InvalidQueryError struct{ Reason string }

func (e *InvalidQueryError) Error() string { return "invalid search: " + e.Reason }

func invalid(format string, a ...any) error {
	return &InvalidQueryError{Reason: fmt.Sprintf(format, a...)}
}

// adminPathRe matches an ltree path of administrative units ("cz.praha.praha_2").
var adminPathRe = regexp.MustCompile(`^[A-Za-z0-9_]{1,64}(\.[A-Za-z0-9_]{1,64}){0,15}$`)

// Validate rejects values that would make the SQL fail (and the API answer
// 500): malformed admin paths, out-of-range or inverted bounding boxes, NaN
// bounds and numeric bounds on non-numeric attributes.
func (q Query) Validate(schema *catalog.Schema) error {
	if q.AdminPath != "" && !adminPathRe.MatchString(q.AdminPath) {
		return invalid("admin_path %q is not a valid area path", q.AdminPath)
	}
	if len(q.BBox) != 0 {
		if len(q.BBox) != 4 {
			return invalid("bbox needs west, south, east, north")
		}
		for _, v := range q.BBox {
			if math.IsNaN(v) || math.IsInf(v, 0) {
				return invalid("bbox values must be finite")
			}
		}
		w, so, e, n := q.BBox[0], q.BBox[1], q.BBox[2], q.BBox[3]
		if w < -180 || e > 180 || so < -90 || n > 90 || w > e || so > n {
			return invalid("bbox out of range")
		}
	}
	for _, f := range []*float64{q.AreaMin, q.AreaMax} {
		if f != nil && (math.IsNaN(*f) || math.IsInf(*f, 0)) {
			return invalid("area bounds must be finite")
		}
	}
	for k, f := range q.Attributes {
		a, ok := schema.Get(k)
		if !ok {
			return fmt.Errorf("unknown attribute %q", k)
		}
		if f.Min != nil || f.Max != nil {
			if a.Type != "int" && a.Type != "range" {
				return invalid("attribute %q has no numeric range", k)
			}
			for _, v := range []*float64{f.Min, f.Max} {
				if v != nil && (math.IsNaN(*v) || math.IsInf(*v, 0)) {
					return invalid("attribute %q bounds must be finite", k)
				}
			}
		}
		if f.Bool != nil && a.Type != "bool" {
			return invalid("attribute %q is not a yes/no attribute", k)
		}
	}
	return nil
}

// asInvalid maps PostgreSQL errors caused by request values (syntax and
// data exceptions, class 22 and 42601) to InvalidQueryError.
func asInvalid(err error) error {
	var pe *pgconn.PgError
	if errors.As(err, &pe) && (strings.HasPrefix(pe.Code, "22") || pe.Code == "42601") {
		return invalid("%s", pe.Message)
	}
	return err
}

type builder struct {
	where []string
	args  []any
}

func (b *builder) arg(v any) string {
	b.args = append(b.args, v)
	return fmt.Sprintf("$%d", len(b.args))
}

func (b *builder) add(cond string) { b.where = append(b.where, cond) }

func (b *builder) sql() string {
	if len(b.where) == 0 {
		return "true"
	}
	return strings.Join(b.where, " AND ")
}

// build turns a query into WHERE conditions; skip names an attribute whose
// own filter is left out (disjunctive facet counts).
func build(q Query, schema *catalog.Schema, skip string) (*builder, error) {
	b := &builder{}
	if t := strings.TrimSpace(q.Text); t != "" {
		b.add("s.tsv @@ websearch_to_tsquery('simple', lower(unaccent(" + b.arg(t) + ")))")
	}
	if q.PublishedAfter != nil {
		// First publication, not the last approved version: approving an
		// edit bumps listings.published_at, and digests must not resend
		// listings the user already got as "new".
		b.add("(SELECT l.first_published_at FROM listings l WHERE l.id = s.listing_id) > " + b.arg(*q.PublishedAfter))
	}
	if len(q.Kinds) > 0 {
		b.add("s.unit_kind = ANY(" + b.arg(q.Kinds) + ")")
	}
	if q.RentMin != nil {
		b.add("s.rent_amount >= " + b.arg(*q.RentMin))
	}
	if q.RentMax != nil {
		b.add("s.rent_amount <= " + b.arg(*q.RentMax))
	}
	if q.AreaMin != nil {
		b.add("s.floor_area >= " + b.arg(*q.AreaMin))
	}
	if q.AreaMax != nil {
		b.add("s.floor_area <= " + b.arg(*q.AreaMax))
	}
	if len(q.Layouts) > 0 && skip != "layout" {
		b.add("s.layout = ANY(" + b.arg(q.Layouts) + ")")
	}
	if q.AdminPath != "" {
		b.add("s.admin_path <@ " + b.arg(q.AdminPath) + "::ltree")
	}
	if len(q.BBox) == 4 {
		b.add(fmt.Sprintf("s.location && ST_MakeEnvelope(%s, %s, %s, %s, 4326)::geography",
			b.arg(q.BBox[0]), b.arg(q.BBox[1]), b.arg(q.BBox[2]), b.arg(q.BBox[3])))
	}
	keys := make([]string, 0, len(q.Attributes))
	for k := range q.Attributes {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		if k == skip {
			continue
		}
		f := q.Attributes[k]
		a, ok := schema.Get(k)
		if !ok {
			return nil, fmt.Errorf("unknown attribute %q", k)
		}
		switch {
		case f.Bool != nil:
			b.add("s.facets @> " + b.arg([]string{fmt.Sprintf("%s=%t", k, *f.Bool)}))
		case len(f.Values) > 0 && (a.Type == "set" || a.Type == "enum"):
			toks := make([]string, len(f.Values))
			for i, v := range f.Values {
				toks[i] = k + "=" + v
			}
			b.add("s.facets && " + b.arg(toks))
		}
		if (f.Min != nil || f.Max != nil) && a.Type != "int" && a.Type != "range" {
			return nil, invalid("attribute %q has no numeric range", k)
		}
		// jsonb_typeof guards the cast against values of another type.
		if f.Min != nil {
			b.add("(CASE WHEN jsonb_typeof(s.attributes -> " + b.arg(k) + ") = 'number' THEN (s.attributes ->> " +
				b.arg(k) + ")::numeric END) >= " + b.arg(*f.Min))
		}
		if f.Max != nil {
			b.add("(CASE WHEN jsonb_typeof(s.attributes -> " + b.arg(k) + ") = 'number' THEN (s.attributes ->> " +
				b.arg(k) + ")::numeric END) <= " + b.arg(*f.Max))
		}
	}
	return b, nil
}

// promotedCol is true while a paid top placement runs.
const promotedCol = "(s.boosted_until IS NOT NULL AND s.boosted_until > now())"

// highlightedCol is true while a paid visual highlight runs.
const highlightedCol = "(s.highlighted_until IS NOT NULL AND s.highlighted_until > now())"

// cardCols are the columns scanned by scanCard.
const cardCols = `s.listing_id, s.unit_kind, s.layout, s.rent_amount, s.currency, s.floor_area::float8, s.title, s.city, s.city_part,
		ST_Y(s.location::geometry), ST_X(s.location::geometry), s.cover_key, s.cover_orientation, s.published_at, ` +
	promotedCol + `, ` + highlightedCol

func scanCard(rows pgx.Rows) (Card, error) {
	var c Card
	var title []byte
	if err := rows.Scan(&c.ListingID, &c.UnitKind, &c.Layout, &c.RentAmount, &c.Currency, &c.FloorArea, &title, &c.City,
		&c.CityPart, &c.Lat, &c.Lng, &c.CoverKey, &c.CoverOrientation, &c.PublishedAt, &c.Promoted, &c.Highlighted); err != nil {
		return c, err
	}
	_ = json.Unmarshal(title, &c.Title)
	return c, nil
}

// orderBy returns the ORDER BY clause. Paid top placement (M7) only reorders
// the default and relevance sorts: currently boosted listings come first,
// then the usual order. An explicit sort chosen by the user (price, area,
// newest) is kept as is, so promotion never overrides what the user asked
// for; boosted items in those sorts still carry the transparent "Promoted"
// label (Card.Promoted).
func orderBy(q Query, b *builder) string {
	switch q.Sort {
	case "price_asc":
		return "s.rent_amount ASC, s.published_at DESC"
	case "price_desc":
		return "s.rent_amount DESC, s.published_at DESC"
	case "area_desc":
		return "s.floor_area DESC NULLS LAST, s.published_at DESC"
	case "newest":
		return "s.published_at DESC"
	}
	if t := strings.TrimSpace(q.Text); t != "" {
		return promotedCol + " DESC, ts_rank(s.tsv, websearch_to_tsquery('simple', lower(unaccent(" + b.arg(t) + ")))) DESC, s.published_at DESC"
	}
	return promotedCol + " DESC, s.published_at DESC"
}

// Engine runs searches.
type Engine struct {
	Pool *pgxpool.Pool
	// MaxParallel caps the read transactions all searches together hold at
	// once (default: a quarter of the pool, at least 2). One search runs
	// five parts; without the cap a burst of searches takes the whole pool
	// and starves every other request.
	MaxParallel int

	semOnce sync.Once
	sem     chan struct{}
}

func (e *Engine) slots() chan struct{} {
	e.semOnce.Do(func() {
		n := e.MaxParallel
		if n <= 0 {
			n = 2
			if e.Pool != nil {
				if m := int(e.Pool.Config().MaxConns) / 4; m > n {
					n = m
				}
			}
		}
		e.sem = make(chan struct{}, n)
	})
	return e.sem
}

// acquire takes one database slot for a search part.
func (e *Engine) acquire(ctx context.Context) (func(), error) {
	sem := e.slots()
	select {
	case sem <- struct{}{}:
		return func() { <-sem }, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

// Search runs the query with facets, aggregates and map points.
func (e *Engine) Search(ctx context.Context, q Query, schema *catalog.Schema) (Result, error) {
	if q.Limit <= 0 || q.Limit > 100 {
		q.Limit = 24
	}
	if q.Offset < 0 || q.Offset > 10_000 {
		q.Offset = 0
	}
	if err := q.Validate(schema); err != nil {
		return Result{}, err
	}
	b, err := build(q, schema, "")
	if err != nil {
		return Result{}, err
	}
	res := Result{Facets: map[string][]FacetValue{}}
	// The parts are independent read-only queries; running them on separate
	// connections in parallel roughly halves latency on a multi-core database.
	// They may see data a few milliseconds apart, which is fine for search.
	var parts [5]Result
	for i := range parts {
		parts[i].Facets = map[string][]FacetValue{}
	}
	g, gctx := errgroup.WithContext(ctx)
	run := func(i int, fn func(ctx context.Context, tx pgx.Tx, r *Result) error) {
		g.Go(func() error {
			release, err := e.acquire(gctx)
			if err != nil {
				return err
			}
			defer release()
			return pgx.BeginTxFunc(gctx, e.Pool, pgx.TxOptions{AccessMode: pgx.ReadOnly}, func(tx pgx.Tx) error {
				return fn(gctx, tx, &parts[i])
			})
		})
	}
	run(0, func(ctx context.Context, tx pgx.Tx, r *Result) error {
		err := tx.QueryRow(ctx, "SELECT count(*), coalesce(min(rent_amount), 0), coalesce(max(rent_amount), 0) FROM listing_search s WHERE "+
			b.sql(), b.args...).Scan(&r.Total, &r.RentMin, &r.RentMax)
		if err != nil {
			return fmt.Errorf("count: %w", err)
		}
		return nil
	})
	run(1, func(ctx context.Context, tx pgx.Tx, r *Result) error { return e.items(ctx, tx, q, b, r) })
	run(2, func(ctx context.Context, tx pgx.Tx, r *Result) error { return e.facets(ctx, tx, q, schema, r) })
	run(3, func(ctx context.Context, tx pgx.Tx, r *Result) error { return e.areas(ctx, tx, q, b, r) })
	run(4, func(ctx context.Context, tx pgx.Tx, r *Result) error { return e.points(ctx, tx, b, r) })
	if err := g.Wait(); err != nil {
		return Result{}, asInvalid(err)
	}
	res.Total, res.RentMin, res.RentMax = parts[0].Total, parts[0].RentMin, parts[0].RentMax
	res.Items, res.Facets, res.Areas, res.Points = parts[1].Items, parts[2].Facets, parts[3].Areas, parts[4].Points
	return res, nil
}

func (e *Engine) items(ctx context.Context, tx pgx.Tx, q Query, base *builder, res *Result) error {
	b := &builder{where: base.where, args: slices.Clone(base.args)}
	order := orderBy(q, b)
	sql := `SELECT ` + cardCols + `
		FROM listing_search s WHERE ` + b.sql() + ` ORDER BY ` + order +
		` LIMIT ` + b.arg(q.Limit) + ` OFFSET ` + b.arg(q.Offset)
	rows, err := tx.Query(ctx, sql, b.args...)
	if err != nil {
		return fmt.Errorf("items: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		c, err := scanCard(rows)
		if err != nil {
			return err
		}
		res.Items = append(res.Items, c)
	}
	return rows.Err()
}

// facets counts values of filterable enum/set/bool attributes and layouts.
// Each facet ignores its own filter, so users see alternatives.
func (e *Engine) facets(ctx context.Context, tx pgx.Tx, q Query, schema *catalog.Schema, res *Result) error {
	var keys []string
	for _, a := range schema.Attrs {
		if a.Filter && (a.Type == "enum" || a.Type == "set" || a.Type == "bool") && a.Key != "layout" {
			keys = append(keys, a.Key)
		}
	}
	// Facets of attributes without their own filter share one query.
	shared, err := build(q, schema, "")
	if err != nil {
		return err
	}
	var own []string
	var plain []string
	for _, k := range keys {
		if _, filtered := q.Attributes[k]; filtered {
			own = append(own, k)
		} else {
			plain = append(plain, k)
		}
	}
	if err := e.facetQuery(ctx, tx, shared, plain, res); err != nil {
		return err
	}
	for _, k := range own {
		b, err := build(q, schema, k)
		if err != nil {
			return err
		}
		if err := e.facetQuery(ctx, tx, b, []string{k}, res); err != nil {
			return err
		}
	}
	// Layout facet ignores the layout filter.
	lb, err := build(q, schema, "layout")
	if err != nil {
		return err
	}
	rows, err := tx.Query(ctx, "SELECT s.layout, count(*) FROM listing_search s WHERE "+lb.sql()+
		" AND s.layout IS NOT NULL GROUP BY s.layout ORDER BY count(*) DESC", lb.args...)
	if err != nil {
		return fmt.Errorf("layout facet: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		var fv FacetValue
		if err := rows.Scan(&fv.Value, &fv.Count); err != nil {
			return err
		}
		res.Facets["layout"] = append(res.Facets["layout"], fv)
	}
	return rows.Err()
}

func (e *Engine) facetQuery(ctx context.Context, tx pgx.Tx, base *builder, keys []string, res *Result) error {
	if len(keys) == 0 {
		return nil
	}
	want := map[string]bool{}
	for _, k := range keys {
		want[k] = true
	}
	b := &builder{where: base.where, args: slices.Clone(base.args)}
	rows, err := tx.Query(ctx, `SELECT tok, count(*) FROM listing_search s CROSS JOIN LATERAL unnest(s.facets) tok
		WHERE `+b.sql()+` GROUP BY tok`, b.args...)
	if err != nil {
		return fmt.Errorf("facets: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		var tok string
		var n int
		if err := rows.Scan(&tok, &n); err != nil {
			return err
		}
		k, v, ok := strings.Cut(tok, "=")
		if ok && want[k] {
			res.Facets[k] = append(res.Facets[k], FacetValue{Value: v, Count: n})
		}
	}
	if err := rows.Err(); err != nil {
		return err
	}
	for k := range want {
		sort.Slice(res.Facets[k], func(i, j int) bool { return res.Facets[k][i].Count > res.Facets[k][j].Count })
	}
	return nil
}

// areas aggregates results per child unit of the selected area (regions
// when none is selected) for the drill-down map.
func (e *Engine) areas(ctx context.Context, tx pgx.Tx, q Query, base *builder, res *Result) error {
	b := &builder{where: base.where, args: slices.Clone(base.args)}
	var scope string
	if q.AdminPath == "" {
		scope = "a.level = 1"
	} else {
		p := b.arg(q.AdminPath)
		scope = "a.path <@ " + p + "::ltree AND nlevel(a.path) = nlevel(" + p + "::ltree) + 1"
	}
	sql := `SELECT a.path::text, a.name, a.level, count(*)::int,
		percentile_cont(0.5) WITHIN GROUP (ORDER BY s.rent_amount)::bigint, ST_Y(a.centroid), ST_X(a.centroid)
		FROM listing_search s JOIN admin_units a ON s.admin_path <@ a.path
		WHERE ` + b.sql() + ` AND ` + scope + `
		GROUP BY a.path, a.name, a.level, a.centroid ORDER BY count(*) DESC`
	rows, err := tx.Query(ctx, sql, b.args...)
	if err != nil {
		return fmt.Errorf("areas: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		var a Area
		if err := rows.Scan(&a.Path, &a.Name, &a.Level, &a.Count, &a.MedianRent, &a.Lat, &a.Lng); err != nil {
			return err
		}
		res.Areas = append(res.Areas, a)
	}
	return rows.Err()
}

func (e *Engine) points(ctx context.Context, tx pgx.Tx, base *builder, res *Result) error {
	b := &builder{where: base.where, args: slices.Clone(base.args)}
	rows, err := tx.Query(ctx, `SELECT s.listing_id, ST_Y(s.location::geometry), ST_X(s.location::geometry), s.rent_amount
		FROM listing_search s WHERE `+b.sql()+` ORDER BY s.published_at DESC LIMIT `+b.arg(MaxPoints), b.args...)
	if err != nil {
		return fmt.Errorf("points: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		var p Point
		if err := rows.Scan(&p.ListingID, &p.Lat, &p.Lng, &p.RentAmount); err != nil {
			return err
		}
		res.Points = append(res.Points, p)
	}
	return rows.Err()
}

// Cards loads result cards by id, keeping the given order.
func (e *Engine) Cards(ctx context.Context, ids []uuid.UUID) ([]Card, error) {
	rows, err := e.Pool.Query(ctx, `SELECT `+cardCols+`
		FROM listing_search s WHERE s.listing_id = ANY($1)`, ids)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	byID := map[uuid.UUID]Card{}
	for rows.Next() {
		c, err := scanCard(rows)
		if err != nil {
			return nil, err
		}
		byID[c.ListingID] = c
	}
	out := make([]Card, 0, len(ids))
	for _, id := range ids {
		if c, ok := byID[id]; ok {
			out = append(out, c)
		}
	}
	return out, rows.Err()
}
