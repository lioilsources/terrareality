package api

import (
	"context"
	"encoding/json"
	"time"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/vision"
)

func i18nDTO(b []byte) gen.I18nText {
	var t listing.I18n
	_ = json.Unmarshal(b, &t)
	return gen.I18nText{Cs: t.CS, En: t.EN}
}

func objectOf(b []byte) map[string]any {
	m := map[string]any{}
	_ = json.Unmarshal(b, &m)
	return m
}

func (s *Server) mediaDTO(m db.Medium) gen.Media {
	out := gen.Media{Id: m.ID, Status: gen.MediaStatus(m.Status), RejectionReason: m.RejectionReason, Filename: m.Filename,
		ContentType: m.ContentType, Width: m.Width, Height: m.Height, Position: m.Position, Caption: i18nDTO(m.Caption),
		Urls: gen.PhotoUrls{}}
	if m.Status == "ready" {
		out.Urls = s.Listings.PhotoURLs(m.ObjectKey, m.Orientation)
	}
	var v vision.Analysis
	if json.Unmarshal(m.Vision, &v) == nil && v.RoomType != "" {
		out.RoomType = &v.RoomType
		out.Tags = &v.Tags
	}
	return out
}

func suggestionDTO(sg db.AiSuggestion) gen.Suggestion {
	return gen.Suggestion{Id: sg.ID, Kind: gen.SuggestionKind(sg.Kind), Status: gen.SuggestionStatus(sg.Status),
		MediaId: sg.MediaID, Payload: objectOf(sg.Payload), Model: sg.Model, Error: sg.Error, CreatedAt: sg.CreatedAt,
		DecidedAt: sg.DecidedAt}
}

func (s *Server) listingDTO(ctx context.Context, v listing.View) (gen.Listing, error) {
	l, c := v.Listing, v.Context
	out := gen.Listing{Id: l.ID, OrgId: l.OrgID, Status: gen.ListingStatus(l.Status), Title: i18nDTO(l.Title),
		Description: i18nDTO(l.Description), RentAmount: l.RentAmount, DepositAmount: l.DepositAmount,
		UtilitiesAmount: l.UtilitiesAmount, Currency: l.Currency, MinTermMonths: l.MinTermMonths, Attributes: objectOf(l.Attributes),
		LocationPrecision: gen.ListingLocationPrecision(l.LocationPrecision), PublishedVersion: l.PublishedVersion,
		PublishedAt: l.PublishedAt, CreatedAt: l.CreatedAt, UpdatedAt: l.UpdatedAt, PropertyId: c.PropertyID,
		Unit: gen.ListingUnit{Id: c.UnitID, Kind: gen.UnitKind(c.UnitKind), Label: c.UnitLabel, Floor: c.Floor,
			FloorArea: c.FloorArea, Layout: c.Layout, ParentId: c.ParentID, ParentLabel: c.ParentLabel},
		Address: gen.ListingAddress{Label: c.AddressLabel, City: c.City, CityPart: c.CityPart, PostalCode: c.PostalCode, Lat: c.Lat, Lng: c.Lng},
		Media:   []gen.Media{}, Suggestions: []gen.Suggestion{}, Versions: []gen.ListingVersionInfo{}}
	if l.AvailableFrom.Valid {
		out.AvailableFrom = &openapi_types.Date{Time: l.AvailableFrom.Time}
	}
	for _, m := range v.Media {
		out.Media = append(out.Media, s.mediaDTO(m))
	}
	for _, sg := range v.Suggestions {
		out.Suggestions = append(out.Suggestions, suggestionDTO(sg))
	}
	for _, ver := range v.Versions {
		out.Versions = append(out.Versions, gen.ListingVersionInfo{Id: ver.ID, Version: ver.Version,
			Status: gen.ListingVersionInfoStatus(ver.Status), SubmittedAt: ver.SubmittedAt, ReviewedAt: ver.ReviewedAt, ReviewNote: ver.ReviewNote})
		if ver.Status == "pending" {
			out.PendingReview = true
		}
	}
	j, err := db.New(s.pool).GetJurisdiction(ctx, c.JurisdictionCode)
	if err != nil {
		return out, err
	}
	out.DepositMaxMonths = int(j.DepositMaxMonths)
	return out, nil
}

func (s *Server) listingResponse(ctx context.Context, orgID, id openapi_types.UUID) (gen.Listing, error) {
	p, err := principal(ctx)
	if err != nil {
		return gen.Listing{}, err
	}
	v, err := s.Listings.Get(ctx, p, orgID, id)
	if err != nil {
		return gen.Listing{}, err
	}
	return s.listingDTO(ctx, v)
}

// GetAttributeSchema implements GET /v1/attributes.
func (s *Server) GetAttributeSchema(ctx context.Context, _ gen.GetAttributeSchemaRequestObject) (gen.GetAttributeSchemaResponseObject, error) {
	schema, err := s.Listings.Schema(ctx)
	if err != nil {
		return nil, err
	}
	out := gen.GetAttributeSchema200JSONResponse{Groups: []gen.AttributeGroup{}, Attributes: []gen.AttributeDef{}}
	for _, g := range schema.Groups {
		out.Groups = append(out.Groups, gen.AttributeGroup{Key: g.Key, Label: gen.I18nText{Cs: g.Label.CS, En: g.Label.EN}})
	}
	for _, a := range schema.Attrs {
		d := gen.AttributeDef{Key: a.Key, Type: gen.AttributeDefType(a.Type), Group: a.Group, Filter: a.Filter,
			Label: gen.I18nText{Cs: a.Label.CS, En: a.Label.EN}, Min: a.Min, Max: a.Max, AppliesTo: []gen.UnitKind{},
			Options: []gen.AttributeOption{}}
		if a.Unit != "" {
			u := a.Unit
			d.Unit = &u
		}
		for _, k := range a.AppliesTo {
			d.AppliesTo = append(d.AppliesTo, gen.UnitKind(k))
		}
		for _, o := range a.Options {
			src := gen.AttributeOptionSource(o.Source)
			if src == "" {
				src = gen.Catalog
			}
			d.Options = append(d.Options, gen.AttributeOption{Value: o.Value, Label: gen.I18nText{Cs: o.Label.CS, En: o.Label.EN}, Source: &src})
		}
		out.Attributes = append(out.Attributes, d)
	}
	return out, nil
}

// SearchAddresses implements GET /v1/addresses/search.
func (s *Server) SearchAddresses(ctx context.Context, r gen.SearchAddressesRequestObject) (gen.SearchAddressesResponseObject, error) {
	if err := s.searchLimit(ctx); err != nil {
		return nil, err
	}
	lim := int32(8)
	if r.Params.Limit != nil {
		lim = int32(*r.Params.Limit)
	}
	rows, err := s.Listings.SearchAddresses(ctx, r.Params.Q, lim)
	if err != nil {
		return nil, err
	}
	out := gen.SearchAddresses200JSONResponse{}
	for _, a := range rows {
		out = append(out, gen.AddressSuggestion{RuianId: a.ID, Label: a.Label, Municipality: a.Municipality, District: a.District,
			CityPart: a.CityPart, Street: a.Street, PostalCode: a.PostalCode, Lat: a.Lat, Lng: a.Lng})
	}
	return out, nil
}

// ListListings implements GET /v1/orgs/{orgId}/listings.
func (s *Server) ListListings(ctx context.Context, r gen.ListListingsRequestObject) (gen.ListListingsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var status *string
	if r.Params.Status != nil {
		st := string(*r.Params.Status)
		status = &st
	}
	rows, err := s.Listings.List(ctx, p, r.OrgId, status)
	if err != nil {
		return nil, err
	}
	out := gen.ListListings200JSONResponse{}
	for _, l := range rows {
		sum := gen.ListingSummary{Id: l.ID, Status: gen.ListingStatus(l.Status), Title: i18nDTO(l.Title), UnitKind: gen.UnitKind(l.UnitKind),
			UnitLabel: l.UnitLabel, AddressLabel: l.AddressLabel, RentAmount: l.RentAmount, Currency: l.Currency,
			PendingReview: l.PendingReview, PublishedVersion: l.PublishedVersion, UpdatedAt: l.UpdatedAt}
		if l.CoverKey != "" {
			u := s.Listings.PhotoURLs(l.CoverKey, l.CoverOrientation)["thumb"]
			sum.CoverUrl = &u
		}
		out = append(out, sum)
	}
	return out, nil
}

// CreateListing implements POST /v1/orgs/{orgId}/listings.
func (s *Server) CreateListing(ctx context.Context, r gen.CreateListingRequestObject) (gen.CreateListingResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b := r.Body
	label := ""
	if b.UnitLabel != nil {
		label = *b.UnitLabel
	}
	id, err := s.Listings.Create(ctx, p, r.OrgId, listing.CreateInput{RuianID: b.RuianId, UnitKind: string(b.UnitKind),
		UnitLabel: label, Floor: b.Floor, FloorArea: b.FloorArea, Layout: b.Layout, ParentUnitID: b.ParentUnitId,
		ParentLayout: b.ParentLayout, ParentArea: b.ParentFloorArea})
	if err != nil {
		return nil, err
	}
	l, err := s.listingResponse(ctx, r.OrgId, id)
	if err != nil {
		return nil, err
	}
	return gen.CreateListing201JSONResponse{ListingJSONResponse: gen.ListingJSONResponse(l)}, nil
}

// GetListing implements GET /v1/orgs/{orgId}/listings/{listingId}.
func (s *Server) GetListing(ctx context.Context, r gen.GetListingRequestObject) (gen.GetListingResponseObject, error) {
	l, err := s.listingResponse(ctx, r.OrgId, r.ListingId)
	if err != nil {
		return nil, err
	}
	return gen.GetListing200JSONResponse{ListingJSONResponse: gen.ListingJSONResponse(l)}, nil
}

// UpdateListing implements PUT /v1/orgs/{orgId}/listings/{listingId}.
func (s *Server) UpdateListing(ctx context.Context, r gen.UpdateListingRequestObject) (gen.UpdateListingResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b := r.Body
	in := listing.UpdateInput{Title: listing.I18n{CS: b.Title.Cs, EN: b.Title.En},
		Description: listing.I18n{CS: b.Description.Cs, EN: b.Description.En}, Rent: b.RentAmount, Deposit: b.DepositAmount,
		Utilities: b.UtilitiesAmount, MinTermMonths: b.MinTermMonths, Attributes: b.Attributes,
		LocationPrecision: string(b.LocationPrecision), UnitLabel: b.UnitLabel, Floor: b.Floor, FloorArea: b.FloorArea, Layout: b.Layout}
	if b.AvailableFrom != nil {
		t := b.AvailableFrom.Time
		in.AvailableFrom = &t
	}
	if in.Attributes == nil {
		in.Attributes = map[string]any{}
	}
	if err := s.Listings.Update(ctx, p, r.OrgId, r.ListingId, in); err != nil {
		return nil, err
	}
	l, err := s.listingResponse(ctx, r.OrgId, r.ListingId)
	if err != nil {
		return nil, err
	}
	return gen.UpdateListing200JSONResponse{ListingJSONResponse: gen.ListingJSONResponse(l)}, nil
}

// SubmitListing implements POST /v1/orgs/{orgId}/listings/{listingId}/submit.
func (s *Server) SubmitListing(ctx context.Context, r gen.SubmitListingRequestObject) (gen.SubmitListingResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.requireVerifiedEmail(ctx); err != nil {
		return nil, err
	}
	if _, err := s.Listings.Submit(ctx, p, r.OrgId, r.ListingId); err != nil {
		return nil, err
	}
	l, err := s.listingResponse(ctx, r.OrgId, r.ListingId)
	if err != nil {
		return nil, err
	}
	return gen.SubmitListing200JSONResponse{ListingJSONResponse: gen.ListingJSONResponse(l)}, nil
}

// ChangeListingStatus implements POST /v1/orgs/{orgId}/listings/{listingId}/status.
func (s *Server) ChangeListingStatus(ctx context.Context, r gen.ChangeListingStatusRequestObject) (gen.ChangeListingStatusResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Listings.Transition(ctx, p, r.OrgId, r.ListingId, string(r.Body.Status)); err != nil {
		return nil, err
	}
	l, err := s.listingResponse(ctx, r.OrgId, r.ListingId)
	if err != nil {
		return nil, err
	}
	return gen.ChangeListingStatus200JSONResponse{ListingJSONResponse: gen.ListingJSONResponse(l)}, nil
}

// DuplicateListing implements POST /v1/orgs/{orgId}/listings/{listingId}/duplicate.
func (s *Server) DuplicateListing(ctx context.Context, r gen.DuplicateListingRequestObject) (gen.DuplicateListingResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	id, err := s.Listings.Duplicate(ctx, p, r.OrgId, r.ListingId)
	if err != nil {
		return nil, err
	}
	l, err := s.listingResponse(ctx, r.OrgId, id)
	if err != nil {
		return nil, err
	}
	return gen.DuplicateListing201JSONResponse{ListingJSONResponse: gen.ListingJSONResponse(l)}, nil
}

// CreateMediaUpload implements POST /v1/orgs/{orgId}/listings/{listingId}/media.
func (s *Server) CreateMediaUpload(ctx context.Context, r gen.CreateMediaUploadRequestObject) (gen.CreateMediaUploadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	up, err := s.Listings.CreateUpload(ctx, p, r.OrgId, r.ListingId, r.Body.Filename, string(r.Body.ContentType), r.Body.Size)
	if err != nil {
		return nil, err
	}
	return gen.CreateMediaUpload201JSONResponse{Media: s.mediaDTO(up.Media), UploadUrl: up.UploadURL, ExpiresAt: up.ExpiresAt}, nil
}

// CompleteMediaUpload implements POST /v1/orgs/{orgId}/media/{mediaId}/complete.
func (s *Server) CompleteMediaUpload(ctx context.Context, r gen.CompleteMediaUploadRequestObject) (gen.CompleteMediaUploadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	m, err := s.Listings.CompleteUpload(ctx, p, r.OrgId, r.MediaId)
	if err != nil {
		return nil, err
	}
	return gen.CompleteMediaUpload200JSONResponse(s.mediaDTO(m)), nil
}

// UpdateMedia implements PATCH /v1/orgs/{orgId}/media/{mediaId}.
func (s *Server) UpdateMedia(ctx context.Context, r gen.UpdateMediaRequestObject) (gen.UpdateMediaResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	m, err := s.Listings.UpdateMedia(ctx, p, r.OrgId, r.MediaId, r.Body.Position, listing.I18n{CS: r.Body.Caption.Cs, EN: r.Body.Caption.En})
	if err != nil {
		return nil, err
	}
	return gen.UpdateMedia200JSONResponse(s.mediaDTO(m)), nil
}

// DeleteMedia implements DELETE /v1/orgs/{orgId}/media/{mediaId}.
func (s *Server) DeleteMedia(ctx context.Context, r gen.DeleteMediaRequestObject) (gen.DeleteMediaResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Listings.DeleteMedia(ctx, p, r.OrgId, r.MediaId); err != nil {
		return nil, err
	}
	return gen.DeleteMedia204Response{}, nil
}

// RequestSuggestion implements POST /v1/orgs/{orgId}/listings/{listingId}/suggestions.
func (s *Server) RequestSuggestion(ctx context.Context, r gen.RequestSuggestionRequestObject) (gen.RequestSuggestionResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.limit(ctx, "ai:"+p.UserID.String()); err != nil {
		return nil, err
	}
	sg, err := s.Listings.RequestSuggestion(ctx, p, r.OrgId, r.ListingId, string(r.Body.Kind))
	if err != nil {
		return nil, err
	}
	return gen.RequestSuggestion202JSONResponse(suggestionDTO(sg)), nil
}

// DecideSuggestion implements POST /v1/orgs/{orgId}/suggestions/{suggestionId}/decision.
func (s *Server) DecideSuggestion(ctx context.Context, r gen.DecideSuggestionRequestObject) (gen.DecideSuggestionResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	d := listing.Decision{Accept: r.Body.Accept}
	if r.Body.Keys != nil {
		d.Keys = *r.Body.Keys
	}
	sg, err := s.Listings.Decide(ctx, p, r.OrgId, r.SuggestionId, d)
	if err != nil {
		return nil, err
	}
	return gen.DecideSuggestion200JSONResponse(suggestionDTO(sg)), nil
}

func (s *Server) reviewItem(v db.ListPendingVersionsRow) gen.ReviewItem {
	var snap listing.Snapshot
	_ = json.Unmarshal(v.Snapshot, &snap)
	item := gen.ReviewItem{VersionId: v.ID, ListingId: v.ListingID, OrgId: v.OrgID, OrgName: v.OrgName, Version: v.Version,
		SubmittedAt: v.SubmittedAt, SubmittedByEmail: v.SubmittedByEmail, Title: gen.I18nText{Cs: snap.Title.CS, En: snap.Title.EN},
		FirstPublication: v.PublishedVersion == nil}
	if len(snap.Photos) > 0 {
		u := s.Listings.PhotoURLs(snap.Photos[0].Key, snap.Photos[0].Orientation)["thumb"]
		item.CoverUrl = &u
	}
	return item
}

// BackofficeListReviews implements GET /v1/backoffice/reviews.
func (s *Server) BackofficeListReviews(ctx context.Context, _ gen.BackofficeListReviewsRequestObject) (gen.BackofficeListReviewsResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	rows, err := s.Listings.ReviewQueue(ctx)
	if err != nil {
		return nil, err
	}
	out := gen.BackofficeListReviews200JSONResponse{}
	for _, v := range rows {
		out = append(out, s.reviewItem(v))
	}
	return out, nil
}

// BackofficeGetReview implements GET /v1/backoffice/reviews/{versionId}.
func (s *Server) BackofficeGetReview(ctx context.Context, r gen.BackofficeGetReviewRequestObject) (gen.BackofficeGetReviewResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	v, err := s.Listings.Version(ctx, r.VersionId)
	if err != nil {
		return nil, err
	}
	q := db.New(s.pool)
	o, err := q.GetOrganization(ctx, v.OrgID)
	if err != nil {
		return nil, err
	}
	l, err := q.GetListing(ctx, db.GetListingParams{ID: v.ListingID, OrgID: v.OrgID})
	if err != nil {
		return nil, err
	}
	email := ""
	if v.SubmittedBy != nil {
		if u, err := q.GetUser(ctx, *v.SubmittedBy); err == nil {
			email = u.Email
		}
	}
	item := s.reviewItem(db.ListPendingVersionsRow{ID: v.ID, ListingID: v.ListingID, OrgID: v.OrgID, Version: v.Version,
		SubmittedAt: v.SubmittedAt, Snapshot: v.Snapshot, OrgName: o.Name, SubmittedByEmail: email, PublishedVersion: l.PublishedVersion})
	var snap listing.Snapshot
	_ = json.Unmarshal(v.Snapshot, &snap)
	photos := []gen.PhotoUrls{}
	for _, ph := range snap.Photos {
		photos = append(photos, s.Listings.PhotoURLs(ph.Key, ph.Orientation))
	}
	return gen.BackofficeGetReview200JSONResponse{Item: item, Snapshot: objectOf(v.Snapshot), Photos: photos}, nil
}

// BackofficeDecideReview implements POST /v1/backoffice/reviews/{versionId}/decision.
func (s *Server) BackofficeDecideReview(ctx context.Context, r gen.BackofficeDecideReviewRequestObject) (gen.BackofficeDecideReviewResponseObject, error) {
	p, err := s.staff(ctx)
	if err != nil {
		return nil, err
	}
	note := ""
	if r.Body.Note != nil {
		note = *r.Body.Note
	}
	if !r.Body.Approve && len(note) < 5 {
		return nil, apperr.Unprocessable("note_required", "explain to the owner what to change")
	}
	if err := s.Listings.Review(ctx, p, r.VersionId, r.Body.Approve, note); err != nil {
		return nil, err
	}
	return gen.BackofficeDecideReview204Response{}, nil
}

// BackofficeListFilterProposals implements GET /v1/backoffice/filter-proposals.
func (s *Server) BackofficeListFilterProposals(ctx context.Context, r gen.BackofficeListFilterProposalsRequestObject) (gen.BackofficeListFilterProposalsResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	status := "pending"
	if r.Params.Status != nil {
		status = string(*r.Params.Status)
	}
	rows, err := s.Listings.Proposals(ctx, status)
	if err != nil {
		return nil, err
	}
	out := gen.BackofficeListFilterProposals200JSONResponse{}
	for _, p := range rows {
		out = append(out, gen.FilterProposal{Id: p.ID, AttributeKey: p.AttributeKey, Value: p.Value, Label: i18nDTO(p.Label),
			Occurrences: int(p.Occurrences), Status: gen.FilterProposalStatus(p.Status), ExampleListingId: p.ExampleListingID, CreatedAt: p.CreatedAt})
	}
	return out, nil
}

// BackofficeDecideFilterProposal implements POST /v1/backoffice/filter-proposals/{proposalId}/decision.
func (s *Server) BackofficeDecideFilterProposal(ctx context.Context, r gen.BackofficeDecideFilterProposalRequestObject) (gen.BackofficeDecideFilterProposalResponseObject, error) {
	p, err := s.staff(ctx)
	if err != nil {
		return nil, err
	}
	var label *listing.I18n
	if r.Body.Label != nil {
		label = &listing.I18n{CS: r.Body.Label.Cs, EN: r.Body.Label.En}
	}
	note := ""
	if r.Body.Note != nil {
		note = *r.Body.Note
	}
	if err := s.Listings.DecideProposal(ctx, p, r.ProposalId, r.Body.Approve, label, note); err != nil {
		return nil, err
	}
	return gen.BackofficeDecideFilterProposal204Response{}, nil
}

var _ = time.Now
