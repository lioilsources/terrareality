package ruian

import (
	"bytes"
	"encoding/csv"
	"testing"
	"time"
)

func TestFileMunicipalityCode(t *testing.T) {
	for name, want := range map[string]int32{
		"20260930_OB_554782_ADR.csv":     554782,
		"CSV/20260930_OB_538728_ADR.csv": 538728,
		"20260930_ob_532053_adr.CSV":     532053,
	} {
		got, ok := FileMunicipalityCode(name)
		if !ok || got != want {
			t.Errorf("%s: got %d %v, want %d", name, got, ok, want)
		}
	}
	if _, ok := FileMunicipalityCode("adresy.csv"); ok {
		t.Error("plain file name must not yield a code")
	}
}

func TestPrahaRegionCounter(t *testing.T) {
	c := NewCounter(Regions["praha"])
	if !c.Keep(554782) || c.Keep(582786) {
		t.Fatal("Praha kept, Brno rejected")
	}
	if c.Rows(554782) != 1 || c.Rows(582786) != 0 {
		t.Fatal("rows counted only for kept municipalities")
	}
	missing := c.Missing()
	if len(missing) != len(Regions["praha"].Municipalities)-1 {
		t.Fatalf("missing = %v", missing)
	}
}

// The embedded Praha sample parses completely and stays inside the region.
func TestPrahaSampleParses(t *testing.T) {
	r := Regions["praha"]
	cr := csv.NewReader(bytes.NewReader(r.Sample))
	cr.Comma = ';'
	header, err := cr.Read()
	if err != nil {
		t.Fatal(err)
	}
	idx := map[string]int{}
	for i, h := range header {
		if f, ok := columns[h]; ok {
			idx[f] = i
		}
	}
	districts := map[string]bool{}
	c := NewCounter(r)
	n := 0
	for {
		rec, err := cr.Read()
		if err != nil {
			break
		}
		row, ok := parseRow(rec, idx)
		if !ok {
			t.Fatalf("row %v does not parse", rec)
		}
		if !c.Keep(row.MunicipalityCode) {
			t.Fatalf("row outside the region: %d", row.MunicipalityCode)
		}
		if row.ID < 98000000 || row.ID >= 99000000 {
			t.Fatalf("id %d collides with the dev sample range", row.ID)
		}
		if row.District != nil {
			districts[*row.District] = true
		}
		n++
	}
	if len(districts) != 22 {
		t.Errorf("districts = %d, want Praha 1-22", len(districts))
	}
	if m := c.Missing(); len(m) != 0 {
		t.Errorf("sample misses municipalities %v", m)
	}
	if n == 0 {
		t.Fatal("empty sample")
	}
}

func TestDefaultExportDate(t *testing.T) {
	if got := DefaultExportDate(time.Date(2026, 10, 15, 0, 0, 0, 0, time.UTC)); got != "20260930" {
		t.Fatalf("got %s", got)
	}
}
