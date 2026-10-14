package applications

import (
	"context"
	"encoding/json"
	"errors"
	"slices"
	"sort"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/textscan"
)

// Profile is a "looking for a flatmate" profile.
type Profile struct {
	Active    bool       `json:"active"`
	AdminPath string     `json:"admin_path"`
	AreaLabel string     `json:"area_label"`
	BudgetMax int64      `json:"budget_max"`
	MoveIn    *time.Time `json:"move_in"`
	About     string     `json:"about"`
	Lifestyle []string   `json:"lifestyle"`
	HasRoom   bool       `json:"has_room"`
}

// Match is another seeker's profile with a score.
type Match struct {
	db.ListRoommateProfilesRow
	Score int
}

func dateOf(d pgtype.Date) *time.Time {
	if !d.Valid {
		return nil
	}
	t := d.Time
	return &t
}

// RoommateProfile returns the caller's profile (nil when none).
func (s *Service) RoommateProfile(ctx context.Context, p *auth.Principal) (*Profile, error) {
	var out *Profile
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		r, err := q.GetRoommateProfile(ctx, p.UserID)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil
		}
		if err != nil {
			return err
		}
		out = profileOf(r)
		return nil
	})
	return out, err
}

func profileOf(r db.GetRoommateProfileRow) *Profile {
	return &Profile{Active: r.Active, AdminPath: r.AdminPath, AreaLabel: r.AreaLabel, BudgetMax: r.BudgetMax,
		MoveIn: dateOf(r.MoveIn), About: r.About, Lifestyle: r.Lifestyle, HasRoom: r.HasRoom}
}

// SaveRoommateProfile creates or updates the caller's profile.
func (s *Service) SaveRoommateProfile(ctx context.Context, p *auth.Principal, in Profile) (*Profile, error) {
	if in.BudgetMax <= 0 {
		return nil, apperr.Unprocessable("budget_required", "set a monthly budget")
	}
	if utf8.RuneCountInString(in.About) > 2000 {
		return nil, apperr.Unprocessable("about_too_long", "the description is limited to 2000 characters")
	}
	tags := []string{}
	for _, t := range in.Lifestyle {
		if slices.Contains(Lifestyle, t) && !slices.Contains(tags, t) {
			tags = append(tags, t)
		}
	}
	in.Lifestyle = tags
	in.About, _ = textscan.Scan(strings.TrimSpace(in.About)) // public text: no contacts
	var path *string
	label := strings.TrimSpace(in.AreaLabel)
	if in.AdminPath != "" {
		u, err := db.New(s.Pool).GetAdminUnit(ctx, in.AdminPath)
		if err != nil {
			return nil, apperr.Unprocessable("unknown_area", "unknown area")
		}
		path = &u.Path
		if label == "" {
			label = u.Name
		}
	}
	in.AreaLabel = label
	var move pgtype.Date
	if in.MoveIn != nil {
		move = pgtype.Date{Time: *in.MoveIn, Valid: true}
	}
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		_, err := q.UpsertRoommateProfile(ctx, db.UpsertRoommateProfileParams{UserID: p.UserID, Active: in.Active,
			AdminPath: path, AreaLabel: label, BudgetMax: in.BudgetMax, MoveIn: move, About: in.About,
			Lifestyle: in.Lifestyle, HasRoom: in.HasRoom})
		return err
	})
	return &in, err
}

func matchOf(r db.ListRoommateProfilesRow) MatchProfile {
	return MatchProfile{AdminPath: r.AdminPath, BudgetMax: r.BudgetMax, MoveIn: dateOf(r.MoveIn), Lifestyle: r.Lifestyle}
}

func rank(rows []db.ListRoommateProfilesRow, score func(MatchProfile) int) []Match {
	out := make([]Match, 0, len(rows))
	for _, r := range rows {
		if sc := score(matchOf(r)); sc > 0 {
			out = append(out, Match{ListRoommateProfilesRow: r, Score: sc})
		}
	}
	sort.SliceStable(out, func(i, j int) bool { return out[i].Score > out[j].Score })
	if len(out) > 50 {
		out = out[:50]
	}
	return out
}

// Roommates lists other seekers ranked against the caller's profile (or
// only filtered by area when the caller has none).
func (s *Service) Roommates(ctx context.Context, p *auth.Principal, area string) ([]Match, error) {
	mine, err := s.RoommateProfile(ctx, p)
	if err != nil {
		return nil, err
	}
	var areaPtr *string
	if area != "" {
		areaPtr = &area
	} else if mine != nil && mine.AdminPath != "" {
		areaPtr = &mine.AdminPath
	}
	var rows []db.ListRoommateProfilesRow
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		rows, err = q.ListRoommateProfiles(ctx, db.ListRoommateProfilesParams{Exclude: p.UserID, Area: areaPtr})
		return err
	})
	if err != nil {
		return nil, err
	}
	me := MatchProfile{AdminPath: area}
	if mine != nil {
		me = MatchProfile{AdminPath: mine.AdminPath, BudgetMax: mine.BudgetMax, MoveIn: mine.MoveIn, Lifestyle: mine.Lifestyle}
		if area != "" {
			me.AdminPath = area
		}
	}
	return rank(rows, func(other MatchProfile) int { return max(ScoreProfiles(me, other), 1) }), nil
}

// ListingRoommates suggests seekers for a published room listing (owner side).
func (s *Service) ListingRoommates(ctx context.Context, p *auth.Principal, orgID, listingID uuid.UUID) ([]Match, error) {
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		_, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogRead)
		return err
	})
	if err != nil {
		return nil, err
	}
	f, err := db.New(s.Pool).ListingMatchFacts(ctx, listingID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperr.Unprocessable("listing_not_published", "matches are available for published listings")
	}
	if err != nil {
		return nil, err
	}
	var attrs map[string]any
	_ = json.Unmarshal(f.Attributes, &attrs)
	facts := ListingFacts{AdminPath: f.AdminPath, Rent: f.RentAmount, Attributes: attrs}
	var area *string
	if f.AdminPath != "" {
		// Search the municipality (first three labels), not just the street block.
		parts := strings.Split(f.AdminPath, ".")
		a := strings.Join(parts[:min(3, len(parts))], ".")
		area = &a
	}
	var rows []db.ListRoommateProfilesRow
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		rows, err = q.ListRoommateProfiles(ctx, db.ListRoommateProfilesParams{Exclude: p.UserID, Area: area})
		return err
	})
	if err != nil {
		return nil, err
	}
	return rank(rows, func(m MatchProfile) int { return ScoreListing(m, facts) }), nil
}
