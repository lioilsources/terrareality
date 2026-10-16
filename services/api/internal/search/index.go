package search

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"errors"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/catalog"
	"github.com/terrareality/terrareality/services/api/internal/db"
)

// snapshot is the subset of listing.Snapshot the index reads.
type snapshot struct {
	Title       map[string]string `json:"title"`
	Description map[string]string `json:"description"`
	RentAmount  *int64            `json:"rent_amount"`
	Deposit     *int64            `json:"deposit_amount"`
	Currency    string            `json:"currency"`
	Attributes  map[string]any    `json:"attributes"`
	Unit        struct {
		Kind      string   `json:"kind"`
		Layout    *string  `json:"layout"`
		FloorArea *float64 `json:"floor_area"`
	} `json:"unit"`
	Address struct {
		City     string  `json:"city"`
		CityPart *string `json:"city_part"`
		Lat      float64 `json:"lat"`
		Lng      float64 `json:"lng"`
	} `json:"address"`
	Photos []struct {
		Key         string `json:"key"`
		Orientation int32  `json:"orientation"`
	} `json:"photos"`
}

var kindWords = map[string]string{"apartment": "byt flat apartment", "house": "dům rodinný house", "room": "pokoj spolubydlení room",
	"parking": "parkování garáž parking", "storage": "sklad storage", "commercial": "komerční prostor office commercial"}

// Indexer keeps listing_search in sync with published versions.
type Indexer struct{}

// Index (re)builds the row of a listing from its approved version; listings
// that are not visible (paused, rented, archived) are removed.
func (Indexer) Index(ctx context.Context, q *db.Queries, listingID uuid.UUID) error {
	src, err := q.GetIndexSource(ctx, listingID)
	if errors.Is(err, pgx.ErrNoRows) {
		return q.DeleteListingSearch(ctx, listingID)
	}
	if err != nil {
		return err
	}
	if src.Status != "published" || src.PublishedVersion == nil {
		return q.DeleteListingSearch(ctx, listingID)
	}
	var s snapshot
	if err := json.Unmarshal(src.Snapshot, &s); err != nil {
		return err
	}
	if s.RentAmount == nil {
		return q.DeleteListingSearch(ctx, listingID)
	}
	schema, err := catalog.Load(ctx, q)
	if err != nil {
		return err
	}
	lat, lng := s.Address.Lat, s.Address.Lng
	if src.LocationPrecision != "exact" {
		lat, lng = Jitter(listingID, lat, lng)
	}
	var adminPath *string
	if src.AdminPath != "" {
		adminPath = &src.AdminPath
	} else if p, err := q.AdminPathAt(ctx, db.AdminPathAtParams{Lat: s.Address.Lat, Lng: s.Address.Lng}); err == nil {
		adminPath = &p
	}
	var coverKey *string
	coverOrient := int32(1)
	if len(s.Photos) > 0 {
		coverKey, coverOrient = &s.Photos[0].Key, s.Photos[0].Orientation
	}
	title, _ := json.Marshal(s.Title)
	attrs, _ := json.Marshal(nonNilMap(s.Attributes))
	published := time.Now()
	if src.PublishedAt != nil {
		published = *src.PublishedAt
	}
	return q.UpsertListingSearch(ctx, db.UpsertListingSearchParams{ListingID: listingID, OrgID: src.OrgID,
		Version: *src.PublishedVersion, UnitKind: s.Unit.Kind, Layout: s.Unit.Layout, RentAmount: *s.RentAmount,
		Currency: s.Currency, DepositAmount: s.Deposit, FloorArea: s.Unit.FloorArea, Attributes: attrs, Title: title,
		Lat: lat, Lng: lng, AdminPath: adminPath, City: s.Address.City, CityPart: s.Address.CityPart,
		CoverKey: coverKey, CoverOrientation: coverOrient, SearchText: searchText(s, schema), PublishedAt: published,
		IsDemo: src.IsDemo})
}

// Remove drops a listing from search.
func (Indexer) Remove(ctx context.Context, q *db.Queries, listingID uuid.UUID) error {
	return q.DeleteListingSearch(ctx, listingID)
}

func nonNilMap(m map[string]any) map[string]any {
	if m == nil {
		return map[string]any{}
	}
	return m
}

// searchText collects words for fulltext: texts, place, kind and the labels
// of attribute values in both languages.
func searchText(s snapshot, schema *catalog.Schema) string {
	parts := []string{s.Title["cs"], s.Title["en"], s.Description["cs"], s.Address.City, kindWords[s.Unit.Kind]}
	if s.Address.CityPart != nil {
		parts = append(parts, *s.Address.CityPart)
	}
	if s.Unit.Layout != nil {
		parts = append(parts, *s.Unit.Layout)
	}
	for k, v := range s.Attributes {
		a, ok := schema.Get(k)
		if !ok {
			continue
		}
		switch x := v.(type) {
		case bool:
			if x {
				parts = append(parts, a.Label.CS, a.Label.EN)
			}
		case string:
			for _, o := range a.Options {
				if o.Value == x {
					parts = append(parts, o.Label.CS, o.Label.EN)
				}
			}
		case []any:
			for _, e := range x {
				for _, o := range a.Options {
					if o.Value == e {
						parts = append(parts, o.Label.CS, o.Label.EN)
					}
				}
			}
		}
	}
	return strings.Join(parts, " ")
}

// Jitter moves a point 150-350 m in a direction derived from the listing id,
// so approximate locations are stable but do not reveal the building.
func Jitter(id uuid.UUID, lat, lng float64) (float64, float64) {
	h := sha256.Sum256(id[:])
	dist := 150 + float64(binary.BigEndian.Uint16(h[0:2])%200)
	angle := float64(binary.BigEndian.Uint16(h[2:4])) / 65535 * 2 * math.Pi
	dLat := dist * math.Cos(angle) / 111_320
	dLng := dist * math.Sin(angle) / (111_320 * math.Cos(lat*math.Pi/180))
	return lat + dLat, lng + dLng
}
