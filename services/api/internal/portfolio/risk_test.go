package portfolio

import (
	"testing"
	"time"
)

func d(s string) time.Time {
	t, _ := time.Parse("2006-01-02", s)
	return t
}

func ptrT(t time.Time) *time.Time { return &t }

func factor(r Result, key string) Factor {
	for _, f := range r.Factors {
		if f.Key == key {
			return f
		}
	}
	return Factor{}
}

func TestWeightsSumTo100(t *testing.T) {
	sum := 0
	for _, f := range Factors {
		sum += f.Weight
	}
	if sum != 100 {
		t.Fatalf("default weights sum to %d", sum)
	}
}

func TestScoreGoodPayer(t *testing.T) {
	r := Score(Input{Today: d("2026-10-15"), State: "active", Monthly: 2_400_000, Rent: 2_000_000, Deposit: 4_000_000,
		Parties: []Party{{DepositPaid: 4_000_000, HasAccount: true, Verification: "identity", IncomeProof: true, Insolvency: "clear"}}}, nil)
	if r.Score != 0 || r.Band != "low" {
		t.Fatalf("got %d %s, want 0 low: %+v", r.Score, r.Band, r.Factors)
	}
	if f := factor(r, "market_rent"); f.Known {
		t.Fatal("market data without listings must be unknown")
	}
}

func TestScoreDebtorIsHigh(t *testing.T) {
	today := d("2026-10-15")
	r := Score(Input{Today: today, State: "active", Monthly: 2_400_000, Rent: 2_000_000, Deposit: 4_000_000, Escalations: 2,
		Parties: []Party{{Overdue: 4_800_000, DepositUnpaid: 4_000_000, OldestUnpaid: ptrT(today.AddDate(0, 0, -45)),
			HasAccount: true, Verification: "email"}}}, nil)
	if r.Band != "high" {
		t.Fatalf("got %d %s, want high", r.Score, r.Band)
	}
	if f := factor(r, "debt"); f.Value != 1 || f.Points != 15 {
		t.Fatalf("debt factor %+v", f)
	}
	if f := factor(r, "overdue_days"); f.Detail["days"] != 45 {
		t.Fatalf("overdue days %+v", f)
	}
	if f := factor(r, "deposit_coverage"); f.Value != 1 {
		t.Fatalf("deposit coverage %+v", f)
	}
}

func TestDepositCoversDebt(t *testing.T) {
	today := d("2026-10-15")
	in := Input{Today: today, State: "active", Monthly: 2_000_000, Rent: 2_000_000, Deposit: 6_000_000,
		Parties: []Party{{Overdue: 2_000_000, DepositPaid: 6_000_000, OldestUnpaid: ptrT(today.AddDate(0, 0, -10)), HasAccount: true,
			Verification: "identity", IncomeProof: true}}}
	if f := factor(Score(in, nil), "deposit_coverage"); f.Value != 0 {
		t.Fatalf("a paid deposit larger than the debt covers it: %+v", f)
	}
}

func TestContractFactors(t *testing.T) {
	today := d("2026-10-15")
	r := Score(Input{Today: today, State: "notice_given", Monthly: 1_000_000, Rent: 1_000_000, EndsOn: ptrT(today.AddDate(0, 0, 45)),
		Parties: []Party{{HasAccount: true, Verification: "identity", IncomeProof: true, DepositPaid: 1},
			{Overdue: 500_000, HasAccount: true, Verification: "identity", IncomeProof: true, DepositPaid: 1}}}, nil)
	if f := factor(r, "term_end"); f.Value != 0.5 {
		t.Fatalf("45 of 90 days left = 0.5: %+v", f)
	}
	if factor(r, "notice").Value != 1 || factor(r, "joint_nonpayer").Value != 1 {
		t.Fatalf("notice and joint non-payer expected: %+v", r.Factors)
	}
}

func TestMarketFactors(t *testing.T) {
	r := Score(Input{Today: d("2026-10-15"), State: "active", Monthly: 3_000_000, Rent: 3_000_000, MedianRent: 2_000_000,
		MarketListings: 10, AvgListingDays: 60, Parties: []Party{{HasAccount: true, Verification: "identity", IncomeProof: true, DepositPaid: 1}}}, nil)
	if f := factor(r, "market_rent"); f.Value != 1 || !f.Known {
		t.Fatalf("rent 50%% over the median = 1: %+v", f)
	}
	if f := factor(r, "market_supply"); f.Value != 0.5 {
		t.Fatalf("60 days on market = 0.5: %+v", f)
	}
}

func TestCustomWeightsNormalize(t *testing.T) {
	today := d("2026-10-15")
	in := Input{Today: today, State: "active", Monthly: 1_000_000, Rent: 1_000_000,
		Parties: []Party{{Overdue: 2_000_000, DepositPaid: 5_000_000, OldestUnpaid: ptrT(today.AddDate(0, 0, -1)), HasAccount: true,
			Verification: "identity", IncomeProof: true}}}
	w := map[string]int{}
	for _, f := range Factors {
		w[f.Key] = 0
	}
	w["debt"] = 10
	r := Score(in, w)
	if r.Score != 100 {
		t.Fatalf("debt alone at full value with all weight = 100, got %d", r.Score)
	}
}

func TestDeterministic(t *testing.T) {
	today := d("2026-10-15")
	in := Input{Today: today, State: "active", Monthly: 2_000_000, Rent: 2_000_000, Escalations: 1,
		Parties: []Party{{Overdue: 1_000_000, OldestUnpaid: ptrT(today.AddDate(0, 0, -20))}}}
	a, b := Score(in, nil), Score(in, nil)
	if a.Score != b.Score || len(a.Factors) != len(b.Factors) {
		t.Fatal("same input, different score")
	}
}

func TestRulesMergeAndValidate(t *testing.T) {
	ten := 10
	r := Defaults().Merge(Rules{EscalationDays: &ten})
	if *r.EscalationDays != 10 || *r.OverdueDays != 1 {
		t.Fatalf("merge: %+v", r)
	}
	one := 1
	if err := (Rules{OverdueDays: &ten, EscalationDays: &one}).Validate(3); err == nil {
		t.Fatal("escalation before the overdue reminder must fail")
	}
	five := 5
	if err := (Rules{DepositMonths: &five}).Validate(3); err == nil {
		t.Fatal("deposit above the jurisdiction maximum must fail")
	}
	if got := LeaseRules([]byte(`{"rules":{"escalation_days":10}}`)); *got.EscalationDays != 10 || *got.ReminderBeforeDays != 3 {
		t.Fatalf("lease rules: %+v", got)
	}
}

func TestHelpers(t *testing.T) {
	if got := municipalityPath("cz.jihomoravsky_kraj.brno.brno_stred"); got != "cz.jihomoravsky_kraj.brno" {
		t.Fatal(got)
	}
	if got := municipalityPath("cz.hlavni_mesto_praha.praha"); got != "cz.hlavni_mesto_praha.praha" {
		t.Fatal(got)
	}
	if got := municipalityPath("cz.kraj"); got != "" {
		t.Fatal(got)
	}
	if got := initials("Anna Nováková, Ben Dvořák"); got != "A. N., B. D." {
		t.Fatal(got)
	}
}

func TestExportCSV(t *testing.T) {
	score := 42
	rows := []Row{{Kind: "lease", Code: 2600000001, Municipality: "Brno", Address: "Kounicova 20", Rent: 2_000_000, Services: 300_000,
		Currency: "CZK", Billed: 4_600_000, Paid: 2_300_000, Debt: 2_300_000, RiskScore: &score, RiskBand: "medium"},
		{Kind: "vacant", Municipality: "Ostrava", Address: "Nádražní 20", Currency: "CZK", AskingRent: 1_500_000}}
	got := string(RentRollCSV(rows, nil))
	want := "kind,municipality,region,address,unit,lease_code,state,tenants,rent,services,currency,due_day,starts_on,ends_on,notice_on,deposit,deposit_paid,billed,paid,debt,risk_score,risk_band,groups,asking_rent\n" +
		"lease,Brno,,Kounicova 20,,2600000001,,,20000.00,3000.00,CZK,,,,,0.00,0.00,46000.00,23000.00,23000.00,42,medium,,\n" +
		"vacant,Ostrava,,Nádražní 20,,,,,,,CZK,,,,,,,,,,,,,15000.00\n"
	if got != want {
		t.Fatalf("csv:\n%s\nwant:\n%s", got, want)
	}
	if _, err := RentRollXLSX(rows, nil); err != nil {
		t.Fatal(err)
	}
}

// Without an agreed deposit there is no missing cushion: only uncovered debt counts.
func TestNoDepositAgreed(t *testing.T) {
	today := d("2026-10-15")
	in := Input{Today: today, State: "active", Monthly: 2_000_000, Rent: 2_000_000,
		Parties: []Party{{HasAccount: true, Verification: "identity", IncomeProof: true}}}
	if f := factor(Score(in, nil), "deposit_coverage"); f.Value != 0 {
		t.Fatalf("no deposit agreed, no debt: %+v", f)
	}
	in.Deposit = 4_000_000
	if f := factor(Score(in, nil), "deposit_coverage"); f.Value != 0.5 {
		t.Fatalf("agreed deposit unpaid: %+v", f)
	}
}
