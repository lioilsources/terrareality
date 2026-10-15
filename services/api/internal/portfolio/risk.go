// Package portfolio implements the owner's view across municipalities:
// rent roll, groups, rules per municipality or group, the deterministic
// lease risk score and portfolio aggregates (ADR 0010). Scores explain
// themselves factor by factor and never decide about a tenant (ADR 0003).
package portfolio

import (
	"math"
	"time"
)

// ModelVersion identifies the scoring rules stored with every score.
const ModelVersion = "risk-v0.1"

// Factor groups.
const (
	GroupPayments = "payments"
	GroupDeposit  = "deposit"
	GroupPassport = "passport"
	GroupContract = "contract"
	GroupLocation = "location"
)

// FactorDef is a factor of the model with its default weight (the weights
// sum to 100, so a factor at full value adds its weight to the score).
type FactorDef struct {
	Key           string
	Group         string
	Weight        int
	TenantVisible bool // shown to the tenant (payments on their own lease)
}

// Factors of the model in display order.
var Factors = []FactorDef{
	{"debt", GroupPayments, 15, true},
	{"escalations", GroupPayments, 12, true},
	{"overdue_days", GroupPayments, 8, true},
	{"deposit_coverage", GroupDeposit, 15, true},
	{"passport", GroupPassport, 15, false},
	{"term_end", GroupContract, 8, false},
	{"notice", GroupContract, 8, false},
	{"joint_nonpayer", GroupContract, 4, false},
	{"market_rent", GroupLocation, 8, false},
	{"market_supply", GroupLocation, 7, false},
}

// DefaultWeights returns the model weights by factor key.
func DefaultWeights() map[string]int {
	out := make(map[string]int, len(Factors))
	for _, f := range Factors {
		out[f.Key] = f.Weight
	}
	return out
}

// Party is what the model uses about one tenant party.
type Party struct {
	Overdue       int64 // rent, services and one-off items due and unpaid
	DepositUnpaid int64
	DepositPaid   int64
	OldestUnpaid  *time.Time
	HasAccount    bool   // the party has a user account (passport facts known)
	Verification  string // none | email | phone | identity
	IncomeProof   bool
	Insolvency    string // unchecked | clear | record | error
}

// Input is everything the score depends on. Protected characteristics are
// not part of it (they are not collected at all).
type Input struct {
	Today       time.Time
	State       string
	Monthly     int64 // rent + services
	Rent        int64
	Deposit     int64 // agreed
	EndsOn      *time.Time
	NoticeGiven bool
	Escalations int // payment escalations (D+7) in the last 12 months
	Parties     []Party
	// Local market from our own search data (zero = unknown).
	MedianRent     int64
	MarketListings int
	AvgListingDays float64
}

// Factor is one explained part of a score.
type Factor struct {
	Key           string         `json:"key"`
	Group         string         `json:"group"`
	Weight        int            `json:"weight"`
	Value         float64        `json:"value"`  // 0..1
	Points        float64        `json:"points"` // contribution to the score
	Known         bool           `json:"known"`  // false: no data, counted as 0
	TenantVisible bool           `json:"tenant_visible"`
	Detail        map[string]any `json:"detail,omitempty"`
}

// Result is a score with its factors.
type Result struct {
	Score   int      `json:"score"`
	Band    string   `json:"band"`
	Factors []Factor `json:"factors"`
}

// Band thresholds: below 25 low, below 50 medium, otherwise high.
func Band(score int) string {
	switch {
	case score < 25:
		return "low"
	case score < 50:
		return "medium"
	default:
		return "high"
	}
}

func clamp01(x float64) float64 { return math.Max(0, math.Min(1, x)) }

func round(x float64, places int) float64 {
	p := math.Pow(10, float64(places))
	return math.Round(x*p) / p
}

// Score computes the risk of a lease. weights override the defaults per
// factor key (0 switches a factor off); they are normalized to 100.
func Score(in Input, weights map[string]int) Result {
	w := DefaultWeights()
	for k, v := range weights {
		if _, ok := w[k]; ok && v >= 0 {
			w[k] = v
		}
	}
	total := 0
	for _, v := range w {
		total += v
	}
	var overdue, depositUnpaid, depositPaid int64
	var oldest *time.Time
	payers, nonPayers := 0, 0
	for _, p := range in.Parties {
		overdue += p.Overdue
		depositUnpaid += p.DepositUnpaid
		depositPaid += p.DepositPaid
		if p.OldestUnpaid != nil && (oldest == nil || p.OldestUnpaid.Before(*oldest)) {
			t := *p.OldestUnpaid
			oldest = &t
		}
		if p.Overdue > 0 {
			nonPayers++
		} else {
			payers++
		}
	}
	monthly := float64(max(in.Monthly, 1))
	values := map[string]Factor{}
	set := func(key string, v float64, known bool, detail map[string]any) {
		values[key] = Factor{Value: round(clamp01(v), 3), Known: known, Detail: detail}
	}

	// Payments: two months of debt, three escalations a year or sixty days
	// overdue reach the full weight.
	set("debt", float64(overdue)/monthly/2, true, map[string]any{"amount": overdue, "monthly": in.Monthly})
	set("escalations", float64(in.Escalations)/3, true, map[string]any{"count": in.Escalations})
	days := 0
	if oldest != nil {
		days = int(in.Today.Sub(*oldest).Hours() / 24)
	}
	set("overdue_days", float64(days)/60, true, map[string]any{"days": days})

	// Deposit: the debt not covered by the paid deposit, in months; a lease
	// whose agreed deposit was not paid has no cushion at all. Without an
	// agreed deposit only the uncovered debt counts.
	uncovered := max(overdue-depositPaid, 0)
	cov := float64(uncovered) / monthly
	if depositPaid == 0 && in.Deposit > 0 {
		cov = math.Max(cov, 0.5)
	}
	set("deposit_coverage", cov, true, map[string]any{"deposit": in.Deposit, "deposit_paid": depositPaid,
		"deposit_unpaid": depositUnpaid, "uncovered": uncovered})

	// Tenant Passport: the average over tenants; a tenant without an account
	// counts as unknown (0.6).
	if len(in.Parties) > 0 {
		sum := 0.0
		identity, income, record := 0, 0, 0
		for _, p := range in.Parties {
			if !p.HasAccount {
				sum += 0.6
				continue
			}
			v := 0.0
			if p.Verification != "identity" {
				v += 0.4
			} else {
				identity++
			}
			if !p.IncomeProof {
				v += 0.3
			} else {
				income++
			}
			if p.Insolvency == "record" {
				v = 1
				record++
			}
			sum += clamp01(v)
		}
		set("passport", sum/float64(len(in.Parties)), true, map[string]any{"tenants": len(in.Parties),
			"identity": identity, "income_proof": income, "insolvency_records": record})
	} else {
		set("passport", 0, false, nil)
	}

	// Contract: a fixed term ending within 90 days (vacancy), notice, and a
	// joint tenancy where one tenant pays and another does not.
	if in.EndsOn != nil {
		left := int(in.EndsOn.Sub(in.Today).Hours() / 24)
		v := 0.0
		if left <= 90 {
			v = float64(90-max(left, 0)) / 90
		}
		set("term_end", v, true, map[string]any{"days_left": left})
	} else {
		set("term_end", 0, true, map[string]any{"indefinite": true})
	}
	notice := 0.0
	if in.NoticeGiven || in.State == "notice_given" {
		notice = 1
	}
	set("notice", notice, true, nil)
	joint := 0.0
	if len(in.Parties) > 1 && payers > 0 && nonPayers > 0 {
		joint = 1
	}
	set("joint_nonpayer", joint, true, map[string]any{"paying": payers, "behind": nonPayers})

	// Location: rent 50 % above the local median, or listings staying on the
	// market for 90 days, reach the full weight. Too little data = unknown.
	if in.MedianRent > 0 && in.MarketListings >= 3 {
		ratio := float64(in.Rent) / float64(in.MedianRent)
		set("market_rent", (ratio-1)/0.5, true, map[string]any{"median": in.MedianRent, "ratio": round(ratio, 2),
			"listings": in.MarketListings})
	} else {
		set("market_rent", 0, false, map[string]any{"listings": in.MarketListings})
	}
	if in.MarketListings >= 3 {
		set("market_supply", (in.AvgListingDays-30)/60, true, map[string]any{"avg_days": int(math.Round(in.AvgListingDays)),
			"listings": in.MarketListings})
	} else {
		set("market_supply", 0, false, map[string]any{"listings": in.MarketListings})
	}

	out := Result{Factors: make([]Factor, 0, len(Factors))}
	score := 0.0
	for _, d := range Factors {
		f := values[d.Key]
		f.Key, f.Group, f.TenantVisible = d.Key, d.Group, d.TenantVisible
		f.Weight = w[d.Key]
		if total > 0 {
			f.Points = round(f.Value*float64(w[d.Key])*100/float64(total), 1)
		}
		score += f.Points
		out.Factors = append(out.Factors, f)
	}
	out.Score = int(math.Round(math.Min(100, score)))
	out.Band = Band(out.Score)
	return out
}
