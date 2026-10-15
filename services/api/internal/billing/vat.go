package billing

import (
	"fmt"
	"strconv"
	"strings"
	"time"
)

// VATRateCZStandard is the Czech standard VAT rate in basis points (21 %).
const VATRateCZStandard = 2100

// ComputeVAT returns VAT and gross for a net amount in minor units and a rate
// in basis points, rounding the VAT half away from zero to whole minor units.
func ComputeVAT(net int64, rateBP int) (vat, gross int64) {
	p := net * int64(rateBP)
	if p >= 0 {
		vat = (p + 5000) / 10000
	} else {
		vat = -((-p + 5000) / 10000)
	}
	return vat, net + vat
}

// FormatInvoiceNumber formats the gapless yearly invoice number, e.g. TR-2026-000001.
func FormatInvoiceNumber(year, seq int) string {
	return fmt.Sprintf("TR-%04d-%06d", year, seq)
}

// FormatAmount formats minor units the Czech way: "1 234,50 Kč" (non-breaking
// spaces). Currencies other than CZK keep their ISO code.
func FormatAmount(minor int64, currency string) string {
	sign := ""
	if minor < 0 {
		sign, minor = "-", -minor
	}
	whole := strconv.FormatInt(minor/100, 10)
	var b strings.Builder
	for i, r := range whole {
		if i > 0 && (len(whole)-i)%3 == 0 {
			b.WriteRune(' ')
		}
		b.WriteRune(r)
	}
	sym := strings.ToUpper(currency)
	if sym == "CZK" {
		sym = "Kč"
	}
	return fmt.Sprintf("%s%s,%02d %s", sign, b.String(), minor%100, sym)
}

// FormatRate formats a rate in basis points, e.g. 2100 -> "21 %".
func FormatRate(bp int) string {
	s := strconv.Itoa(bp / 100)
	if r := bp % 100; r != 0 {
		s += "," + strings.TrimRight(fmt.Sprintf("%02d", r), "0")
	}
	return s + " %"
}

// FormatDate formats a date the Czech way, e.g. "15. 10. 2026".
func FormatDate(t time.Time) string {
	if t.IsZero() {
		return ""
	}
	return t.Format("2. 1. 2006")
}
