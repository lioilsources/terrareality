package portfolio

import (
	"bytes"
	"encoding/csv"
	"testing"
)

func TestCSVSafe(t *testing.T) {
	for in, want := range map[string]string{"=HYPERLINK(\"x\")": "'=HYPERLINK(\"x\")", "+420": "'+420", "-1": "'-1",
		"@SUM(A1)": "'@SUM(A1)", "\tx": "'\tx", "\rx": "'\rx", "Dejvická 12": "Dejvická 12", "": ""} {
		if got := CSVSafe(in); got != want {
			t.Fatalf("CSVSafe(%q) = %q, want %q", in, got, want)
		}
	}
}

// User-supplied texts (tenant names, addresses) cannot become formulas in the
// rent roll CSV; amounts the platform writes stay numbers (also negative).
func TestRentRollCSVNeutralizesFormulas(t *testing.T) {
	rows := []Row{{Kind: "lease", Code: 7, Municipality: "Praha", Address: "=cmd|' /C calc'!A0", Unit: "+1",
		Tenants: "@Anna", Rent: 2_000_000, Debt: -5_000, Currency: "CZK"}}
	recs, err := csv.NewReader(bytes.NewReader(RentRollCSV(rows, nil))).ReadAll()
	if err != nil || len(recs) != 2 {
		t.Fatalf("csv %v %d", err, len(recs))
	}
	r := recs[1]
	if r[3] != "'=cmd|' /C calc'!A0" || r[4] != "'+1" || r[7] != "'@Anna" || r[1] != "Praha" {
		t.Fatalf("texts %q", r)
	}
	if r[8] != "20000.00" || r[19] != "-50.00" {
		t.Fatalf("amounts %q %q", r[8], r[19])
	}
}
