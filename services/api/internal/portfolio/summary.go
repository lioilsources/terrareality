package portfolio

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
)

// Summary is a stored AI suggestion about the portfolio.
type Summary struct {
	ai.PortfolioSummary
	CreatedAt time.Time
}

// Facts turns the dashboard into aggregates without personal data.
func Facts(d Dashboard) ai.PortfolioFacts {
	f := ai.PortfolioFacts{Currency: d.Currency, Leases: d.Leases, Vacant: d.Vacant, Monthly: d.Monthly, Debt: d.Debt,
		WeightedRisk: d.WeightedRisk, Expected: d.Expected, Received: d.Received, Attention: map[string]int{},
		Cities: []ai.CityFacts{}, RiskTrend: []ai.TrendFacts{}}
	for _, c := range d.Cities {
		name := c.Name
		if name == "" {
			name = "neurčeno"
		}
		f.Cities = append(f.Cities, ai.CityFacts{Name: name, Leases: c.Leases, Vacant: c.Vacant, Monthly: c.Monthly, Debt: c.Debt,
			WeightedRisk: c.WeightedRisk})
	}
	if t := d.Concentration.TopCity; t != nil {
		f.TopCity, f.TopCityShare = t.Name, t.Share
	}
	if e := d.Concentration.EndingPeak; e != nil {
		f.EndingPeak, f.EndingCount = e.Name, e.Count
	}
	for _, it := range d.Attention {
		f.Attention[it.Kind]++
	}
	for _, t := range d.Trend {
		f.RiskTrend = append(f.RiskTrend, ai.TrendFacts{Period: t.Period, Expected: t.Expected, Received: t.Received,
			WeightedRisk: t.WeightedRisk})
	}
	return f
}

// Summarize asks the AI for a summary of the portfolio and stores it. If the
// model is unavailable the rules-based summary is used; either way it is a
// suggestion for the owner (ADR 0003).
func (s *Service) Summarize(ctx context.Context, p *auth.Principal, orgID uuid.UUID) (Summary, error) {
	d, err := s.Dashboard(ctx, p, orgID, Filter{})
	if err != nil {
		return Summary{}, err
	}
	facts := Facts(d)
	var sum ai.PortfolioSummary
	if s.AI != nil {
		cctx, cancel := context.WithTimeout(ctx, 60*time.Second)
		sum, err = s.AI.SummarizePortfolio(cctx, facts)
		cancel()
	}
	if s.AI == nil || err != nil {
		sum, _ = ai.Mock{}.SummarizePortfolio(ctx, facts)
	}
	body, _ := json.Marshal(sum)
	input, _ := json.Marshal(facts)
	var out Summary
	err = s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolioRead); err != nil {
			return err
		}
		row, err := q.InsertPortfolioSummary(ctx, db.InsertPortfolioSummaryParams{OrgID: orgID, Body: string(body), Model: sum.Model,
			Input: input, CreatedBy: &p.UserID})
		out = Summary{PortfolioSummary: sum, CreatedAt: row.CreatedAt}
		return err
	})
	return out, err
}

// LatestSummary returns the last summary, nil when there is none.
func (s *Service) LatestSummary(ctx context.Context, p *auth.Principal, orgID uuid.UUID) (*Summary, error) {
	var out *Summary
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermPortfolioRead); err != nil {
			return err
		}
		row, err := q.LatestPortfolioSummary(ctx, orgID)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil
		}
		if err != nil {
			return err
		}
		var sum ai.PortfolioSummary
		if err := json.Unmarshal([]byte(row.Body), &sum); err != nil {
			return err
		}
		out = &Summary{PortfolioSummary: sum, CreatedAt: row.CreatedAt}
		return nil
	})
	return out, err
}
