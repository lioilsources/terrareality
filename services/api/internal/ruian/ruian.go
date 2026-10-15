// Package ruian imports address points from the Czech address register
// (RÚIAN, open data of ČÚZK: "Adresní místa" CSV, one file per municipality,
// semicolon separated, windows-1250) and powers address autocomplete.
package ruian

import (
	"archive/zip"
	"bufio"
	"bytes"
	"context"
	_ "embed"
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/text/encoding/charmap"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

// Sample is a small synthetic Prague/Brno/Ostrava data set (realistic format and
// coordinates, not official codes) so autocomplete works offline in dev.
//
//go:embed testdata/sample.csv
var Sample []byte

const batchSize = 5000

// columns maps the CSV header names to staging fields.
var columns = map[string]string{
	"Kód ADM": "id", "Kód obce": "municipality_code", "Název obce": "municipality", "Název MOMC": "district",
	"Název části obce": "city_part", "Název ulice": "street", "Typ SO": "type", "Číslo domovní": "house_number",
	"Číslo orientační": "orientation_number", "Znak čísla orientačního": "orientation_letter", "PSČ": "postal_code",
	"Souřadnice Y": "y", "Souřadnice X": "x",
}

// Keep decides whether rows of a municipality (RÚIAN "Kód obce") are imported.
// A nil Keep imports everything.
type Keep func(municipalityCode int32) bool

// ImportFile imports a CSV file or a ZIP archive of CSV files.
func ImportFile(ctx context.Context, pool *pgxpool.Pool, path string) (int64, error) {
	return ImportFileFiltered(ctx, pool, path, nil)
}

// ImportFileFiltered imports a CSV file or a ZIP archive of CSV files, keeping
// only rows accepted by keep. ZIP entries named like the official per-municipality
// export ("20260930_OB_554782_ADR.csv") are skipped without reading when keep
// rejects their code.
func ImportFileFiltered(ctx context.Context, pool *pgxpool.Pool, path string, keep Keep) (int64, error) {
	if strings.EqualFold(filepath.Ext(path), ".zip") {
		zr, err := zip.OpenReader(path)
		if err != nil {
			return 0, err
		}
		defer zr.Close()
		var total int64
		for _, f := range zr.File {
			if !strings.EqualFold(filepath.Ext(f.Name), ".csv") {
				continue
			}
			if code, ok := FileMunicipalityCode(f.Name); ok && keep != nil && !keep(code) {
				continue
			}
			rc, err := f.Open()
			if err != nil {
				return total, err
			}
			n, err := ImportFiltered(ctx, pool, rc, keep)
			rc.Close()
			total += n
			if err != nil {
				return total, fmt.Errorf("%s: %w", f.Name, err)
			}
		}
		return total, nil
	}
	f, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	defer f.Close()
	return ImportFiltered(ctx, pool, f, keep)
}

// Import reads one CSV (UTF-8 or windows-1250) and upserts its address points.
func Import(ctx context.Context, pool *pgxpool.Pool, r io.Reader) (int64, error) {
	return ImportFiltered(ctx, pool, r, nil)
}

// ImportFiltered is Import restricted to the municipalities accepted by keep.
func ImportFiltered(ctx context.Context, pool *pgxpool.Pool, r io.Reader, keep Keep) (int64, error) {
	br := bufio.NewReader(r)
	head, _ := br.Peek(4096)
	var src io.Reader = br
	if !utf8.Valid(bytes.TrimPrefix(head, []byte("\xef\xbb\xbf"))) {
		src = charmap.Windows1250.NewDecoder().Reader(br)
	}
	cr := csv.NewReader(src)
	cr.Comma = ';'
	cr.FieldsPerRecord = -1
	header, err := cr.Read()
	if err != nil {
		return 0, fmt.Errorf("read header: %w", err)
	}
	idx := map[string]int{}
	for i, h := range header {
		if f, ok := columns[strings.TrimSpace(strings.TrimPrefix(h, "\ufeff"))]; ok {
			idx[f] = i
		}
	}
	for _, need := range []string{"id", "municipality_code", "municipality", "house_number", "postal_code", "y", "x"} {
		if _, ok := idx[need]; !ok {
			return 0, fmt.Errorf("missing column for %s", need)
		}
	}
	var total int64
	var batch []db.CopyRuianStagingParams
	flush := func() error {
		if len(batch) == 0 {
			return nil
		}
		n, err := mergeBatch(ctx, pool, batch)
		total += n
		batch = batch[:0]
		return err
	}
	for {
		rec, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return total, err
		}
		row, ok := parseRow(rec, idx)
		if !ok || (keep != nil && !keep(row.MunicipalityCode)) {
			continue
		}
		batch = append(batch, row)
		if len(batch) >= batchSize {
			if err := flush(); err != nil {
				return total, err
			}
		}
	}
	return total, flush()
}

func parseRow(rec []string, idx map[string]int) (db.CopyRuianStagingParams, bool) {
	get := func(f string) string {
		i, ok := idx[f]
		if !ok || i >= len(rec) {
			return ""
		}
		return strings.TrimSpace(rec[i])
	}
	opt := func(f string) *string {
		if v := get(f); v != "" {
			return &v
		}
		return nil
	}
	id, err1 := strconv.ParseInt(get("id"), 10, 64)
	mc, err2 := strconv.Atoi(get("municipality_code"))
	hn, err3 := strconv.Atoi(get("house_number"))
	y, err4 := strconv.ParseFloat(strings.ReplaceAll(get("y"), ",", "."), 64)
	x, err5 := strconv.ParseFloat(strings.ReplaceAll(get("x"), ",", "."), 64)
	if err1 != nil || err2 != nil || err3 != nil || err4 != nil || err5 != nil || y == 0 || x == 0 {
		return db.CopyRuianStagingParams{}, false
	}
	p := db.CopyRuianStagingParams{ID: id, MunicipalityCode: int32(mc), Municipality: get("municipality"),
		District: opt("district"), CityPart: opt("city_part"), Street: opt("street"), HouseNumber: int32(hn),
		HouseNumberType: "cp", OrientationLetter: opt("orientation_letter"), PostalCode: get("postal_code"),
		SjtskY: y, SjtskX: x}
	if strings.Contains(get("type"), "ev") {
		p.HouseNumberType = "ce"
	}
	if on, err := strconv.Atoi(get("orientation_number")); err == nil {
		v := int32(on)
		p.OrientationNumber = &v
	}
	return p, true
}

func mergeBatch(ctx context.Context, pool *pgxpool.Pool, rows []db.CopyRuianStagingParams) (int64, error) {
	var n int64
	err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		if err := q.TruncateRuianStaging(ctx); err != nil {
			return err
		}
		if _, err := q.CopyRuianStaging(ctx, rows); err != nil {
			return err
		}
		var err error
		n, err = q.MergeRuianStaging(ctx)
		if err != nil {
			return err
		}
		return q.TruncateRuianStaging(ctx)
	})
	return n, err
}

// SeedSample loads the embedded sample when some of its rows are missing (dev/test).
func SeedSample(ctx context.Context, pool *pgxpool.Pool) (int64, error) {
	n, err := db.New(pool).CountRuianSamplePlaces(ctx)
	if err != nil || n >= int64(bytes.Count(Sample, []byte("\n"))-1) {
		return 0, err
	}
	return Import(ctx, pool, bytes.NewReader(Sample))
}
