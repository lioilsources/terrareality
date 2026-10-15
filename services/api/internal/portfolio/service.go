package portfolio

import (
	"context"
	"encoding/json"
	"errors"
	"math"
	"regexp"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

// Service implements the portfolio API. Reads and writes run as the user
// (row-level security); the role decides what is visible (ADR 0010).
type Service struct {
	Pool   *pgxpool.Pool
	Scorer *Scorer
	AI     ai.PortfolioSummarizer
	Now    func() time.Time // tests
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func pgDate(t time.Time) pgtype.Date { return pgtype.Date{Time: t, Valid: true} }

func dateOf(d pgtype.Date) *time.Time {
	if !d.Valid {
		return nil
	}
	t := d.Time
	return &t
}

func (s *Service) asUser(ctx context.Context, p *auth.Principal, fn func(q *db.Queries) error) error {
	return platformdb.AsUser(ctx, s.Pool, p.UserID, func(tx pgx.Tx) error { return fn(db.New(tx)) })
}

func invalid(code, msg string) error { return apperr.Unprocessable(code, msg) }

// ---------------------------------------------------------------------------
// Rent roll.

// Row is one line of the rent roll: a running lease or a vacant unit.
type Row struct {
	Kind             string // lease | vacant
	LeaseID          *uuid.UUID
	UnitID           *uuid.UUID
	Code             int64
	State            string
	Municipality     string
	MunicipalityPath string
	Region           string
	RegionPath       string
	Address          string
	Unit             string
	Tenants          string
	Rent             int64
	Services         int64
	Currency         string
	DueDay           int
	StartsOn         *time.Time
	EndsOn           *time.Time
	NoticeOn         *time.Time
	Deposit          int64
	DepositPaid      int64
	Billed           int64 // receivables due by today (ledger)
	Paid             int64 // payments booked by today (ledger)
	Debt             int64 // receivable balance by today = billed - paid
	RiskScore        *int
	RiskBand         string
	Groups           []uuid.UUID
	Lat, Lng         *float64
	AskingRent       int64
	ListingStatus    string
	LastEscalation   *time.Time
}

// Monthly is rent plus services.
func (r Row) Monthly() int64 { return r.Rent + r.Services }

// Filter narrows the rent roll.
type Filter struct {
	Municipality string // admin path of a municipality
	Region       string // admin path of a region
	GroupID      *uuid.UUID
}

func (f Filter) match(r Row) bool {
	if f.Municipality != "" && r.MunicipalityPath != f.Municipality {
		return false
	}
	if f.Region != "" && r.RegionPath != f.Region {
		return false
	}
	if f.GroupID != nil {
		for _, g := range r.Groups {
			if g == *f.GroupID {
				return true
			}
		}
		return false
	}
	return true
}

var initialsRe = regexp.MustCompile(`[\p{L}]+`)

// initials masks a name for investors ("Anna Nováková" -> "A. N.").
func initials(names string) string {
	var out []string
	for _, n := range strings.Split(names, ",") {
		var parts []string
		for _, w := range initialsRe.FindAllString(n, -1) {
			parts = append(parts, string([]rune(w)[:1])+".")
		}
		if len(parts) > 0 {
			out = append(out, strings.Join(parts, " "))
		}
	}
	return strings.Join(out, ", ")
}

// rows loads the rent roll (q runs as the user).
func (s *Service) rows(ctx context.Context, q *db.Queries, orgID uuid.UUID, role string) ([]Row, error) {
	day := today(s.now())
	leases, err := q.RentRollLeases(ctx, db.RentRollLeasesParams{OrgID: orgID, AsOf: pgDate(day)})
	if err != nil {
		return nil, err
	}
	out := make([]Row, 0, len(leases))
	for _, l := range leases {
		id := l.ID
		r := Row{Kind: "lease", LeaseID: &id, UnitID: l.UnitID, Code: l.Code, State: l.State, Municipality: l.Municipality,
			MunicipalityPath: l.MunicipalityPath, Region: l.Region, RegionPath: l.RegionPath, Address: l.PropertyAddress,
			Unit: l.UnitLabel, Tenants: l.TenantNames, Rent: l.RentAmount, Services: l.ServicesAmount, Currency: l.Currency,
			DueDay: int(l.DueDay), StartsOn: dateOf(l.StartsOn), EndsOn: dateOf(l.EndsOn), NoticeOn: dateOf(l.NoticeOn),
			Deposit: l.DepositAmount, DepositPaid: l.DepositPaid, Billed: l.Billed, Paid: l.Paid, Debt: l.Billed - l.Paid,
			RiskBand: l.RiskBand, Groups: l.GroupIds, Lat: l.Lat, Lng: l.Lng}
		if l.RiskScore >= 0 {
			v := int(l.RiskScore)
			r.RiskScore = &v
		}
		if l.LastEscalation.Year() > 1970 {
			t := l.LastEscalation
			r.LastEscalation = &t
		}
		if role == org.Investor {
			r.Tenants = initials(r.Tenants)
		}
		out = append(out, r)
	}
	vacant, err := q.RentRollVacantUnits(ctx, orgID)
	if err != nil {
		return nil, err
	}
	for _, u := range vacant {
		id := u.ID
		lat, lng := u.Lat, u.Lng
		out = append(out, Row{Kind: "vacant", UnitID: &id, State: "vacant", Municipality: u.Municipality,
			MunicipalityPath: u.MunicipalityPath, Region: u.Region, RegionPath: u.RegionPath, Address: u.Address,
			Unit: u.Label, Currency: "CZK", Groups: u.GroupIds, Lat: &lat, Lng: &lng, AskingRent: u.AskingRent,
			ListingStatus: u.ListingStatus})
	}
	return out, nil
}

// RentRoll returns the filtered rent roll and the caller's role.
func (s *Service) RentRoll(ctx context.Context, p *auth.Principal, orgID uuid.UUID, f Filter) ([]Row, string, error) {
	var out []Row
	var role string
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		m, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolioRead)
		if err != nil {
			return err
		}
		role = m.Role
		all, err := s.rows(ctx, q, orgID, m.Role)
		for _, r := range all {
			if f.match(r) {
				out = append(out, r)
			}
		}
		return err
	})
	return out, role, err
}

// ---------------------------------------------------------------------------
// Dashboard.

// City is one municipality of the portfolio.
type City struct {
	Path, Name, Region string
	Leases, Vacant     int
	Monthly            int64 // rent + services of running leases
	Expected, Received int64 // this month
	Debt               int64
	WeightedRisk       *int
	Band               string
	Share              float64 // of the portfolio's monthly income
	Lat, Lng           *float64
}

// Share is a part of the monthly income.
type Share struct {
	Name   string
	Share  float64
	Amount int64
	Count  int
}

// Concentration of the monthly income.
type Concentration struct {
	TopCity    *Share
	TopTenant  *Share
	EndingPeak *Share  // the month (Name = YYYY-MM) with most fixed terms ending in the next 12 months
	HHI        float64 // Herfindahl index over municipalities, 0..1
}

// Item needs the owner's attention.
type Item struct {
	Kind     string // escalation | debt | ending | notice | vacant | high_risk
	Severity int    // 3 high, 2 medium, 1 low
	LeaseID  *uuid.UUID
	UnitID   *uuid.UUID
	Label    string
	City     string
	Amount   int64
	Date     *time.Time
	Score    *int
}

// Point is one month of the trend.
type Point struct {
	Period             string
	Expected, Received int64
	WeightedRisk       *int
}

// Dashboard is the portfolio overview.
type Dashboard struct {
	Role          string
	Currency      string
	Leases        int
	Vacant        int
	Monthly       int64
	Debt          int64
	WeightedRisk  *int
	Band          string
	Period        string
	Expected      int64
	Received      int64
	Cities        []City
	Concentration Concentration
	Attention     []Item
	Trend         []Point
}

// weighted returns the rent-weighted mean score.
func weighted(sum, weight float64) *int {
	if weight <= 0 {
		return nil
	}
	v := int(math.Round(sum / weight))
	return &v
}

// Dashboard builds the overview (filters as in the rent roll).
func (s *Service) Dashboard(ctx context.Context, p *auth.Principal, orgID uuid.UUID, f Filter) (Dashboard, error) {
	var d Dashboard
	var rows []Row
	var monthly []db.PortfolioMonthlyRow
	var trend []db.PortfolioRiskTrendRow
	now := s.now()
	day := today(now)
	first := time.Date(day.Year(), day.Month(), 1, 0, 0, 0, 0, time.UTC)
	from := first.AddDate(0, -11, 0)
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		m, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolioRead)
		if err != nil {
			return err
		}
		d.Role, d.Currency = m.Role, "CZK"
		if j, err := q.GetJurisdiction(ctx, m.Org.JurisdictionCode); err == nil {
			d.Currency = j.Currency
		}
		all, err := s.rows(ctx, q, orgID, m.Role)
		if err != nil {
			return err
		}
		for _, r := range all {
			if f.match(r) {
				rows = append(rows, r)
			}
		}
		if monthly, err = q.PortfolioMonthly(ctx, db.PortfolioMonthlyParams{OrgID: orgID, FromDay: pgDate(from),
			ToDay: pgDate(first.AddDate(0, 1, -1))}); err != nil {
			return err
		}
		trend, err = q.PortfolioRiskTrend(ctx, db.PortfolioRiskTrendParams{OrgID: orgID, Period: from.Format("2006-01")})
		return err
	})
	if err != nil {
		return d, err
	}
	d.Period = first.Format("2006-01")
	inScope := map[string]bool{} // municipalities of the filtered rows (for the monthly figures)
	cities := map[string]*City{}
	cityKey := func(r Row) string {
		if r.MunicipalityPath == "" {
			return "?"
		}
		return r.MunicipalityPath
	}
	var riskSum, riskWeight float64
	cityRisk := map[string][2]float64{}
	cityLat := map[string][3]float64{}
	tenants := map[string]*Share{}
	endings := map[string]*Share{}
	for _, r := range rows {
		k := cityKey(r)
		inScope[r.MunicipalityPath] = true
		c := cities[k]
		if c == nil {
			c = &City{Path: r.MunicipalityPath, Name: r.Municipality, Region: r.Region}
			cities[k] = c
		}
		if r.Lat != nil && r.Lng != nil {
			v := cityLat[k]
			cityLat[k] = [3]float64{v[0] + *r.Lat, v[1] + *r.Lng, v[2] + 1}
		}
		if r.Kind == "vacant" {
			c.Vacant++
			d.Vacant++
			d.Attention = append(d.Attention, Item{Kind: "vacant", Severity: 1, UnitID: r.UnitID, Label: joinLabel(r.Address, r.Unit),
				City: r.Municipality, Amount: r.AskingRent})
			continue
		}
		c.Leases++
		d.Leases++
		c.Monthly += r.Monthly()
		d.Monthly += r.Monthly()
		c.Debt += max(r.Debt, 0)
		d.Debt += max(r.Debt, 0)
		if r.RiskScore != nil {
			w := float64(r.Monthly())
			riskSum += float64(*r.RiskScore) * w
			riskWeight += w
			v := cityRisk[k]
			cityRisk[k] = [2]float64{v[0] + float64(*r.RiskScore)*w, v[1] + w}
		}
		if r.Tenants != "" {
			t := tenants[r.Tenants]
			if t == nil {
				t = &Share{Name: r.Tenants}
				tenants[r.Tenants] = t
			}
			t.Amount += r.Monthly()
			t.Count++
		}
		label := joinLabel(r.Address, r.Unit)
		if r.EndsOn != nil && r.EndsOn.After(day) && r.EndsOn.Before(day.AddDate(1, 0, 0)) {
			key := r.EndsOn.Format("2006-01")
			e := endings[key]
			if e == nil {
				e = &Share{Name: key}
				endings[key] = e
			}
			e.Amount += r.Monthly()
			e.Count++
		}
		// Attention.
		if r.LastEscalation != nil && r.LastEscalation.After(now.AddDate(0, 0, -30)) {
			d.Attention = append(d.Attention, Item{Kind: "escalation", Severity: 3, LeaseID: r.LeaseID, Label: label,
				City: r.Municipality, Amount: r.Debt, Date: r.LastEscalation, Score: r.RiskScore})
		}
		if r.Debt > 0 {
			sev := 2
			if r.Debt >= r.Monthly() {
				sev = 3
			}
			d.Attention = append(d.Attention, Item{Kind: "debt", Severity: sev, LeaseID: r.LeaseID, Label: label,
				City: r.Municipality, Amount: r.Debt, Score: r.RiskScore})
		}
		if r.State == "notice_given" {
			d.Attention = append(d.Attention, Item{Kind: "notice", Severity: 2, LeaseID: r.LeaseID, Label: label,
				City: r.Municipality, Date: r.EndsOn, Score: r.RiskScore})
		} else if r.EndsOn != nil && r.EndsOn.Before(day.AddDate(0, 0, 91)) {
			d.Attention = append(d.Attention, Item{Kind: "ending", Severity: 2, LeaseID: r.LeaseID, Label: label,
				City: r.Municipality, Date: r.EndsOn, Score: r.RiskScore})
		}
		if r.RiskBand == "high" {
			d.Attention = append(d.Attention, Item{Kind: "high_risk", Severity: 3, LeaseID: r.LeaseID, Label: label,
				City: r.Municipality, Score: r.RiskScore})
		}
	}
	d.WeightedRisk = weighted(riskSum, riskWeight)
	if d.WeightedRisk != nil {
		d.Band = Band(*d.WeightedRisk)
	}
	// Monthly figures (expected vs received) per city and the trend.
	filtered := f.Municipality != "" || f.Region != "" || f.GroupID != nil
	byPeriod := map[string]*Point{}
	for i := 0; i < 12; i++ {
		per := from.AddDate(0, i, 0).Format("2006-01")
		byPeriod[per] = &Point{Period: per}
	}
	for _, mrow := range monthly {
		if filtered && !inScope[mrow.MunicipalityPath] {
			continue
		}
		if pt := byPeriod[mrow.Period]; pt != nil {
			pt.Expected += mrow.Expected
			pt.Received += mrow.Received
		}
		if mrow.Period == d.Period {
			d.Expected += mrow.Expected
			d.Received += mrow.Received
			k := mrow.MunicipalityPath
			if k == "" {
				k = "?"
			}
			if c := cities[k]; c != nil {
				c.Expected += mrow.Expected
				c.Received += mrow.Received
			}
		}
	}
	if !filtered {
		for _, t := range trend {
			if pt := byPeriod[t.Period]; pt != nil {
				v := int(t.Weighted)
				pt.WeightedRisk = &v
			}
		}
	}
	for i := 0; i < 12; i++ {
		d.Trend = append(d.Trend, *byPeriod[from.AddDate(0, i, 0).Format("2006-01")])
	}
	// Cities, concentration.
	var hhi float64
	for k, c := range cities {
		if v, ok := cityRisk[k]; ok {
			c.WeightedRisk = weighted(v[0], v[1])
			c.Band = Band(*c.WeightedRisk)
		}
		if v, ok := cityLat[k]; ok && v[2] > 0 {
			lat, lng := v[0]/v[2], v[1]/v[2]
			c.Lat, c.Lng = &lat, &lng
		}
		if d.Monthly > 0 {
			c.Share = float64(c.Monthly) / float64(d.Monthly)
			hhi += c.Share * c.Share
		}
		d.Cities = append(d.Cities, *c)
	}
	sort.Slice(d.Cities, func(i, j int) bool {
		if d.Cities[i].Monthly != d.Cities[j].Monthly {
			return d.Cities[i].Monthly > d.Cities[j].Monthly
		}
		return d.Cities[i].Name < d.Cities[j].Name
	})
	d.Concentration.HHI = math.Round(hhi*1000) / 1000
	if len(d.Cities) > 0 && d.Monthly > 0 {
		c := d.Cities[0]
		d.Concentration.TopCity = &Share{Name: c.Name, Share: c.Share, Amount: c.Monthly, Count: c.Leases}
	}
	top := func(m map[string]*Share) *Share {
		var best *Share
		for _, v := range m {
			if best == nil || v.Amount > best.Amount || (v.Amount == best.Amount && v.Name < best.Name) {
				best = v
			}
		}
		if best != nil && d.Monthly > 0 {
			best.Share = float64(best.Amount) / float64(d.Monthly)
		}
		return best
	}
	d.Concentration.TopTenant = top(tenants)
	d.Concentration.EndingPeak = top(endings)
	sort.SliceStable(d.Attention, func(i, j int) bool { return d.Attention[i].Severity > d.Attention[j].Severity })
	return d, nil
}

func joinLabel(address, unit string) string {
	if unit == "" {
		return address
	}
	return address + ", " + unit
}

// ---------------------------------------------------------------------------
// Lease risk.

// LeaseRisk is the score of one lease as the caller may see it.
type LeaseRisk struct {
	Score        *int // nil for tenants
	Band         string
	Factors      []Factor
	ModelVersion string
	ComputedAt   time.Time
	Landlord     bool
}

// LeaseRisk returns the risk of a lease: everything for members who may
// read the portfolio, the payment factors without weights or score for the
// tenant side (ADR 0010).
func (s *Service) LeaseRisk(ctx context.Context, p *auth.Principal, leaseID uuid.UUID) (LeaseRisk, error) {
	var out LeaseRisk
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		l, err := q.GetLease(ctx, leaseID)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("lease_not_found", "lease not found")
		}
		if err != nil {
			return err
		}
		if _, err := org.Access(ctx, q, p.UserID, l.OrgID, org.PermPortfolioRead); err == nil {
			out.Landlord = true
		}
		r, err := q.GetLeaseRisk(ctx, leaseID)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("risk_not_computed", "the risk of this lease has not been computed yet")
		}
		if err != nil {
			return err
		}
		var factors []Factor
		if err := json.Unmarshal(r.Factors, &factors); err != nil {
			return err
		}
		out.ModelVersion, out.ComputedAt = r.ModelVersion, r.ComputedAt
		if out.Landlord {
			score := int(r.Score)
			out.Score, out.Band, out.Factors = &score, r.Band, factors
			return nil
		}
		for _, f := range factors {
			if f.TenantVisible {
				f.Weight, f.Points = 0, 0
				out.Factors = append(out.Factors, f)
			}
		}
		return nil
	})
	return out, err
}

// ---------------------------------------------------------------------------
// Groups.

// Group is a portfolio group with its members.
type Group struct {
	db.PortfolioGroup
	Properties []uuid.UUID
	Leases     []uuid.UUID
}

var colorRe = regexp.MustCompile(`^#[0-9a-f]{6}$`)

// Groups lists the groups and the properties that can be added.
func (s *Service) Groups(ctx context.Context, p *auth.Principal, orgID uuid.UUID) ([]Group, []db.ListOrgPropertiesRow, error) {
	var out []Group
	var props []db.ListOrgPropertiesRow
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolioRead); err != nil {
			return err
		}
		groups, err := q.ListPortfolioGroups(ctx, orgID)
		if err != nil {
			return err
		}
		items, err := q.GroupItems(ctx, orgID)
		if err != nil {
			return err
		}
		for _, g := range groups {
			gr := Group{PortfolioGroup: db.PortfolioGroup{ID: g.ID, OrgID: g.OrgID, Name: g.Name, Color: g.Color, CreatedAt: g.CreatedAt},
				Properties: []uuid.UUID{}, Leases: []uuid.UUID{}}
			for _, it := range items {
				if it.GroupID != g.ID {
					continue
				}
				if it.PropertyID != nil {
					gr.Properties = append(gr.Properties, *it.PropertyID)
				}
				if it.LeaseID != nil {
					gr.Leases = append(gr.Leases, *it.LeaseID)
				}
			}
			out = append(out, gr)
		}
		props, err = q.ListOrgProperties(ctx, orgID)
		return err
	})
	return out, props, err
}

// GroupInput creates or replaces a group.
type GroupInput struct {
	Name       string
	Color      string
	Properties []uuid.UUID
	Leases     []uuid.UUID
}

// SaveGroup creates (id nil) or updates a group and replaces its members.
func (s *Service) SaveGroup(ctx context.Context, p *auth.Principal, orgID uuid.UUID, id *uuid.UUID, in GroupInput) (uuid.UUID, error) {
	in.Name = strings.TrimSpace(in.Name)
	if in.Name == "" || len([]rune(in.Name)) > 80 {
		return uuid.Nil, invalid("invalid_name", "the group name has 1 to 80 characters")
	}
	if in.Color == "" {
		in.Color = "#64748b"
	}
	if !colorRe.MatchString(in.Color) {
		return uuid.Nil, invalid("invalid_color", "the color is #rrggbb")
	}
	var gid uuid.UUID
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolio); err != nil {
			return err
		}
		if id == nil {
			g, err := q.CreatePortfolioGroup(ctx, db.CreatePortfolioGroupParams{OrgID: orgID, Name: in.Name, Color: in.Color})
			if err != nil {
				if strings.Contains(err.Error(), "portfolio_groups_org_id_name_key") {
					return apperr.Conflict("group_exists", "a group with this name exists")
				}
				return err
			}
			gid = g.ID
		} else {
			g, err := q.UpdatePortfolioGroup(ctx, db.UpdatePortfolioGroupParams{ID: *id, OrgID: orgID, Name: in.Name, Color: in.Color})
			if errors.Is(err, pgx.ErrNoRows) {
				return apperr.NotFound("group_not_found", "group not found")
			}
			if err != nil {
				return err
			}
			gid = g.ID
		}
		if err := q.ClearGroupItems(ctx, gid); err != nil {
			return err
		}
		for _, pid := range in.Properties {
			if err := q.AddGroupProperty(ctx, db.AddGroupPropertyParams{GroupID: gid, PropertyID: pid}); err != nil {
				return err
			}
		}
		for _, lid := range in.Leases {
			if err := q.AddGroupLease(ctx, db.AddGroupLeaseParams{GroupID: gid, LeaseID: lid}); err != nil {
				return err
			}
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "portfolio_group", EntityID: &gid, Action: "portfolio.group_saved",
			Diff: map[string]any{"name": in.Name, "properties": len(in.Properties), "leases": len(in.Leases)}})
	})
	return gid, err
}

// DeleteGroup removes a group (its rules go with it).
func (s *Service) DeleteGroup(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolio); err != nil {
			return err
		}
		n, err := q.DeletePortfolioGroup(ctx, db.DeletePortfolioGroupParams{ID: id, OrgID: orgID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.NotFound("group_not_found", "group not found")
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "portfolio_group", EntityID: &id, Action: "portfolio.group_deleted"})
	})
}

// ---------------------------------------------------------------------------
// Rules.

// Rules lists the rules and the municipalities they can be set for.
func (s *Service) Rules(ctx context.Context, p *auth.Principal, orgID uuid.UUID) ([]db.ListPortfolioRulesRow, []db.ListMunicipalitiesRow, error) {
	var rules []db.ListPortfolioRulesRow
	var munis []db.ListMunicipalitiesRow
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolioRead); err != nil {
			return err
		}
		var err error
		if rules, err = q.ListPortfolioRules(ctx, orgID); err != nil {
			return err
		}
		munis, err = q.ListMunicipalities(ctx)
		return err
	})
	return rules, munis, err
}

// SaveRule sets the rules of a municipality (admin path) or a group. They
// apply to leases created afterwards (existing leases keep their terms).
func (s *Service) SaveRule(ctx context.Context, p *auth.Principal, orgID uuid.UUID, municipality string, groupID *uuid.UUID, r Rules) (uuid.UUID, error) {
	if (municipality == "") == (groupID == nil) {
		return uuid.Nil, invalid("invalid_scope", "choose a municipality or a group")
	}
	var id uuid.UUID
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		m, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolio)
		if err != nil {
			return err
		}
		j, err := q.GetJurisdiction(ctx, m.Org.JurisdictionCode)
		if err != nil {
			return err
		}
		if err := r.Validate(int(j.DepositMaxMonths)); err != nil {
			return invalid("invalid_rules", err.Error())
		}
		b, _ := json.Marshal(r)
		if municipality != "" {
			id, err = q.UpsertMunicipalityRule(ctx, db.UpsertMunicipalityRuleParams{OrgID: orgID, AdminPath: municipality, Rules: b})
		} else {
			id, err = q.UpsertGroupRule(ctx, db.UpsertGroupRuleParams{OrgID: orgID, GroupID: *groupID, Rules: b})
			if errors.Is(err, pgx.ErrNoRows) {
				return apperr.NotFound("group_not_found", "group not found")
			}
		}
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "portfolio_rule", EntityID: &id, Action: "portfolio.rule_saved",
			Diff: map[string]any{"rules": r, "municipality": municipality}})
	})
	return id, err
}

// DeleteRule removes a rule.
func (s *Service) DeleteRule(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolio); err != nil {
			return err
		}
		n, err := q.DeletePortfolioRule(ctx, db.DeletePortfolioRuleParams{ID: id, OrgID: orgID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.NotFound("rule_not_found", "rule not found")
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "portfolio_rule", EntityID: &id, Action: "portfolio.rule_deleted"})
	})
}

// ResolveRules previews the rules a new lease would get (lease form).
func (s *Service) ResolveRules(ctx context.Context, p *auth.Principal, orgID uuid.UUID, listingID *uuid.UUID, ruianID *int64, address string) (Resolved, string, error) {
	var out Resolved
	var place string
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases); err != nil {
			return err
		}
		pl, err := Locate(ctx, q, listingID, ruianID, address)
		if err != nil {
			return err
		}
		if mp := municipalityPath(pl.AdminPath); mp != "" {
			if u, err := q.GetAdminUnit(ctx, mp); err == nil {
				place = u.Name
			}
		}
		out, err = Resolve(ctx, q, orgID, pl, uuid.Nil)
		return err
	})
	return out, place, err
}

// ---------------------------------------------------------------------------
// Risk weights.

// Weights returns the organization's weights merged with the defaults.
func (s *Service) Weights(ctx context.Context, p *auth.Principal, orgID uuid.UUID) (map[string]int, error) {
	out := DefaultWeights()
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolioRead); err != nil {
			return err
		}
		w, err := Weights(ctx, q, orgID)
		for k, v := range w {
			if _, ok := out[k]; ok {
				out[k] = v
			}
		}
		return err
	})
	return out, err
}

// SetWeights stores the weights and rescores the organization's leases.
func (s *Service) SetWeights(ctx context.Context, p *auth.Principal, orgID uuid.UUID, w map[string]int) error {
	total := 0
	clean := map[string]int{}
	for k, v := range w {
		if _, ok := DefaultWeights()[k]; !ok {
			return invalid("unknown_factor", "unknown factor "+k)
		}
		if v < 0 || v > 100 {
			return invalid("invalid_weight", "weights are 0 to 100")
		}
		clean[k] = v
		total += v
	}
	if len(clean) > 0 && total == 0 {
		return invalid("invalid_weight", "at least one factor needs a weight")
	}
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolio); err != nil {
			return err
		}
		b, _ := json.Marshal(clean)
		if err := q.UpsertRiskSettings(ctx, db.UpsertRiskSettingsParams{OrgID: orgID, Weights: b}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "risk_settings", EntityID: &orgID, Action: "portfolio.weights_changed",
			Diff: map[string]any{"weights": clean}})
	})
	if err != nil || s.Scorer == nil {
		return err
	}
	return s.Scorer.RecomputeOrg(ctx, orgID)
}
