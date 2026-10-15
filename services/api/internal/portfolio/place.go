package portfolio

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

// Place is where a lease is.
type Place struct {
	UnitID    *uuid.UUID
	AdminPath string // deepest administrative unit, empty when unknown
	Lat, Lng  *float64
}

// Locate finds a lease's place from its listing, a RÚIAN address or the
// municipality named in the free-text address, in this order.
func Locate(ctx context.Context, q *db.Queries, listingID *uuid.UUID, ruianID *int64, address string) (Place, error) {
	if listingID != nil {
		r, err := q.LeaseLocationFromListing(ctx, *listingID)
		if err == nil {
			return Place{UnitID: &r.UnitID, AdminPath: r.AdminPath, Lat: &r.Lat, Lng: &r.Lng}, nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return Place{}, err
		}
	}
	if ruianID != nil {
		r, err := q.LeaseLocationFromRuian(ctx, *ruianID)
		if err == nil {
			return Place{AdminPath: r.AdminPath, Lat: &r.Lat, Lng: &r.Lng}, nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return Place{}, err
		}
	}
	if address != "" {
		r, err := q.MunicipalityInText(ctx, address)
		if err == nil {
			return Place{AdminPath: r.AdminPath, Lat: &r.Lat, Lng: &r.Lng}, nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return Place{}, err
		}
	}
	return Place{}, nil
}

// Resolved are the effective rules of a lease with where they came from.
type Resolved struct {
	Rules   Rules    `json:"rules"`
	Sources []string `json:"sources"` // jurisdiction, municipality, group
}

// Resolve merges the jurisdiction defaults with the municipality rules of
// the place and the rules of the lease's groups (group rules win).
func Resolve(ctx context.Context, q *db.Queries, orgID uuid.UUID, place Place, leaseID uuid.UUID) (Resolved, error) {
	groups, err := q.LeaseGroupIDs(ctx, db.LeaseGroupIDsParams{UnitID: place.UnitID, LeaseID: &leaseID})
	if err != nil {
		return Resolved{}, err
	}
	rows, err := q.RulesForLease(ctx, db.RulesForLeaseParams{OrgID: orgID, AdminPath: place.AdminPath, GroupIds: groups})
	if err != nil {
		return Resolved{}, err
	}
	out := Resolved{Rules: Defaults(), Sources: []string{"jurisdiction"}}
	for _, r := range rows {
		over, err := ParseRules(r.Rules)
		if err != nil {
			return Resolved{}, err
		}
		out.Rules = out.Rules.Merge(over)
		out.Sources = append(out.Sources, r.Scope)
	}
	return out, nil
}

// Apply stores the place on the lease and the resolved rules in its terms,
// which the lifecycle workflow reads (ADR 0010).
func Apply(ctx context.Context, q *db.Queries, l db.Lease, place Place, res Resolved) error {
	if err := q.SetLeaseLocation(ctx, db.SetLeaseLocationParams{ID: l.ID, UnitID: place.UnitID, AdminPath: place.AdminPath,
		Lat: place.Lat, Lng: place.Lng}); err != nil {
		return err
	}
	terms := map[string]any{}
	if len(l.Terms) > 0 {
		_ = json.Unmarshal(l.Terms, &terms)
	}
	terms["rules"] = res.Rules
	terms["rules_sources"] = res.Sources
	b, err := json.Marshal(terms)
	if err != nil {
		return err
	}
	return q.SetLeaseTerms(ctx, db.SetLeaseTermsParams{ID: l.ID, Terms: b})
}

// LeaseRules reads the rules stored in lease terms (defaults when absent).
func LeaseRules(terms []byte) Rules {
	var t struct {
		Rules Rules `json:"rules"`
	}
	_ = json.Unmarshal(terms, &t)
	return Defaults().Merge(t.Rules)
}
