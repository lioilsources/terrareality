package search

import (
	"context"
	"encoding/json"
	"fmt"
	"slices"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

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
		b.add("s.published_at > " + b.arg(*q.PublishedAfter))
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
		if f.Min != nil {
			b.add("(s.attributes ->> " + b.arg(k) + ")::numeric >= " + b.arg(*f.Min))
		}
		if f.Max != nil {
			b.add("(s.attributes ->> " + b.arg(k) + ")::numeric <= " + b.arg(*f.Max))
		}
	}
	return b, nil
}

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
		return "ts_rank(s.tsv, websearch_to_tsquery('simple', lower(unaccent(" + b.arg(t) + ")))) DESC, s.published_at DESC"
	}
	return "s.published_at DESC"
}

// Engine runs searches.
type Engine struct {
	Pool *pgxpool.Pool
}

// Search runs the query with facets, aggregates and map points.
func (e *Engine) Search(ctx context.Context, q Query, schema *catalog.Schema) (Result, error) {
	if q.Limit <= 0 || q.Limit > 100 {
		q.Limit = 24
	}
	if q.Offset < 0 || q.Offset > 10_000 {
		q.Offset = 0
	}
	b, err := build(q, schema, "")
	if err != nil {
		return Result{}, err
	}
	res := Result{Facets: map[string][]FacetValue{}}
	// One snapshot of the data for all parts of the answer.
	err = pgx.BeginTxFunc(ctx, e.Pool, pgx.TxOptions{AccessMode: pgx.ReadOnly, IsoLevel: pgx.RepeatableRead}, func(tx pgx.Tx) error {
		where := b.sql()
		if err := tx.QueryRow(ctx, "SELECT count(*), coalesce(min(rent_amount), 0), coalesce(max(rent_amount), 0) FROM listing_search s WHERE "+where,
			b.args...).Scan(&res.Total, &res.RentMin, &res.RentMax); err != nil {
			return fmt.Errorf("count: %w", err)
		}
		if err := e.items(ctx, tx, q, b, &res); err != nil {
			return err
		}
		if err := e.facets(ctx, tx, q, schema, &res); err != nil {
			return err
		}
		if err := e.areas(ctx, tx, q, b, &res); err != nil {
			return err
		}
		return e.points(ctx, tx, b, &res)
	})
	return res, err
}

func (e *Engine) items(ctx context.Context, tx pgx.Tx, q Query, base *builder, res *Result) error {
	b := &builder{where: base.where, args: slices.Clone(base.args)}
	order := orderBy(q, b)
	sql := `SELECT s.listing_id, s.unit_kind, s.layout, s.rent_amount, s.currency, s.floor_area::float8, s.title, s.city, s.city_part,
		ST_Y(s.location::geometry), ST_X(s.location::geometry), s.cover_key, s.cover_orientation, s.published_at
		FROM listing_search s WHERE ` + b.sql() + ` ORDER BY ` + order +
		` LIMIT ` + b.arg(q.Limit) + ` OFFSET ` + b.arg(q.Offset)
	rows, err := tx.Query(ctx, sql, b.args...)
	if err != nil {
		return fmt.Errorf("items: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		var c Card
		var title []byte
		if err := rows.Scan(&c.ListingID, &c.UnitKind, &c.Layout, &c.RentAmount, &c.Currency, &c.FloorArea, &title, &c.City,
			&c.CityPart, &c.Lat, &c.Lng, &c.CoverKey, &c.CoverOrientation, &c.PublishedAt); err != nil {
			return err
		}
		_ = json.Unmarshal(title, &c.Title)
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
	rows, err := e.Pool.Query(ctx, `SELECT s.listing_id, s.unit_kind, s.layout, s.rent_amount, s.currency, s.floor_area::float8, s.title,
		s.city, s.city_part, ST_Y(s.location::geometry), ST_X(s.location::geometry), s.cover_key, s.cover_orientation, s.published_at
		FROM listing_search s WHERE s.listing_id = ANY($1)`, ids)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	byID := map[uuid.UUID]Card{}
	for rows.Next() {
		var c Card
		var title []byte
		if err := rows.Scan(&c.ListingID, &c.UnitKind, &c.Layout, &c.RentAmount, &c.Currency, &c.FloorArea, &title, &c.City,
			&c.CityPart, &c.Lat, &c.Lng, &c.CoverKey, &c.CoverOrientation, &c.PublishedAt); err != nil {
			return nil, err
		}
		_ = json.Unmarshal(title, &c.Title)
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
