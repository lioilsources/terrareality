package ai

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
)

// PortfolioFacts are aggregates of a landlord's portfolio. They contain no
// personal data: no tenant names, addresses or individual scores.
type PortfolioFacts struct {
	Currency     string         `json:"currency"`
	Leases       int            `json:"leases"`
	Vacant       int            `json:"vacant_units"`
	Monthly      int64          `json:"monthly_income"` // minor units
	Debt         int64          `json:"debt"`
	WeightedRisk *int           `json:"weighted_risk,omitempty"` // 0-100
	Expected     int64          `json:"expected_this_month"`
	Received     int64          `json:"received_this_month"`
	Cities       []CityFacts    `json:"cities"`
	TopCityShare float64        `json:"top_city_share"`
	TopCity      string         `json:"top_city,omitempty"`
	EndingPeak   string         `json:"ending_peak_month,omitempty"`
	EndingCount  int            `json:"ending_peak_leases,omitempty"`
	Attention    map[string]int `json:"attention"` // kind -> count
	RiskTrend    []TrendFacts   `json:"risk_trend"`
}

// CityFacts are the aggregates of one municipality.
type CityFacts struct {
	Name         string `json:"name"`
	Leases       int    `json:"leases"`
	Vacant       int    `json:"vacant"`
	Monthly      int64  `json:"monthly_income"`
	Debt         int64  `json:"debt"`
	WeightedRisk *int   `json:"weighted_risk,omitempty"`
}

// TrendFacts is one month of the portfolio trend.
type TrendFacts struct {
	Period       string `json:"period"`
	Expected     int64  `json:"expected"`
	Received     int64  `json:"received"`
	WeightedRisk *int   `json:"weighted_risk,omitempty"`
}

// PortfolioSummary is a suggestion the owner reads; it decides nothing.
type PortfolioSummary struct {
	Summary string   `json:"summary"` // Czech, a few sentences
	Changes []string `json:"changes"` // what got worse or better
	Actions []string `json:"actions"` // suggested next steps for the owner
	Model   string   `json:"model"`
}

// PortfolioSummarizer writes portfolio summaries.
type PortfolioSummarizer interface {
	SummarizePortfolio(ctx context.Context, f PortfolioFacts) (PortfolioSummary, error)
}

func czk(minor int64) string {
	whole := fmt.Sprint(minor / 100)
	var b strings.Builder
	for i, r := range whole {
		if i > 0 && (len(whole)-i)%3 == 0 {
			b.WriteRune(' ')
		}
		b.WriteRune(r)
	}
	return b.String() + " Kč"
}

// SummarizePortfolio implements PortfolioSummarizer with rules.
func (Mock) SummarizePortfolio(_ context.Context, f PortfolioFacts) (PortfolioSummary, error) {
	out := PortfolioSummary{Model: "mock-rules", Changes: []string{}, Actions: []string{}}
	parts := []string{fmt.Sprintf("Běžící nájmy: %d, obce: %d, měsíční předpis %s", f.Leases, len(f.Cities), czk(f.Monthly))}
	if f.WeightedRisk != nil {
		parts = append(parts, fmt.Sprintf("vážené riziko je %d/100", *f.WeightedRisk))
	}
	out.Summary = strings.Join(parts, ", ") + "."
	if f.Expected > 0 {
		out.Summary += fmt.Sprintf(" Tento měsíc přišlo %s z očekávaných %s.", czk(f.Received), czk(f.Expected))
	}
	var worst *CityFacts
	for i := range f.Cities {
		c := &f.Cities[i]
		if c.WeightedRisk != nil && (worst == nil || *c.WeightedRisk > *worst.WeightedRisk) {
			worst = c
		}
	}
	if worst != nil && len(f.Cities) > 1 {
		out.Changes = append(out.Changes, fmt.Sprintf("Nejrizikovější obec je %s (vážené riziko %d/100, dluh %s).",
			worst.Name, *worst.WeightedRisk, czk(worst.Debt)))
	}
	if n := len(f.RiskTrend); n >= 2 && f.RiskTrend[n-1].WeightedRisk != nil && f.RiskTrend[n-2].WeightedRisk != nil {
		d := *f.RiskTrend[n-1].WeightedRisk - *f.RiskTrend[n-2].WeightedRisk
		switch {
		case d > 0:
			out.Changes = append(out.Changes, fmt.Sprintf("Riziko oproti minulému měsíci vzrostlo (+%d).", d))
		case d < 0:
			out.Changes = append(out.Changes, fmt.Sprintf("Riziko oproti minulému měsíci kleslo (−%d).", -d))
		}
	}
	if f.TopCityShare >= 0.6 && len(f.Cities) > 1 {
		out.Changes = append(out.Changes, fmt.Sprintf("%.0f %% příjmu pochází z jedné obce (%s).", f.TopCityShare*100, f.TopCity))
	}
	if n := f.Attention["escalation"]; n > 0 {
		out.Actions = append(out.Actions, fmt.Sprintf("Eskalované platby (%d): ozvěte se nájemcům a domluvte splátkový kalendář.", n))
	}
	if f.Debt > 0 {
		out.Actions = append(out.Actions, fmt.Sprintf("Zkontrolujte dluh %s a krytí kaucí v rent rollu.", czk(f.Debt)))
	}
	if n := f.Attention["ending"]; n > 0 {
		out.Actions = append(out.Actions, fmt.Sprintf("Smlouvy končící do 90 dní (%d): rozhodněte o prodloužení.", n))
	}
	if f.EndingCount > 1 {
		out.Actions = append(out.Actions, fmt.Sprintf("V měsíci %s končí najednou smlouvy (%d); zvažte rozložení konců.", f.EndingPeak, f.EndingCount))
	}
	if f.Vacant > 0 {
		out.Actions = append(out.Actions, fmt.Sprintf("Volné jednotky (%d): zveřejněte nebo upravte inzerci.", f.Vacant))
	}
	return out, nil
}

const portfolioSystem = `You help a landlord in Czechia read the aggregates of their rental portfolio across
municipalities. In Czech, write a short neutral summary (two or three sentences), list what changed
(better or worse) and suggest practical next steps for the owner. Amounts are in minor units of the given
currency. Never suggest sanctions, evictions or decisions about specific tenants and never infer anything
about people: the owner decides. Answer with one JSON object only.`

// SummarizePortfolio implements PortfolioSummarizer.
func (c *Client) SummarizePortfolio(ctx context.Context, f PortfolioFacts) (PortfolioSummary, error) {
	in, _ := json.MarshalIndent(f, "", "  ")
	list := map[string]any{"type": "array", "items": map[string]any{"type": "string"}}
	schema := map[string]any{"type": "object", "properties": map[string]any{
		"summary": map[string]any{"type": "string"}, "changes": list, "actions": list,
	}, "required": []string{"summary", "changes", "actions"}}
	var out PortfolioSummary
	if err := c.complete(ctx, portfolioSystem, "Portfolio:\n"+string(in), "portfolio_summary", schema, &out); err != nil {
		return PortfolioSummary{}, err
	}
	if out.Changes == nil {
		out.Changes = []string{}
	}
	if out.Actions == nil {
		out.Actions = []string{}
	}
	out.Model = c.Model
	return out, nil
}
