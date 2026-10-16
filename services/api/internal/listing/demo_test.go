package listing

import (
	"encoding/json"
	"math"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestGenerateDemoFactsDeterministicAndPlausible(t *testing.T) {
	today := time.Date(2026, 10, 16, 0, 0, 0, 0, time.UTC)
	for _, typ := range []string{"panel", "brick", "new"} {
		for layout, base := range demoBaseArea {
			f := DemoFlat{Flat: "flat-01", Type: typ, Layout: layout}
			a, b := GenerateDemoFacts(f, DefaultDemoSeed, today), GenerateDemoFacts(f, DefaultDemoSeed, today)
			if a.Rent != b.Rent || a.FloorArea != b.FloorArea || a.Floor != b.Floor || !a.AvailableFrom.Equal(b.AvailableFrom) {
				t.Fatalf("%s %s not deterministic: %+v %+v", typ, layout, a, b)
			}
			if a.FloorArea < base*0.89 || a.FloorArea > base*1.16 {
				t.Fatalf("%s area %v for base %v", layout, a.FloorArea, base)
			}
			perM2 := float64(a.Rent) / 100 / a.FloorArea
			if perM2 < 280 || perM2 > 520 {
				t.Fatalf("%s %s rent %d CZK for %v m² (%v/m²)", typ, layout, a.Rent/100, a.FloorArea, perM2)
			}
			if a.Rent%50_000 != 0 || a.Deposit != 2*a.Rent || a.Utilities <= 0 {
				t.Fatalf("money %+v", a)
			}
			if a.Floor < 1 || a.Floor > a.TotalFloors {
				t.Fatalf("floor %d of %d", a.Floor, a.TotalFloors)
			}
			if a.AvailableFrom.Day() != 1 || !a.AvailableFrom.After(today) {
				t.Fatalf("available from %v", a.AvailableFrom)
			}
			if a.Attributes["layout"] != layout || a.Attributes["floor_area"] != a.FloorArea {
				t.Fatalf("attributes %+v", a.Attributes)
			}
		}
	}
	// New buildings ask more per m² than panel ones on average.
	var panel, nb float64
	for i := range 20 {
		key := "flat-" + string(rune('a'+i))
		p := GenerateDemoFacts(DemoFlat{Flat: key, Type: "panel", Layout: "2+kk"}, "s", time.Now())
		n := GenerateDemoFacts(DemoFlat{Flat: key, Type: "new", Layout: "2+kk"}, "s", time.Now())
		panel += float64(p.Rent) / p.FloorArea
		nb += float64(n.Rent) / n.FloorArea
	}
	if nb <= panel || math.IsNaN(nb) {
		t.Fatalf("new %v <= panel %v", nb, panel)
	}
}

func TestDemoTextsAreLabelled(t *testing.T) {
	f := DemoFlat{Flat: "flat-03", Type: "new", Layout: "3+kk"}
	facts := GenerateDemoFacts(f, DefaultDemoSeed, time.Now())
	title, desc := DemoTexts(f, facts, "Praha 6 – Dejvice")
	if !strings.HasPrefix(title.CS, "Ukázka: ") || !strings.HasPrefix(title.EN, "Demo: ") || !strings.Contains(title.CS, "3+kk") {
		t.Fatalf("title %+v", title)
	}
	if !strings.HasPrefix(desc.CS, DemoDisclaimerCS) || !strings.HasPrefix(desc.EN, DemoDisclaimerEN) {
		t.Fatalf("description %+v", desc)
	}
	if len([]rune(desc.CS)) < 50 {
		t.Fatal("description shorter than Submit requires")
	}
}

func writeManifest(t *testing.T, flats []DemoFlat, photos bool) string {
	t.Helper()
	dir := t.TempDir()
	raw, _ := json.Marshal(flats)
	if err := os.WriteFile(filepath.Join(dir, "manifest.json"), raw, 0o600); err != nil {
		t.Fatal(err)
	}
	if photos {
		for _, f := range flats {
			_ = os.MkdirAll(filepath.Join(dir, f.Flat), 0o700)
			for _, r := range demoRooms {
				if err := os.WriteFile(filepath.Join(dir, f.Flat, r.File), []byte("jpeg"), 0o600); err != nil {
					t.Fatal(err)
				}
			}
		}
	}
	return dir
}

func TestLoadDemoManifest(t *testing.T) {
	ok := []DemoFlat{{Flat: "flat-01", Type: "panel", Layout: "2+kk"}, {Flat: "flat-02", Type: "brick", Layout: "1+1"}}
	flats, err := LoadDemoManifest(writeManifest(t, ok, true))
	if err != nil || len(flats) != 2 {
		t.Fatalf("valid manifest: %v %v", flats, err)
	}
	cases := map[string][]DemoFlat{
		"bad type":   {{Flat: "flat-01", Type: "wood", Layout: "2+kk"}},
		"bad layout": {{Flat: "flat-01", Type: "panel", Layout: "9+9"}},
		"bad name":   {{Flat: "../etc", Type: "panel", Layout: "2+kk"}},
		"duplicate":  {{Flat: "flat-01", Type: "panel", Layout: "2+kk"}, {Flat: "flat-01", Type: "new", Layout: "2+kk"}},
		"empty":      {},
	}
	for name, fl := range cases {
		if _, err := LoadDemoManifest(writeManifest(t, fl, true)); err == nil {
			t.Errorf("%s: accepted", name)
		}
	}
	if _, err := LoadDemoManifest(writeManifest(t, ok, false)); err == nil {
		t.Error("missing photos accepted")
	}
	if _, err := LoadDemoManifest(t.TempDir()); err == nil {
		t.Error("missing manifest accepted")
	}
}
