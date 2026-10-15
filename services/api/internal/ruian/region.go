package ruian

import (
	"bytes"
	"context"
	_ "embed"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// PrahaSample is a synthetic offline sample for the Praha launch region: two
// address points in each of Praha 1–22 and in the surrounding municipalities
// (realistic format, approximate S-JTSK coordinates, ids 98000001+).
//
//go:embed testdata/praha.csv
var PrahaSample []byte

// OfficialAddressesURL is the ČÚZK open-data download of all address points
// ("Adresní místa", CSV, one file per municipality, windows-1250). The date in
// the file name is the last day of the previous month; see docs/runbooks/seed-praha.md.
const OfficialAddressesURL = "https://vdp.cuzk.cz/vymenny_format/csv/%s_OB_ADR_csv.zip"

// Region is a launch region: the municipalities whose addresses are imported.
type Region struct {
	Name           string
	Municipalities map[int32]string // RÚIAN municipality code -> name
	Sample         []byte
}

// Regions known to `terractl import-ruian --region`.
var Regions = map[string]Region{
	"praha": {
		Name: "Praha a okolí",
		// Codes from the RÚIAN register of municipalities (číselník obcí); verify
		// after the first real import: `terractl import-ruian` lists codes with no rows.
		Municipalities: map[int32]string{
			554782: "Praha",
			538728: "Říčany",
			538094: "Brandýs nad Labem-Stará Boleslav",
			538931: "Úvaly",
			538086: "Čelákovice",
			539325: "Jesenice",
			539139: "Černošice",
			539694: "Roztoky",
			539210: "Hostivice",
			539627: "Rudná",
			531057: "Beroun",
			532053: "Kladno",
			534676: "Mělník",
		},
		Sample: PrahaSample,
	},
}

// Counter is a Keep for a region that also counts rows per municipality.
type Counter struct {
	region Region
	mu     sync.Mutex
	rows   map[int32]int
}

// NewCounter returns a filter for region r.
func NewCounter(r Region) *Counter { return &Counter{region: r, rows: map[int32]int{}} }

// Keep implements the import filter.
func (c *Counter) Keep(code int32) bool {
	if _, ok := c.region.Municipalities[code]; !ok {
		return false
	}
	c.mu.Lock()
	c.rows[code]++
	c.mu.Unlock()
	return true
}

// Missing lists the region's municipalities that had no rows, sorted by name.
func (c *Counter) Missing() []string {
	c.mu.Lock()
	defer c.mu.Unlock()
	var out []string
	for code, name := range c.region.Municipalities {
		if c.rows[code] == 0 {
			out = append(out, fmt.Sprintf("%s (%d)", name, code))
		}
	}
	sort.Strings(out)
	return out
}

// Rows returns the number of rows seen for a municipality.
func (c *Counter) Rows(code int32) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.rows[code]
}

var fileCode = regexp.MustCompile(`(?i)_OB_(\d+)_ADR\.csv$`)

// FileMunicipalityCode extracts the municipality code from an official export
// file name such as "20260930_OB_554782_ADR.csv".
func FileMunicipalityCode(name string) (int32, bool) {
	m := fileCode.FindStringSubmatch(filepath.Base(name))
	if m == nil {
		return 0, false
	}
	n, err := strconv.ParseInt(m[1], 10, 32)
	return int32(n), err == nil
}

// ImportRegionSample imports the embedded offline sample of a region.
func ImportRegionSample(ctx context.Context, pool *pgxpool.Pool, r Region, keep Keep) (int64, error) {
	return ImportFiltered(ctx, pool, bytes.NewReader(r.Sample), keep)
}

// DefaultExportDate is the date stamp of the latest monthly export (last day of
// the previous month).
func DefaultExportDate(now time.Time) string {
	first := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	return first.AddDate(0, 0, -1).Format("20060102")
}

// Download fetches url into a temporary file and returns its path; the caller removes it.
func Download(ctx context.Context, client *http.Client, url string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}
	res, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return "", fmt.Errorf("download %s: %s", url, res.Status)
	}
	f, err := os.CreateTemp("", "ruian-*"+filepath.Ext(url))
	if err != nil {
		return "", err
	}
	if _, err := io.Copy(f, res.Body); err != nil {
		f.Close()
		os.Remove(f.Name())
		return "", err
	}
	return f.Name(), f.Close()
}
