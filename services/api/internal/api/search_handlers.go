package api

import (
	"context"
	"encoding/json"
	"errors"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/search"
)

// toQuery converts the API query (same JSON shape) into a search query.
func toQuery(in *gen.SearchQuery) search.Query {
	var q search.Query
	if in == nil {
		return q
	}
	b, _ := json.Marshal(in)
	_ = json.Unmarshal(b, &q)
	return q
}

func fromQuery(q search.Query) gen.SearchQuery {
	var out gen.SearchQuery
	b, _ := json.Marshal(q)
	_ = json.Unmarshal(b, &out)
	return out
}

func (s *Server) runSearch(ctx context.Context, q search.Query) (gen.SearchResult, error) {
	schema, err := s.Listings.Schema(ctx)
	if err != nil {
		return gen.SearchResult{}, err
	}
	res, err := s.Engine.Search(ctx, q, schema)
	if err != nil {
		if strings.Contains(err.Error(), "unknown attribute") {
			return gen.SearchResult{}, apperr.BadRequest("unknown_attribute", err.Error())
		}
		var inv *search.InvalidQueryError
		if errors.As(err, &inv) {
			return gen.SearchResult{}, apperr.BadRequest("invalid_query", inv.Reason)
		}
		return gen.SearchResult{}, err
	}
	out := gen.SearchResult{Total: res.Total, RentMin: res.RentMin, RentMax: res.RentMax,
		Items: []gen.ListingCard{}, Facets: map[string][]gen.FacetCount{}, Areas: []gen.AreaAggregate{}, Points: []gen.MapPoint{}}
	for _, c := range res.Items {
		out.Items = append(out.Items, s.card(c))
	}
	for k, vs := range res.Facets {
		for _, v := range vs {
			out.Facets[k] = append(out.Facets[k], gen.FacetCount{Value: v.Value, Count: v.Count})
		}
	}
	for _, a := range res.Areas {
		out.Areas = append(out.Areas, gen.AreaAggregate{Path: a.Path, Name: a.Name, Level: int(a.Level), Count: a.Count,
			MedianRent: a.MedianRent, Lat: a.Lat, Lng: a.Lng})
	}
	for _, p := range res.Points {
		out.Points = append(out.Points, gen.MapPoint{Id: p.ListingID, Lat: p.Lat, Lng: p.Lng, RentAmount: p.RentAmount})
	}
	return out, nil
}

func (s *Server) card(c search.Card) gen.ListingCard {
	out := gen.ListingCard{Id: c.ListingID, UnitKind: gen.UnitKind(c.UnitKind), Layout: c.Layout, RentAmount: c.RentAmount,
		Currency: c.Currency, FloorArea: c.FloorArea, Title: gen.I18nText{Cs: c.Title["cs"], En: c.Title["en"]},
		City: c.City, CityPart: c.CityPart, Lat: c.Lat, Lng: c.Lng, PublishedAt: c.PublishedAt,
		Promoted: c.Promoted, Highlighted: c.Highlighted}
	if c.CoverKey != nil {
		u := s.Listings.PhotoURLs(*c.CoverKey, c.CoverOrientation)["thumb"]
		out.CoverUrl = &u
	}
	return out
}

// Search implements POST /v1/search.
func (s *Server) Search(ctx context.Context, r gen.SearchRequestObject) (gen.SearchResponseObject, error) {
	if err := s.searchLimit(ctx); err != nil {
		return nil, err
	}
	res, err := s.runSearch(ctx, toQuery(r.Body))
	if err != nil {
		return nil, err
	}
	return gen.Search200JSONResponse(res), nil
}

// ChatSearch implements POST /v1/search/chat.
func (s *Server) ChatSearch(ctx context.Context, r gen.ChatSearchRequestObject) (gen.ChatSearchResponseObject, error) {
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	schema, err := s.Listings.Schema(ctx)
	if err != nil {
		return nil, err
	}
	locale := "cs"
	if r.Body.Locale != nil {
		locale = string(*r.Body.Locale)
	}
	out := s.Chat.Ask(ctx, r.Body.Message, toQuery(r.Body.Query), schema, locale)
	res, err := s.runSearch(ctx, out.Query)
	if err != nil {
		return nil, err
	}
	resp := gen.ChatSearch200JSONResponse{Query: fromQuery(out.Query), Reply: out.Reply, Model: out.Model,
		Degraded: out.Degraded, Result: res}
	if out.Place != nil {
		resp.Place = &gen.Place{Path: out.Place.Path, Name: out.Place.Name, Bbox: out.Place.BBox}
	}
	return resp, nil
}

// ListAreas implements GET /v1/areas.
func (s *Server) ListAreas(ctx context.Context, r gen.ListAreasRequestObject) (gen.ListAreasResponseObject, error) {
	parent := ""
	if r.Params.Parent != nil {
		parent = *r.Params.Parent
	}
	rows, err := db.New(s.pool).ListAdminChildren(ctx, db.ListAdminChildrenParams{Parent: parent, Tolerance: 0.0005})
	if err != nil {
		return nil, err
	}
	out := gen.ListAreas200JSONResponse{}
	for _, a := range rows {
		var g map[string]any
		_ = json.Unmarshal([]byte(a.Geojson), &g)
		out = append(out, gen.Area{Path: a.Path, Name: a.Name, Slug: a.Slug, Level: int(a.Level), Lat: a.Lat, Lng: a.Lng, Geometry: g})
	}
	return out, nil
}

// publicSnapshot is the subset of listing.Snapshot shown publicly.
type publicSnapshot struct {
	Title             gen.I18nText   `json:"title"`
	Description       gen.I18nText   `json:"description"`
	RentAmount        int64          `json:"rent_amount"`
	DepositAmount     *int64         `json:"deposit_amount"`
	UtilitiesAmount   *int64         `json:"utilities_amount"`
	Currency          string         `json:"currency"`
	AvailableFrom     *string        `json:"available_from"`
	MinTermMonths     *int32         `json:"min_term_months"`
	Attributes        map[string]any `json:"attributes"`
	LocationPrecision string         `json:"location_precision"`
	Unit              struct {
		Kind      string   `json:"kind"`
		Layout    *string  `json:"layout"`
		Floor     *int32   `json:"floor"`
		FloorArea *float64 `json:"floor_area"`
	} `json:"unit"`
	Address struct {
		Label string `json:"label"`
	} `json:"address"`
	Photos []struct {
		Key         string `json:"key"`
		Orientation int32  `json:"orientation"`
	} `json:"photos"`
}

// GetPublicListing implements GET /v1/listings/{listingId}.
func (s *Server) GetPublicListing(ctx context.Context, r gen.GetPublicListingRequestObject) (gen.GetPublicListingResponseObject, error) {
	q := db.New(s.pool)
	row, err := q.GetPublicListing(ctx, r.ListingId)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperr.NotFound("listing_not_found", "listing not found")
	}
	if err != nil {
		return nil, err
	}
	var snap publicSnapshot
	if err := json.Unmarshal(row.Snapshot, &snap); err != nil {
		return nil, err
	}
	out := gen.GetPublicListing200JSONResponse{Id: row.ListingID, Prescreen: prescreenOf(row.Prescreen), Title: snap.Title, Description: snap.Description,
		RentAmount: snap.RentAmount, DepositAmount: snap.DepositAmount, UtilitiesAmount: snap.UtilitiesAmount,
		Currency: snap.Currency, MinTermMonths: snap.MinTermMonths, Attributes: snap.Attributes, PublishedAt: row.PublishedAt,
		Photos: []gen.PhotoVariants{}, AreaNames: []string{}}
	if out.Attributes == nil {
		out.Attributes = map[string]any{}
	}
	if snap.AvailableFrom != nil {
		var d openapi_types.Date
		if d.UnmarshalText([]byte(*snap.AvailableFrom)) == nil {
			out.AvailableFrom = &d
		}
	}
	out.Unit.Kind, out.Unit.Layout, out.Unit.Floor, out.Unit.FloorArea = gen.UnitKind(snap.Unit.Kind), snap.Unit.Layout, snap.Unit.Floor, snap.Unit.FloorArea
	out.Location.Lat, out.Location.Lng = row.Lat, row.Lng
	out.Location.Precision = gen.PublicListingLocationPrecisionApproximate
	if snap.LocationPrecision == "exact" {
		out.Location.Precision = gen.PublicListingLocationPrecisionExact
		out.Location.Address = &snap.Address.Label
	}
	for _, p := range snap.Photos {
		u := s.Listings.PhotoURLs(p.Key, p.Orientation)
		out.Photos = append(out.Photos, gen.PhotoVariants{Thumb: u["thumb"], Medium: u["medium"], Large: u["large"]})
	}
	if row.AdminPath != "" {
		labels := strings.Split(row.AdminPath, ".")
		for i := 2; i <= len(labels); i++ {
			if a, err := q.GetAdminUnit(ctx, strings.Join(labels[:i], ".")); err == nil {
				out.AreaNames = append(out.AreaNames, a.Name)
			}
		}
	}
	return out, nil
}

// GetSimilarListings implements GET /v1/listings/{listingId}/similar.
func (s *Server) GetSimilarListings(ctx context.Context, r gen.GetSimilarListingsRequestObject) (gen.GetSimilarListingsResponseObject, error) {
	q := db.New(s.pool)
	ids, err := q.SimilarByEmbedding(ctx, db.SimilarByEmbeddingParams{ListingID: r.ListingId, Limit: 6})
	if err != nil {
		return nil, err
	}
	if len(ids) == 0 {
		if ids, err = q.SimilarByAttributes(ctx, db.SimilarByAttributesParams{ListingID: r.ListingId, Limit: 6}); err != nil {
			return nil, err
		}
	}
	out := gen.GetSimilarListings200JSONResponse{}
	if len(ids) == 0 {
		return out, nil
	}
	cards, err := s.Engine.Cards(ctx, ids)
	if err != nil {
		return nil, err
	}
	for _, c := range cards {
		out = append(out, s.card(c))
	}
	return out, nil
}

// ListSeoMunicipalities implements GET /v1/seo/municipalities.
func (s *Server) ListSeoMunicipalities(ctx context.Context, r gen.ListSeoMunicipalitiesRequestObject) (gen.ListSeoMunicipalitiesResponseObject, error) {
	var kind *string
	if r.Params.Kind != nil {
		k := string(*r.Params.Kind)
		kind = &k
	}
	rows, err := db.New(s.pool).MunicipalitiesWithListings(ctx, kind)
	if err != nil {
		return nil, err
	}
	out := gen.ListSeoMunicipalities200JSONResponse{}
	for _, m := range rows {
		out = append(out, gen.MunicipalityStat{Name: m.Name, Slug: m.Slug, Path: m.Path, Listings: int(m.Listings), MedianRent: m.MedianRent})
	}
	return out, nil
}

func savedDTO(x db.SavedSearch) gen.SavedSearch {
	var q gen.SearchQuery
	_ = json.Unmarshal(x.Query, &q)
	return gen.SavedSearch{Id: x.ID, Name: x.Name, Query: q, Notify: x.Notify, CreatedAt: x.CreatedAt}
}

// ListSavedSearches implements GET /v1/me/saved-searches.
func (s *Server) ListSavedSearches(ctx context.Context, _ gen.ListSavedSearchesRequestObject) (gen.ListSavedSearchesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	out := gen.ListSavedSearches200JSONResponse{}
	err = platformdb.AsUser(ctx, s.pool, p.UserID, func(tx pgx.Tx) error {
		rows, err := db.New(tx).ListSavedSearches(ctx, p.UserID)
		for _, x := range rows {
			out = append(out, savedDTO(x))
		}
		return err
	})
	return out, err
}

// CreateSavedSearch implements POST /v1/me/saved-searches.
func (s *Server) CreateSavedSearch(ctx context.Context, r gen.CreateSavedSearchRequestObject) (gen.CreateSavedSearchResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	notify := r.Body.Notify == nil || *r.Body.Notify
	sq := toQuery(&r.Body.Query)
	schema, err := s.Listings.Schema(ctx)
	if err != nil {
		return nil, err
	}
	// A query the digest could never run is refused up front.
	if err := sq.Validate(schema); err != nil {
		var inv *search.InvalidQueryError
		if errors.As(err, &inv) {
			return nil, apperr.BadRequest("invalid_query", inv.Reason)
		}
		return nil, apperr.BadRequest("unknown_attribute", err.Error())
	}
	q, _ := json.Marshal(sq)
	var out db.SavedSearch
	err = platformdb.AsUser(ctx, s.pool, p.UserID, func(tx pgx.Tx) error {
		var err error
		out, err = db.New(tx).CreateSavedSearch(ctx, db.CreateSavedSearchParams{UserID: p.UserID, Name: r.Body.Name, Query: q, Notify: notify})
		return err
	})
	if err != nil {
		return nil, err
	}
	return gen.CreateSavedSearch201JSONResponse(savedDTO(out)), nil
}

// DeleteSavedSearch implements DELETE /v1/me/saved-searches/{savedSearchId}.
func (s *Server) DeleteSavedSearch(ctx context.Context, r gen.DeleteSavedSearchRequestObject) (gen.DeleteSavedSearchResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var n int64
	err = platformdb.AsUser(ctx, s.pool, p.UserID, func(tx pgx.Tx) error {
		var err error
		n, err = db.New(tx).DeleteSavedSearch(ctx, db.DeleteSavedSearchParams{ID: r.SavedSearchId, UserID: p.UserID})
		return err
	})
	if err != nil {
		return nil, err
	}
	if n == 0 {
		return nil, apperr.NotFound("saved_search_not_found", "saved search not found")
	}
	return gen.DeleteSavedSearch204Response{}, nil
}

var _ = uuid.Nil
