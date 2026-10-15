// Package search implements the public search over published listings:
// administrative hierarchy, the search index, faceted queries, aggregates
// for the map and chat-first search.
package search

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"regexp"
	"strings"
	"unicode"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/text/runes"
	"golang.org/x/text/transform"
	"golang.org/x/text/unicode/norm"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

// Levels of the administrative hierarchy.
const (
	LevelRegion       = 1 // kraj
	LevelMunicipality = 2 // obec
	LevelDistrict     = 3 // městský obvod (Praha 6)
	LevelPart         = 4 // část obce (Dejvice)
)

var nonSlug = regexp.MustCompile(`[^a-z0-9]+`)

// Slug turns "Praha 6 – Dejvice" into "praha-6-dejvice".
func Slug(s string) string {
	t := transform.Chain(norm.NFD, runes.Remove(runes.In(unicode.Mn)), norm.NFC)
	out, _, _ := transform.String(t, strings.ToLower(s))
	return strings.Trim(nonSlug.ReplaceAllString(out, "-"), "-")
}

// label makes an ltree label from a slug.
func label(s string) string { return strings.ReplaceAll(Slug(s), "-", "_") }

// Feature is one administrative unit for import.
type Feature struct {
	Code     string          `json:"code"`
	Level    int16           `json:"level"`
	Name     string          `json:"name"`
	Parent   string          `json:"parent"` // parent code, empty for regions
	Geometry json.RawMessage `json:"-"`
}

// ImportGeoJSON loads a FeatureCollection whose features carry properties
// code, level (1-4), name and parent (code). Produce it from OSM
// (admin_level 4/8/9/10) or from the RÚIAN VFR exchange format; see
// infra/README-geo.md. Paths are derived from the parent chain.
func ImportGeoJSON(ctx context.Context, pool *pgxpool.Pool, r io.Reader) (int, error) {
	var fc struct {
		Features []struct {
			Properties Feature         `json:"properties"`
			Geometry   json.RawMessage `json:"geometry"`
		} `json:"features"`
	}
	if err := json.NewDecoder(r).Decode(&fc); err != nil {
		return 0, fmt.Errorf("geojson: %w", err)
	}
	byCode := map[string]*Feature{}
	for i := range fc.Features {
		f := fc.Features[i].Properties
		f.Geometry = fc.Features[i].Geometry
		byCode[f.Code] = &f
	}
	var pathOf func(f *Feature, depth int) (string, error)
	pathOf = func(f *Feature, depth int) (string, error) {
		if depth > 6 {
			return "", fmt.Errorf("parent cycle at %s", f.Code)
		}
		own := label(f.Name)
		if f.Parent == "" {
			return "cz." + own, nil
		}
		p, ok := byCode[f.Parent]
		if !ok {
			return "", fmt.Errorf("%s: unknown parent %s", f.Code, f.Parent)
		}
		pp, err := pathOf(p, depth+1)
		return pp + "." + own, err
	}
	n := 0
	err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		for _, f := range byCode {
			path, err := pathOf(f, 0)
			if err != nil {
				return err
			}
			if err := q.UpsertAdminUnit(ctx, db.UpsertAdminUnitParams{Code: f.Code, Level: f.Level, Name: f.Name,
				Slug: Slug(f.Name), Path: path, Geojson: string(f.Geometry)}); err != nil {
				return fmt.Errorf("%s: %w", f.Code, err)
			}
			n++
		}
		_, err := q.AssignAddressAdminPaths(ctx, pgtype.Bool{})
		return err
	})
	return n, err
}

// devRegions maps municipality codes of the RÚIAN sample to regions.
var devRegions = map[int32][2]string{
	554782: {"CZ010", "Hlavní město Praha"},
	582786: {"CZ064", "Jihomoravský kraj"},
	554821: {"CZ080", "Moravskoslezský kraj"},
}

// SeedFromRuian builds an approximate hierarchy with polygons around the
// RÚIAN address points (dev and tests only; production imports real
// boundaries). It runs only when a sample municipality has no unit yet.
func SeedFromRuian(ctx context.Context, pool *pgxpool.Pool) (int, error) {
	q := db.New(pool)
	if n, err := q.CountRuianMunicipalitiesWithoutUnit(ctx); err != nil || n == 0 {
		return 0, err
	}
	munis, err := q.RuianMunicipalityHull(ctx)
	if err != nil {
		return 0, err
	}
	districts, err := q.RuianDistrictHull(ctx)
	if err != nil {
		return 0, err
	}
	parts, err := q.RuianPartHull(ctx)
	if err != nil {
		return 0, err
	}
	n := 0
	err = pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		up := func(code string, level int16, name, path, geo string) error {
			n++
			return q.UpsertAdminUnit(ctx, db.UpsertAdminUnitParams{Code: code, Level: level, Name: name, Slug: Slug(name), Path: path, Geojson: geo})
		}
		muniPath := map[int32]string{}
		for _, m := range munis {
			reg, ok := devRegions[m.MunicipalityCode]
			if !ok {
				reg = [2]string{"CZ0XX", "Ostatní"}
			}
			rpath := "cz." + label(reg[1])
			// Dev regions reuse the municipality outline (Praha is region and city).
			if err := up(reg[0], LevelRegion, reg[1], rpath, m.Geojson); err != nil {
				return err
			}
			muniPath[m.MunicipalityCode] = rpath + "." + label(m.Municipality)
			if err := up(fmt.Sprint(m.MunicipalityCode), LevelMunicipality, m.Municipality, muniPath[m.MunicipalityCode], m.Geojson); err != nil {
				return err
			}
		}
		districtPath := map[string]string{}
		for _, d := range districts {
			p := muniPath[d.MunicipalityCode] + "." + label(d.District)
			districtPath[fmt.Sprint(d.MunicipalityCode)+"/"+d.District] = p
			if err := up(fmt.Sprintf("%d-%s", d.MunicipalityCode, Slug(d.District)), LevelDistrict, d.District, p, d.Geojson); err != nil {
				return err
			}
		}
		for _, pt := range parts {
			parent, ok := districtPath[fmt.Sprint(pt.MunicipalityCode)+"/"+pt.District]
			if !ok {
				parent = muniPath[pt.MunicipalityCode]
			}
			if err := up(fmt.Sprintf("%d-%s-%s", pt.MunicipalityCode, Slug(pt.District), Slug(pt.CityPart)), LevelPart,
				pt.CityPart, parent+"."+label(pt.CityPart), pt.Geojson); err != nil {
				return err
			}
		}
		_, err := q.AssignAddressAdminPaths(ctx, pgtype.Bool{})
		return err
	})
	return n, err
}
