package leasing

import (
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

func ymd(s string) time.Time {
	t, err := time.Parse("2006-01-02", s)
	if err != nil {
		panic(err)
	}
	return t
}

// A lease running since 2024 imported in October 2026: nothing before the
// cutover is scheduled, the held deposit is not, the opening balance is one
// item due on the cutover day.
func TestImportScheduleFromCutover(t *testing.T) {
	terms := Terms{StartsOn: ymd("2024-03-01"), Rent: 1_800_000, Services: 350_000, Deposit: 3_600_000, DueDay: 5}
	shares := []Share{{PartyID: "a", ShareBps: 5000}, {PartyID: "b", ShareBps: 5000}}
	cut := ymd("2026-11-01")
	items := ImportSchedule(terms, shares, Cutover{On: cut, DepositHeld: true, Opening: map[string]int64{"a": 650_000, "b": 0}})
	if len(items) != 1+IndefiniteHorizon {
		t.Fatalf("items %d: %+v", len(items), items)
	}
	op := items[0]
	if op.Kind != KindOpeningBalance || !op.DueOn.Equal(cut) || op.Amount != 650_000 || len(op.Splits) != 1 || op.Splits["a"] != 650_000 {
		t.Fatalf("opening balance %+v", op)
	}
	for _, it := range items {
		if it.DueOn.Before(cut) {
			t.Fatalf("item before the cutover: %+v", it)
		}
		if it.Kind == "deposit" {
			t.Fatalf("held deposit scheduled: %+v", it)
		}
		var sum int64
		for _, v := range it.Splits {
			sum += v
		}
		if sum != it.Amount {
			t.Fatalf("splits of %s %s add up to %d, not %d", it.Kind, it.Period, sum, it.Amount)
		}
	}
	if items[1].Kind != "rent" || items[1].Period != "2026-11" || !items[1].DueOn.Equal(ymd("2026-11-05")) || items[1].Amount != 2_150_000 {
		t.Fatalf("first rent %+v", items[1])
	}

	// Deposit not collected yet: due on the cutover; no opening balance item.
	items = ImportSchedule(terms, shares, Cutover{On: cut})
	if items[0].Kind != "deposit" || !items[0].DueOn.Equal(cut) || items[0].Amount != 3_600_000 {
		t.Fatalf("deposit %+v", items[0])
	}
	for _, it := range items {
		if it.Kind == KindOpeningBalance {
			t.Fatalf("zero opening balance scheduled: %+v", it)
		}
	}
}

func TestFirstPeriod(t *testing.T) {
	terms := Terms{StartsOn: ymd("2024-03-01"), DueDay: 5}
	if got := FirstPeriod(terms, ymd("2026-10-15")); !got.Equal(ymd("2026-11-01")) {
		t.Fatalf("due day before the cutover: %s", got)
	}
	terms.DueDay = 20
	if got := FirstPeriod(terms, ymd("2026-10-15")); !got.Equal(ymd("2026-10-01")) {
		t.Fatalf("due day after the cutover: %s", got)
	}
	if got := FirstPeriod(terms, ymd("2026-10-20")); !got.Equal(ymd("2026-10-01")) {
		t.Fatalf("due on the cutover day: %s", got)
	}
	// A fixed term ending before the first tracked payment: only the opening balance.
	end := ymd("2026-10-31")
	items := ImportSchedule(Terms{StartsOn: ymd("2025-11-01"), EndsOn: &end, Rent: 100, DueDay: 1}, []Share{{PartyID: "a", ShareBps: 10000}},
		Cutover{On: ymd("2026-10-15"), DepositHeld: true, Opening: map[string]int64{"a": 100}})
	if len(items) != 1 || items[0].Kind != KindOpeningBalance {
		t.Fatalf("items %+v", items)
	}
}

// Every posting of an imported lease balances: shares of each kind and the
// held deposit.
func TestImportPostingsBalance(t *testing.T) {
	party := uuid.New()
	for _, kind := range []string{"rent", "deposit", KindOpeningBalance} {
		legs := receivableLegs(kind, party, 650_000)
		var sum int64
		for _, l := range legs {
			sum += l.amount
		}
		if sum != 0 || legs[0].account != "receivable" || *legs[0].party != party {
			t.Fatalf("%s: %+v", kind, legs)
		}
		want := "income"
		if kind == "deposit" {
			want = "deposit_held"
		}
		if legs[1].account != want {
			t.Fatalf("%s credits %s", kind, legs[1].account)
		}
	}
	legs := heldDepositLegs(3_600_000)
	if legs[0].account != "cash" || legs[1].account != "deposit_held" || legs[0].amount+legs[1].amount != 0 {
		t.Fatalf("held deposit %+v", legs)
	}
	for _, l := range legs {
		if l.account == "receivable" {
			t.Fatal("a held deposit is owed by nobody")
		}
	}
}

func TestVariableSymbolSelection(t *testing.T) {
	vs := "1203"
	l := db.Lease{Code: 2600000007, PayeeIban: "CZ6508000000192000145399", PayeeName: "Jana", Currency: "CZK"}
	if VariableSymbol(l) != "2600000007" {
		t.Fatalf("code: %s", VariableSymbol(l))
	}
	s := &Service{}
	if q := s.spayd(l, "rent", "2026-11", 1, 100, ymd("2026-11-05")); !strings.Contains(q, "X-VS:2600000007*") {
		t.Fatalf("spayd with the code: %s", q)
	}
	l.VariableSymbol = &vs
	if VariableSymbol(l) != "1203" {
		t.Fatalf("custom: %s", VariableSymbol(l))
	}
	q := s.spayd(l, KindOpeningBalance, "", 1, 650_000, ymd("2026-11-01"))
	if !strings.Contains(q, "X-VS:1203*") || strings.Contains(q, "2600000007") || !strings.Contains(q, "MSG:NEDOPLATEK") {
		t.Fatalf("spayd with the custom symbol: %s", q)
	}
	// Matching normalizes the transaction's symbol the same way.
	for in, want := range map[string]string{"1203": "1203", "0001203": "1203", " 12 03 ": "1203", "2600000007": "2600000007",
		"": "", "0": "", "12345678901": "", "12a": "", "-12": ""} {
		if got := NormalizeVS(in); got != want {
			t.Errorf("NormalizeVS(%q) = %q, want %q", in, got, want)
		}
	}
}

func importInput() ImportInput {
	return ImportInput{Lease: Input{Template: "byt_doba_neurcita", StartsOn: ymd("2024-03-01"), Rent: 1_800_000,
		Deposit: 3_600_000, DueDay: 5, PayeeIBAN: "CZ65 0800 0000 1920 0014 5399", PayeeName: "Jana Nováková",
		PropertyAddress: "Dejvická 12, Praha 6"},
		Parties: []ImportParty{{PartyInput: PartyInput{Name: "Petr Svoboda", Role: "tenant"}, OpeningBalance: 100}}}
}

func code(err error) string {
	var ae *apperr.Error
	if errors.As(err, &ae) {
		return ae.Code
	}
	if err != nil {
		return err.Error()
	}
	return ""
}

func TestValidateImport(t *testing.T) {
	today := ymd("2026-10-20")
	in := importInput()
	if err := ValidateImport(&in, 3, today); err != nil {
		t.Fatal(err)
	}
	if !in.CutoverOn.Equal(ymd("2026-11-01")) || in.Parties[0].ShareBps != 10000 || in.Lease.NoticeMonths != 3 ||
		in.Lease.PayeeIBAN != "CZ6508000000192000145399" {
		t.Fatalf("defaults %+v", in)
	}
	// A lease starting later: the cutover defaults to its start.
	in = importInput()
	in.Lease.StartsOn = ymd("2027-01-15")
	if err := ValidateImport(&in, 3, today); err != nil || !in.CutoverOn.Equal(ymd("2027-01-15")) {
		t.Fatalf("future start: %v %v", err, in.CutoverOn)
	}
	for name, c := range map[string]struct {
		mod  func(*ImportInput)
		want string
	}{
		"cutover a month back": {func(in *ImportInput) { c := ymd("2026-09-25"); in.CutoverOn = &c }, ""},
		"cutover too old":      {func(in *ImportInput) { c := ymd("2026-09-01"); in.CutoverOn = &c }, "cutover_too_old"},
		"cutover too far":      {func(in *ImportInput) { c := ymd("2027-11-01"); in.CutoverOn = &c }, "cutover_too_far"},
		"before start": {func(in *ImportInput) {
			in.Lease.StartsOn = ymd("2026-10-10")
			c := ymd("2026-10-01")
			in.CutoverOn = &c
		}, "cutover_before_start"},
		"ended": {func(in *ImportInput) {
			in.Lease.Template = "byt_doba_urcita"
			e := ymd("2026-09-30")
			in.Lease.EndsOn = &e
		}, "lease_ended"},
		"after end": {func(in *ImportInput) {
			in.Lease.Template = "byt_doba_urcita"
			e := ymd("2026-10-31")
			in.Lease.EndsOn = &e
		}, "cutover_after_end"},
		"symbol normalized": {func(in *ImportInput) { in.VariableSymbol = "001203" }, ""},
		"symbol invalid":    {func(in *ImportInput) { in.VariableSymbol = "12-03" }, "invalid_variable_symbol"},
		"e-mail optional":   {func(in *ImportInput) { in.Parties[0].Email = "" }, ""},
		"e-mail invalid":    {func(in *ImportInput) { in.Parties[0].Email = "petr at example" }, "invalid_email"},
		"negative balance":  {func(in *ImportInput) { in.Parties[0].OpeningBalance = -1 }, "invalid_opening_balance"},
		"no tenants":        {func(in *ImportInput) { in.Parties = nil }, "tenant_required"},
		"no address":        {func(in *ImportInput) { in.Lease.PropertyAddress = " " }, "address_required"},
		"deposit cap":       {func(in *ImportInput) { in.Lease.Deposit = 4 * in.Lease.Rent }, "deposit_too_high"},
		"guarantor owes": {func(in *ImportInput) {
			in.Parties = append(in.Parties, ImportParty{PartyInput: PartyInput{Name: "Ručitel", Role: "guarantor"}, OpeningBalance: 5})
		}, "opening_balance_guarantor"},
	} {
		in := importInput()
		c.mod(&in)
		if got := code(ValidateImport(&in, 3, today)); got != c.want {
			t.Errorf("%s: got %q, want %q", name, got, c.want)
		}
		if name == "symbol normalized" && in.VariableSymbol != "1203" {
			t.Errorf("symbol %q", in.VariableSymbol)
		}
	}
	// Validating twice (terractl validates, ImportBatch again) changes nothing.
	in = importInput()
	in.Parties = append(in.Parties, ImportParty{PartyInput: PartyInput{Name: "Eva", Role: "tenant"}})
	in.Lease.Template = "spolecny_najem"
	in.Parties[0].Role, in.Parties[1].Role = "co_tenant", "co_tenant"
	if err := ValidateImport(&in, 3, today); err != nil {
		t.Fatal(err)
	}
	first := *in.CutoverOn
	if err := ValidateImport(&in, 3, today); err != nil || !in.CutoverOn.Equal(first) || in.Parties[0].ShareBps+in.Parties[1].ShareBps != 10000 {
		t.Fatalf("second validation: %v %+v", err, in)
	}
}

// The sample in the docs stays valid.
func TestParseImportCSVExample(t *testing.T) {
	f, err := os.Open("../../../../docs/examples/existing-leases.csv")
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	leases, errs := ParseImportCSV(f, 3, ymd("2026-10-20"))
	if len(errs) > 0 {
		t.Fatalf("errors %v", errs)
	}
	if len(leases) != 2 {
		t.Fatalf("leases %+v", leases)
	}
	a, b := leases[0], leases[1]
	if a.Ref != "dejvicka-12" || a.Input.Lease.Rent != 1_800_000 || a.Input.Lease.Services != 350_000 || !a.Input.DepositHeld ||
		a.Input.VariableSymbol != "1203" || a.Input.Parties[0].Role != "tenant" || a.Input.Parties[0].ShareBps != 10000 ||
		!a.Input.CutoverOn.Equal(ymd("2026-11-01")) || a.Input.Lease.PayeeIBAN != "CZ6508000000192000145399" {
		t.Fatalf("first lease %+v", a)
	}
	if b.Ref != "vinohradska-40" || len(b.Input.Parties) != 2 || b.Input.Parties[0].Role != "co_tenant" ||
		b.Input.Parties[0].OpeningBalance != 650_000 || b.Input.Parties[1].Email != "tomas.velky@example.cz" ||
		b.Input.Parties[0].Email != "" || b.Input.Lease.EndsOn == nil || len(b.Lines) != 2 || b.Lines[1] != 4 {
		t.Fatalf("second lease %+v", b)
	}
}

func TestParseImportCSVReportsRows(t *testing.T) {
	header := strings.Join(ImportColumns, ";") + "\n"
	row := func(ref, starts, rent, vs, name, share, opening string) string {
		return strings.Join([]string{ref, "Dejvická 12, Praha 6", "", "", "", starts, "", rent, "", "", "ne", "5", "",
			"CZ6508000000192000145399", "Jana", vs, "", name, "", share, opening}, ";") + "\n"
	}
	in := "\ufeff" + header +
		row("a", "1.3.2024", "18 000", "", "Petr", "", "") + // line 2: fine (Czech date, spaces)
		row("b", "2024-13-01", "18000", "", "Eva", "", "") + // 3: bad date
		row("c", "2024-03-01", "abc", "", "Ota", "", "") + // 4: bad rent
		row("d", "2024-03-01", "18000", "", "Iva", "", "-5") + // 5: negative balance
		row("e", "2024-03-01", "18000", "77", "Jan", "", "") + // 6: fine
		row("f", "2024-03-01", "18000", "0077", "Lea", "", "") + // 7: same symbol as e
		row("g", "2024-03-01", "18000", "", "Ema", "", "") + // 8: fine
		row("g", "2024-03-01", "19000", "", "Bob", "", "") + // 9: contradicts line 8
		row("", "2024-03-01", "18000", "", "Bez", "", "") // 10: no lease_ref
	leases, errs := ParseImportCSV(strings.NewReader(in), 3, ymd("2026-10-20"))
	lines := map[int]bool{}
	for _, e := range errs {
		lines[e.Line] = true
	}
	for _, want := range []int{3, 4, 5, 7, 9, 10} {
		if !lines[want] {
			t.Errorf("no error on line %d: %v", want, errs)
		}
	}
	var dup bool
	for _, e := range errs {
		if e.Ref == "f" && strings.Contains(e.Err, "also used by lease") {
			dup = true
		}
	}
	if !dup {
		t.Errorf("duplicate symbol not reported: %v", errs)
	}
	if len(leases) != 2 || leases[0].Ref != "a" || leases[1].Ref != "e" || leases[0].Input.Lease.Rent != 1_800_000 ||
		!leases[0].Input.Lease.StartsOn.Equal(ymd("2024-03-01")) || leases[1].Input.VariableSymbol != "77" {
		t.Fatalf("valid leases %+v", leases)
	}
	if _, errs := ParseImportCSV(strings.NewReader("lease_ref,address\nx,y\n"), 3, ymd("2026-10-20")); len(errs) == 0 {
		t.Fatal("missing columns accepted")
	}
}
