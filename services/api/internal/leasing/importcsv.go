package leasing

import (
	"encoding/csv"
	"fmt"
	"io"
	"math/big"
	"slices"
	"strconv"
	"strings"
	"time"
)

// ImportColumns are the columns of the existing-leases CSV (terractl leases
// import, docs/examples/existing-leases.csv). One row per tenant party; rows
// with the same lease_ref form one lease. Lease columns are read from the
// first row of a lease; later rows may leave them empty but must not
// contradict it. Amounts are in whole CZK (a decimal part is allowed).
var ImportColumns = []string{"lease_ref", "address", "ruian_id", "unit_label", "template", "starts_on", "ends_on",
	"rent", "services", "deposit", "deposit_held", "due_day", "notice_months", "payee_iban", "payee_name",
	"variable_symbol", "cutover_on", "tenant_name", "tenant_email", "share_pct", "opening_balance"}

// leaseColumns are the per-lease columns (the rest describe the party).
var leaseColumns = ImportColumns[1:17]

// ParsedLease is one lease of the CSV.
type ParsedLease struct {
	Ref   string
	Lines []int // CSV lines of its parties (the header is line 1)
	Input ImportInput
}

// RowError is a problem with a CSV line (Line 0: the whole file, or a lease
// spanning Lines).
type RowError struct {
	Line int
	Ref  string
	Err  string
}

func (e RowError) String() string {
	switch {
	case e.Line > 0 && e.Ref != "":
		return fmt.Sprintf("line %d (lease %s): %s", e.Line, e.Ref, e.Err)
	case e.Line > 0:
		return fmt.Sprintf("line %d: %s", e.Line, e.Err)
	case e.Ref != "":
		return fmt.Sprintf("lease %s: %s", e.Ref, e.Err)
	}
	return e.Err
}

// ParseImportCSV reads the existing-leases CSV (comma or semicolon
// separated, a UTF-8 BOM is ignored) and checks every lease with
// ValidateImport against today and the deposit cap. It returns the leases
// and every problem found; leases are usable only when there is none.
func ParseImportCSV(r io.Reader, depositMaxMonths int32, today time.Time) ([]ParsedLease, []RowError) {
	raw, err := io.ReadAll(r)
	if err != nil {
		return nil, []RowError{{Err: err.Error()}}
	}
	text := strings.TrimPrefix(string(raw), "\ufeff")
	cr := csv.NewReader(strings.NewReader(text))
	if first, _, _ := strings.Cut(text, "\n"); strings.Count(first, ";") > strings.Count(first, ",") {
		cr.Comma = ';'
	}
	cr.FieldsPerRecord = -1
	cr.TrimLeadingSpace = true
	header, err := cr.Read()
	if err != nil {
		return nil, []RowError{{Line: 1, Err: "read header: " + err.Error()}}
	}
	col := map[string]int{}
	for i, h := range header {
		col[strings.ToLower(strings.TrimSpace(h))] = i
	}
	var errs []RowError
	for _, need := range ImportColumns {
		if _, ok := col[need]; !ok {
			errs = append(errs, RowError{Line: 1, Err: fmt.Sprintf("missing column %q", need)})
		}
	}
	if len(errs) > 0 {
		return nil, errs
	}
	type lease struct {
		ParsedLease
		first map[string]string // lease columns of the first row
		line  int
	}
	var order []string
	byRef := map[string]*lease{}
	bad := map[string]bool{} // leases with a row error: not validated as a whole
	line := 1
	for {
		rec, err := cr.Read()
		if err == io.EOF {
			break
		}
		line++
		if err != nil {
			errs = append(errs, RowError{Line: line, Err: err.Error()})
			continue
		}
		if len(rec) == 1 && strings.TrimSpace(rec[0]) == "" || strings.HasPrefix(strings.TrimSpace(rec[0]), "#") {
			continue
		}
		get := func(name string) string {
			if i := col[name]; i < len(rec) {
				return strings.TrimSpace(rec[i])
			}
			return ""
		}
		ref := get("lease_ref")
		fail := func(format string, a ...any) {
			errs = append(errs, RowError{Line: line, Ref: ref, Err: fmt.Sprintf(format, a...)})
			bad[ref] = true
		}
		if ref == "" {
			errs = append(errs, RowError{Line: line, Err: "lease_ref is required"})
			continue
		}
		l, seen := byRef[ref]
		if !seen {
			l = &lease{ParsedLease: ParsedLease{Ref: ref}, first: map[string]string{}, line: line}
			for _, c := range leaseColumns {
				l.first[c] = get(c)
			}
			byRef[ref] = l
			order = append(order, ref)
			if err := parseLeaseColumns(&l.Input, l.first); err != nil {
				fail("%v", err)
			}
		} else {
			for _, c := range leaseColumns {
				if v := get(c); v != "" && v != l.first[c] {
					fail("%s %q differs from line %d (%q)", c, v, l.line, l.first[c])
				}
			}
		}
		l.Lines = append(l.Lines, line)
		p := ImportParty{PartyInput: PartyInput{Name: get("tenant_name"), Email: get("tenant_email")}}
		if p.Name == "" {
			fail("tenant_name is required")
		}
		if v := get("share_pct"); v != "" {
			bps, err := parseHundredths(v)
			if err != nil || bps < 0 || bps > 10000 {
				fail("share_pct %q is not a percentage", v)
			}
			p.ShareBps = int(bps)
		}
		if v := get("opening_balance"); v != "" {
			amount, err := parseHundredths(v)
			if err != nil || amount < 0 {
				fail("opening_balance %q is not an amount in CZK", v)
			}
			p.OpeningBalance = amount
		}
		l.Input.Parties = append(l.Input.Parties, p)
	}
	var out []ParsedLease
	symbols := map[string]string{} // variable symbol -> lease ref
	for _, ref := range order {
		l := byRef[ref]
		// Roles: one tenant, or co-tenants of a joint tenancy.
		role := "tenant"
		if len(l.Input.Parties) > 1 || l.Input.Lease.Template == "spolecny_najem" {
			role = "co_tenant"
		}
		for i := range l.Input.Parties {
			l.Input.Parties[i].Role = role
		}
		if bad[ref] {
			continue
		}
		if err := ValidateImport(&l.Input, depositMaxMonths, today); err != nil {
			errs = append(errs, RowError{Line: l.line, Ref: ref, Err: err.Error()})
			continue
		}
		if vs := l.Input.VariableSymbol; vs != "" {
			if other, dup := symbols[vs]; dup {
				errs = append(errs, RowError{Line: l.line, Ref: ref, Err: "variable symbol " + vs + " is also used by lease " + other})
				continue
			}
			symbols[vs] = ref
		}
		out = append(out, l.ParsedLease)
	}
	if len(out) == 0 && len(errs) == 0 {
		errs = append(errs, RowError{Err: "no leases in the file"})
	}
	return out, errs
}

// parseLeaseColumns fills the lease part of an import from a CSV row.
func parseLeaseColumns(in *ImportInput, c map[string]string) error {
	l := &in.Lease
	l.PropertyAddress, l.UnitLabel, l.Template = c["address"], c["unit_label"], c["template"]
	l.PayeeIBAN, l.PayeeName = c["payee_iban"], c["payee_name"]
	in.VariableSymbol = c["variable_symbol"]
	var err error
	if v := c["ruian_id"]; v != "" {
		id, err := strconv.ParseInt(v, 10, 64)
		if err != nil || id <= 0 {
			return fmt.Errorf("ruian_id %q is not a RÚIAN address code", v)
		}
		l.RuianID = &id
	}
	if l.StartsOn, err = parseDay(c["starts_on"]); err != nil {
		return fmt.Errorf("starts_on: %w", err)
	}
	if v := c["ends_on"]; v != "" {
		t, err := parseDay(v)
		if err != nil {
			return fmt.Errorf("ends_on: %w", err)
		}
		l.EndsOn = &t
	}
	if v := c["cutover_on"]; v != "" {
		t, err := parseDay(v)
		if err != nil {
			return fmt.Errorf("cutover_on: %w", err)
		}
		in.CutoverOn = &t
	}
	if l.Template == "" { // by the term
		l.Template = "byt_doba_neurcita"
		if l.EndsOn != nil {
			l.Template = "byt_doba_urcita"
		}
	}
	if !slices.Contains(Templates, l.Template) {
		return fmt.Errorf("template %q is not one of %s", l.Template, strings.Join(Templates, ", "))
	}
	for _, a := range []struct {
		name     string
		to       *int64
		required bool
	}{{"rent", &l.Rent, true}, {"services", &l.Services, false}, {"deposit", &l.Deposit, false}} {
		v := c[a.name]
		if v == "" {
			if a.required {
				return fmt.Errorf("%s is required", a.name)
			}
			continue
		}
		amount, err := parseHundredths(v)
		if err != nil || amount < 0 {
			return fmt.Errorf("%s %q is not an amount in CZK", a.name, v)
		}
		*a.to = amount
	}
	switch strings.ToLower(c["deposit_held"]) {
	case "", "0", "false", "no", "ne", "n":
	case "1", "true", "yes", "ano", "y", "a":
		in.DepositHeld = true
	default:
		return fmt.Errorf("deposit_held %q is not yes or no", c["deposit_held"])
	}
	l.DueDay = 15
	for _, a := range []struct {
		name string
		to   *int32
	}{{"due_day", &l.DueDay}, {"notice_months", &l.NoticeMonths}} {
		if v := c[a.name]; v != "" {
			n, err := strconv.Atoi(v)
			if err != nil {
				return fmt.Errorf("%s %q is not a number", a.name, v)
			}
			*a.to = int32(n)
		}
	}
	return nil
}

// parseDay reads 2024-03-01 or the Czech 1.3.2024 / 1. 3. 2024.
func parseDay(s string) (time.Time, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return time.Time{}, fmt.Errorf("a date is required")
	}
	for _, layout := range []string{"2006-01-02", "2.1.2006"} {
		if t, err := time.Parse(layout, strings.ReplaceAll(s, " ", "")); err == nil {
			return t, nil
		}
	}
	return time.Time{}, fmt.Errorf("%q is not a date (YYYY-MM-DD or D.M.YYYY)", s)
}

// parseHundredths reads a decimal number with at most two decimals (comma
// or point; spaces as thousands separators) as hundredths: CZK to haléře,
// percent to basis points.
func parseHundredths(s string) (int64, error) {
	s = strings.NewReplacer(" ", "", "\u00a0", "", ",", ".").Replace(strings.TrimSpace(s))
	if s == "" {
		return 0, fmt.Errorf("empty")
	}
	r, ok := new(big.Rat).SetString(s)
	if !ok || strings.ContainsAny(s, "/eE") {
		return 0, fmt.Errorf("not a number")
	}
	r.Mul(r, big.NewRat(100, 1))
	if !r.IsInt() || !r.Num().IsInt64() {
		return 0, fmt.Errorf("at most two decimals")
	}
	return r.Num().Int64(), nil
}
