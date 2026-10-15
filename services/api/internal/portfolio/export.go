package portfolio

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"strings"
	"time"

	"github.com/xuri/excelize/v2"
)

// exportColumns of the rent roll (CSV and XLSX share them).
var exportColumns = []string{"kind", "municipality", "region", "address", "unit", "lease_code", "state", "tenants",
	"rent", "services", "currency", "due_day", "starts_on", "ends_on", "notice_on", "deposit", "deposit_paid",
	"billed", "paid", "debt", "risk_score", "risk_band", "groups", "asking_rent"}

func amount(minor int64) string {
	sign := ""
	if minor < 0 {
		sign, minor = "-", -minor
	}
	return fmt.Sprintf("%s%d.%02d", sign, minor/100, minor%100)
}

// CSVSafe neutralizes a user-supplied CSV cell that a spreadsheet would read
// as a formula (= + - @, tab, carriage return): it is prefixed with an
// apostrophe. Amounts and dates written by the platform are not passed here.
func CSVSafe(v string) string {
	if v != "" && strings.ContainsRune("=+-@\t\r", rune(v[0])) {
		return "'" + v
	}
	return v
}

func day(t *time.Time) string {
	if t == nil {
		return ""
	}
	return t.Format("2006-01-02")
}

func (r Row) record(groupNames map[string]string) []string {
	code, due, score := "", "", ""
	if r.Code != 0 {
		code = fmt.Sprint(r.Code)
	}
	if r.DueDay != 0 {
		due = fmt.Sprint(r.DueDay)
	}
	if r.RiskScore != nil {
		score = fmt.Sprint(*r.RiskScore)
	}
	var groups []string
	for _, g := range r.Groups {
		if n, ok := groupNames[g.String()]; ok {
			groups = append(groups, n)
		}
	}
	money := func(v int64) string {
		if r.Kind == "vacant" {
			return ""
		}
		return amount(v)
	}
	asking := ""
	if r.AskingRent > 0 {
		asking = amount(r.AskingRent)
	}
	return []string{r.Kind, r.Municipality, r.Region, r.Address, r.Unit, code, r.State, r.Tenants,
		money(r.Rent), money(r.Services), r.Currency, due, day(r.StartsOn), day(r.EndsOn), day(r.NoticeOn),
		money(r.Deposit), money(r.DepositPaid), money(r.Billed), money(r.Paid), money(r.Debt), score, r.RiskBand,
		strings.Join(groups, "|"), asking}
}

// csvTextColumns are the user-supplied text columns of the rent roll.
var csvTextColumns = []int{1, 2, 3, 4, 7, 22}

// RentRollCSV exports the rent roll. Amounts are decimal major units; billed,
// paid and debt come from the leases' ledgers as of today.
func RentRollCSV(rows []Row, groupNames map[string]string) []byte {
	var b bytes.Buffer
	w := csv.NewWriter(&b)
	_ = w.Write(exportColumns)
	for _, r := range rows {
		rec := r.record(groupNames)
		for _, i := range csvTextColumns {
			rec[i] = CSVSafe(rec[i])
		}
		_ = w.Write(rec)
	}
	w.Flush()
	return b.Bytes()
}

// RentRollXLSX exports the rent roll as a spreadsheet (amounts as numbers).
func RentRollXLSX(rows []Row, groupNames map[string]string) ([]byte, error) {
	f := excelize.NewFile()
	defer f.Close()
	const sheet = "Rent roll"
	if err := f.SetSheetName("Sheet1", sheet); err != nil {
		return nil, err
	}
	money := map[int]bool{8: true, 9: true, 15: true, 16: true, 17: true, 18: true, 19: true, 23: true}
	numFmt := "#,##0.00"
	style, err := f.NewStyle(&excelize.Style{CustomNumFmt: &numFmt})
	if err != nil {
		return nil, err
	}
	bold, err := f.NewStyle(&excelize.Style{Font: &excelize.Font{Bold: true}})
	if err != nil {
		return nil, err
	}
	for i, c := range exportColumns {
		cell, _ := excelize.CoordinatesToCellName(i+1, 1)
		_ = f.SetCellValue(sheet, cell, c)
		_ = f.SetCellStyle(sheet, cell, cell, bold)
	}
	for ri, r := range rows {
		rec := r.record(groupNames)
		for ci, v := range rec {
			cell, _ := excelize.CoordinatesToCellName(ci+1, ri+2)
			var val any = v
			if money[ci] && v != "" {
				var x float64
				if _, err := fmt.Sscan(v, &x); err == nil {
					val = x
					_ = f.SetCellStyle(sheet, cell, cell, style)
				}
			} else if (ci == 5 || ci == 11 || ci == 20) && v != "" {
				var n int64
				if _, err := fmt.Sscan(v, &n); err == nil {
					val = n
				}
			}
			if err := f.SetCellValue(sheet, cell, val); err != nil {
				return nil, err
			}
		}
	}
	_ = f.SetPanes(sheet, &excelize.Panes{Freeze: true, YSplit: 1, TopLeftCell: "A2", ActivePane: "bottomLeft"})
	buf, err := f.WriteToBuffer()
	if err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}
