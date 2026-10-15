package api

import (
	"bytes"
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/portfolio"
)

func f32(v *float64) *float32 {
	if v == nil {
		return nil
	}
	x := float32(*v)
	return &x
}

func i64(v int64) *int64 { return &v }

func band(b string) *gen.RiskBand {
	if b == "" {
		return nil
	}
	x := gen.RiskBand(b)
	return &x
}

func dayDTO(t *time.Time) *openapi_types.Date {
	if t == nil {
		return nil
	}
	return &openapi_types.Date{Time: *t}
}

func filterOf(m *gen.PortfolioMunicipality, r *gen.PortfolioRegion, g *gen.PortfolioGroupFilter) portfolio.Filter {
	var f portfolio.Filter
	if m != nil {
		f.Municipality = *m
	}
	if r != nil {
		f.Region = *r
	}
	if g != nil {
		id := uuid.UUID(*g)
		f.GroupID = &id
	}
	return f
}

func shareDTO(s *portfolio.Share) *gen.PortfolioShare {
	if s == nil {
		return nil
	}
	return &gen.PortfolioShare{Name: s.Name, Share: float32(s.Share), Amount: s.Amount, Count: s.Count}
}

// GetPortfolio implements GET /v1/orgs/{orgId}/portfolio.
func (s *Server) GetPortfolio(ctx context.Context, r gen.GetPortfolioRequestObject) (gen.GetPortfolioResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	d, err := s.Portfolio.Dashboard(ctx, p, r.OrgId, filterOf(r.Params.Municipality, r.Params.Region, r.Params.GroupId))
	if err != nil {
		return nil, err
	}
	out := gen.GetPortfolio200JSONResponse{Role: gen.Role(d.Role), Currency: d.Currency, Leases: d.Leases, Vacant: d.Vacant,
		Monthly: d.Monthly, Debt: d.Debt, WeightedRisk: d.WeightedRisk, Band: band(d.Band), Period: d.Period, Expected: d.Expected,
		Received: d.Received, Cities: []gen.PortfolioCity{}, Attention: []gen.PortfolioAttention{}}
	for _, c := range d.Cities {
		out.Cities = append(out.Cities, gen.PortfolioCity{Path: c.Path, Name: c.Name, Region: c.Region, Leases: c.Leases, Vacant: c.Vacant,
			Monthly: c.Monthly, Expected: c.Expected, Received: c.Received, Debt: c.Debt, WeightedRisk: c.WeightedRisk, Band: band(c.Band),
			Share: float32(c.Share), Lat: f32(c.Lat), Lng: f32(c.Lng)})
	}
	out.Concentration.Hhi = float32(d.Concentration.HHI)
	out.Concentration.TopCity = shareDTO(d.Concentration.TopCity)
	out.Concentration.TopTenant = shareDTO(d.Concentration.TopTenant)
	out.Concentration.EndingPeak = shareDTO(d.Concentration.EndingPeak)
	for _, it := range d.Attention {
		a := gen.PortfolioAttention{Kind: gen.PortfolioAttentionKind(it.Kind), Severity: it.Severity, Label: it.Label, City: it.City,
			LeaseId: it.LeaseID, UnitId: it.UnitID, Date: dayDTO(it.Date), Score: it.Score}
		if it.Amount != 0 {
			a.Amount = i64(it.Amount)
		}
		out.Attention = append(out.Attention, a)
	}
	for _, t := range d.Trend {
		out.Trend = append(out.Trend, struct {
			Expected     int64  `json:"expected"`
			Period       string `json:"period"`
			Received     int64  `json:"received"`
			WeightedRisk *int   `json:"weighted_risk,omitempty"`
		}{t.Expected, t.Period, t.Received, t.WeightedRisk})
	}
	return out, nil
}

func rentRollRow(r portfolio.Row) gen.RentRollRow {
	out := gen.RentRollRow{Kind: gen.RentRollRowKind(r.Kind), LeaseId: r.LeaseID, UnitId: r.UnitID, State: r.State,
		Municipality: r.Municipality, MunicipalityPath: r.MunicipalityPath, Region: r.Region, RegionPath: &r.RegionPath,
		Address: r.Address, Unit: r.Unit, Currency: r.Currency, GroupIds: []openapi_types.UUID{}, Lat: f32(r.Lat), Lng: f32(r.Lng),
		RiskScore: r.RiskScore, RiskBand: band(r.RiskBand), StartsOn: dayDTO(r.StartsOn), EndsOn: dayDTO(r.EndsOn),
		NoticeOn: dayDTO(r.NoticeOn)}
	out.GroupIds = append(out.GroupIds, r.Groups...)
	if r.Kind == "lease" {
		code, due, tenants := r.Code, r.DueDay, r.Tenants
		out.Code, out.DueDay, out.Tenants = &code, &due, &tenants
		out.Rent, out.Services, out.Deposit, out.DepositPaid = i64(r.Rent), i64(r.Services), i64(r.Deposit), i64(r.DepositPaid)
		out.Billed, out.Paid, out.Debt = i64(r.Billed), i64(r.Paid), i64(r.Debt)
	} else {
		status := r.ListingStatus
		out.ListingStatus = &status
		if r.AskingRent > 0 {
			out.AskingRent = i64(r.AskingRent)
		}
	}
	return out
}

// GetRentRoll implements GET /v1/orgs/{orgId}/portfolio/rent-roll.
func (s *Server) GetRentRoll(ctx context.Context, r gen.GetRentRollRequestObject) (gen.GetRentRollResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, role, err := s.Portfolio.RentRoll(ctx, p, r.OrgId, filterOf(r.Params.Municipality, r.Params.Region, r.Params.GroupId))
	if err != nil {
		return nil, err
	}
	groups, _, err := s.Portfolio.Groups(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	names := map[string]string{}
	for _, g := range groups {
		names[g.ID.String()] = g.Name
	}
	if r.Params.Format != nil {
		switch *r.Params.Format {
		case gen.GetRentRollParamsFormatCsv:
			b := portfolio.RentRollCSV(rows, names)
			return gen.GetRentRoll200TextcsvResponse{Body: bytes.NewReader(b), ContentLength: int64(len(b))}, nil
		case gen.GetRentRollParamsFormatXlsx:
			b, err := portfolio.RentRollXLSX(rows, names)
			if err != nil {
				return nil, err
			}
			return gen.GetRentRoll200ApplicationvndOpenxmlformatsOfficedocumentSpreadsheetmlSheetResponse{Body: bytes.NewReader(b),
				ContentLength: int64(len(b))}, nil
		}
	}
	out := gen.GetRentRoll200JSONResponse{Role: gen.Role(role), Rows: []gen.RentRollRow{}, Groups: []gen.PortfolioGroup{}}
	for _, row := range rows {
		out.Rows = append(out.Rows, rentRollRow(row))
		if row.Kind == "vacant" {
			out.Totals.Vacant++
			continue
		}
		out.Totals.Leases++
		out.Totals.Monthly += row.Monthly()
		out.Totals.Billed += row.Billed
		out.Totals.Paid += row.Paid
		out.Totals.Debt += row.Debt
	}
	for _, g := range groups {
		out.Groups = append(out.Groups, groupDTO(g))
	}
	return out, nil
}

func groupDTO(g portfolio.Group) gen.PortfolioGroup {
	return gen.PortfolioGroup{Id: g.ID, Name: g.Name, Color: g.Color, PropertyIds: g.Properties, LeaseIds: g.Leases}
}

// ListPortfolioGroups implements GET /v1/orgs/{orgId}/portfolio/groups.
func (s *Server) ListPortfolioGroups(ctx context.Context, r gen.ListPortfolioGroupsRequestObject) (gen.ListPortfolioGroupsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	groups, props, err := s.Portfolio.Groups(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	out := gen.ListPortfolioGroups200JSONResponse{Groups: []gen.PortfolioGroup{}}
	for _, g := range groups {
		out.Groups = append(out.Groups, groupDTO(g))
	}
	out.Properties = []struct {
		Address string             `json:"address"`
		Id      openapi_types.UUID `json:"id"`
		Name    string             `json:"name"`
	}{}
	for _, pr := range props {
		out.Properties = append(out.Properties, struct {
			Address string             `json:"address"`
			Id      openapi_types.UUID `json:"id"`
			Name    string             `json:"name"`
		}{pr.Address, pr.ID, pr.Name})
	}
	return out, nil
}

func groupInput(b gen.PortfolioGroupInput) portfolio.GroupInput {
	in := portfolio.GroupInput{Name: b.Name}
	if b.Color != nil {
		in.Color = *b.Color
	}
	if b.PropertyIds != nil {
		in.Properties = *b.PropertyIds
	}
	if b.LeaseIds != nil {
		in.Leases = *b.LeaseIds
	}
	return in
}

func (s *Server) groupByID(ctx context.Context, orgID, id uuid.UUID) (gen.PortfolioGroup, error) {
	p, err := principal(ctx)
	if err != nil {
		return gen.PortfolioGroup{}, err
	}
	groups, _, err := s.Portfolio.Groups(ctx, p, orgID)
	if err != nil {
		return gen.PortfolioGroup{}, err
	}
	for _, g := range groups {
		if g.ID == id {
			return groupDTO(g), nil
		}
	}
	return gen.PortfolioGroup{}, nil
}

// CreatePortfolioGroup implements POST /v1/orgs/{orgId}/portfolio/groups.
func (s *Server) CreatePortfolioGroup(ctx context.Context, r gen.CreatePortfolioGroupRequestObject) (gen.CreatePortfolioGroupResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	id, err := s.Portfolio.SaveGroup(ctx, p, r.OrgId, nil, groupInput(*r.Body))
	if err != nil {
		return nil, err
	}
	g, err := s.groupByID(ctx, r.OrgId, id)
	return gen.CreatePortfolioGroup201JSONResponse(g), err
}

// UpdatePortfolioGroup implements PUT /v1/orgs/{orgId}/portfolio/groups/{portfolioGroupId}.
func (s *Server) UpdatePortfolioGroup(ctx context.Context, r gen.UpdatePortfolioGroupRequestObject) (gen.UpdatePortfolioGroupResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	gid := uuid.UUID(r.PortfolioGroupId)
	if _, err := s.Portfolio.SaveGroup(ctx, p, r.OrgId, &gid, groupInput(*r.Body)); err != nil {
		return nil, err
	}
	g, err := s.groupByID(ctx, r.OrgId, gid)
	return gen.UpdatePortfolioGroup200JSONResponse(g), err
}

// DeletePortfolioGroup implements DELETE /v1/orgs/{orgId}/portfolio/groups/{portfolioGroupId}.
func (s *Server) DeletePortfolioGroup(ctx context.Context, r gen.DeletePortfolioGroupRequestObject) (gen.DeletePortfolioGroupResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Portfolio.DeleteGroup(ctx, p, r.OrgId, uuid.UUID(r.PortfolioGroupId)); err != nil {
		return nil, err
	}
	return gen.DeletePortfolioGroup204Response{}, nil
}

func rulesDTO(r portfolio.Rules) gen.PortfolioRules {
	return gen.PortfolioRules{ReminderBeforeDays: r.ReminderBeforeDays, OverdueDays: r.OverdueDays, EscalationDays: r.EscalationDays,
		DepositMonths: r.DepositMonths, NoticeMonths: r.NoticeMonths}
}

// ListPortfolioRules implements GET /v1/orgs/{orgId}/portfolio/rules.
func (s *Server) ListPortfolioRules(ctx context.Context, r gen.ListPortfolioRulesRequestObject) (gen.ListPortfolioRulesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rules, munis, err := s.Portfolio.Rules(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	out := gen.ListPortfolioRules200JSONResponse{Rules: []gen.PortfolioRule{}, Defaults: rulesDTO(portfolio.Defaults())}
	for _, x := range rules {
		parsed, err := portfolio.ParseRules(x.Rules)
		if err != nil {
			return nil, err
		}
		rule := gen.PortfolioRule{Id: x.ID, Scope: gen.PortfolioRuleScope(x.Scope), ScopeName: x.ScopeName, Rules: rulesDTO(parsed),
			UpdatedAt: x.UpdatedAt, GroupId: x.GroupID}
		if x.AdminPath != "" {
			path := x.AdminPath
			rule.Municipality = &path
		}
		out.Rules = append(out.Rules, rule)
	}
	out.Municipalities = []struct {
		Name string `json:"name"`
		Path string `json:"path"`
	}{}
	for _, m := range munis {
		out.Municipalities = append(out.Municipalities, struct {
			Name string `json:"name"`
			Path string `json:"path"`
		}{m.Name, m.Path})
	}
	return out, nil
}

// SavePortfolioRule implements PUT /v1/orgs/{orgId}/portfolio/rules.
func (s *Server) SavePortfolioRule(ctx context.Context, r gen.SavePortfolioRuleRequestObject) (gen.SavePortfolioRuleResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b := r.Body
	rules := portfolio.Rules{ReminderBeforeDays: b.Rules.ReminderBeforeDays, OverdueDays: b.Rules.OverdueDays,
		EscalationDays: b.Rules.EscalationDays, DepositMonths: b.Rules.DepositMonths, NoticeMonths: b.Rules.NoticeMonths}
	muni := ""
	if b.Municipality != nil {
		muni = *b.Municipality
	}
	id, err := s.Portfolio.SaveRule(ctx, p, r.OrgId, muni, b.GroupId, rules)
	if err != nil {
		return nil, err
	}
	return gen.SavePortfolioRule200JSONResponse{Id: id}, nil
}

// DeletePortfolioRule implements DELETE /v1/orgs/{orgId}/portfolio/rules/{ruleId}.
func (s *Server) DeletePortfolioRule(ctx context.Context, r gen.DeletePortfolioRuleRequestObject) (gen.DeletePortfolioRuleResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Portfolio.DeleteRule(ctx, p, r.OrgId, uuid.UUID(r.RuleId)); err != nil {
		return nil, err
	}
	return gen.DeletePortfolioRule204Response{}, nil
}

// ResolvePortfolioRules implements GET /v1/orgs/{orgId}/portfolio/rules/resolve.
func (s *Server) ResolvePortfolioRules(ctx context.Context, r gen.ResolvePortfolioRulesRequestObject) (gen.ResolvePortfolioRulesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	address := ""
	if r.Params.Address != nil {
		address = *r.Params.Address
	}
	res, place, err := s.Portfolio.ResolveRules(ctx, p, r.OrgId, r.Params.ListingId, r.Params.RuianId, address)
	if err != nil {
		return nil, err
	}
	out := gen.ResolvePortfolioRules200JSONResponse{Rules: rulesDTO(res.Rules), Place: place}
	for _, src := range res.Sources {
		out.Sources = append(out.Sources, gen.ResolvedRulesSources(src))
	}
	return out, nil
}

// GetRiskWeights implements GET /v1/orgs/{orgId}/portfolio/risk-weights.
func (s *Server) GetRiskWeights(ctx context.Context, r gen.GetRiskWeightsRequestObject) (gen.GetRiskWeightsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	w, err := s.Portfolio.Weights(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	return gen.GetRiskWeights200JSONResponse{Weights: w, Defaults: portfolio.DefaultWeights()}, nil
}

// SetRiskWeights implements PUT /v1/orgs/{orgId}/portfolio/risk-weights.
func (s *Server) SetRiskWeights(ctx context.Context, r gen.SetRiskWeightsRequestObject) (gen.SetRiskWeightsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Portfolio.SetWeights(ctx, p, r.OrgId, r.Body.Weights); err != nil {
		return nil, err
	}
	w, err := s.Portfolio.Weights(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	return gen.SetRiskWeights200JSONResponse{Weights: w, Defaults: portfolio.DefaultWeights()}, nil
}

func summaryDTO(s portfolio.Summary) gen.PortfolioSummary {
	return gen.PortfolioSummary{Summary: s.PortfolioSummary.Summary, Changes: s.Changes, Actions: s.Actions, Model: s.Model, CreatedAt: s.CreatedAt}
}

// GetPortfolioSummary implements GET /v1/orgs/{orgId}/portfolio/summary.
func (s *Server) GetPortfolioSummary(ctx context.Context, r gen.GetPortfolioSummaryRequestObject) (gen.GetPortfolioSummaryResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	sum, err := s.Portfolio.LatestSummary(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	out := gen.GetPortfolioSummary200JSONResponse{}
	if sum != nil {
		d := summaryDTO(*sum)
		out.Summary = &d
	}
	return out, nil
}

// CreatePortfolioSummary implements POST /v1/orgs/{orgId}/portfolio/summary.
func (s *Server) CreatePortfolioSummary(ctx context.Context, r gen.CreatePortfolioSummaryRequestObject) (gen.CreatePortfolioSummaryResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	sum, err := s.Portfolio.Summarize(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	return gen.CreatePortfolioSummary201JSONResponse(summaryDTO(sum)), nil
}

// GetLeaseRisk implements GET /v1/leases/{leaseId}/risk.
func (s *Server) GetLeaseRisk(ctx context.Context, r gen.GetLeaseRiskRequestObject) (gen.GetLeaseRiskResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	lr, err := s.Portfolio.LeaseRisk(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	out := gen.GetLeaseRisk200JSONResponse{Score: lr.Score, Band: band(lr.Band), ModelVersion: lr.ModelVersion,
		ComputedAt: lr.ComputedAt, Landlord: lr.Landlord, Factors: []gen.RiskFactor{}}
	for _, f := range lr.Factors {
		gf := gen.RiskFactor{Key: gen.RiskFactorKey(f.Key), Group: gen.RiskFactorGroup(f.Group), Value: float32(f.Value), Known: f.Known}
		if lr.Landlord {
			w, pts := f.Weight, float32(f.Points)
			gf.Weight, gf.Points = &w, &pts
		}
		if len(f.Detail) > 0 {
			// Round-trip so numbers keep their JSON form.
			var d map[string]any
			b, _ := json.Marshal(f.Detail)
			_ = json.Unmarshal(b, &d)
			gf.Detail = &d
		}
		out.Factors = append(out.Factors, gf)
	}
	return out, nil
}
