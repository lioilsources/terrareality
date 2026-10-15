package leasing

import (
	"fmt"
	"math/big"
	"regexp"
	"strings"
	"unicode"
)

// NormalizeIBAN removes spaces and upper-cases.
func NormalizeIBAN(s string) string {
	var b strings.Builder
	for _, r := range strings.ToUpper(s) {
		if !unicode.IsSpace(r) {
			b.WriteRune(r)
		}
	}
	return b.String()
}

var reIBAN = regexp.MustCompile(`^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$`)

// ValidIBAN checks the format and the mod-97 checksum.
func ValidIBAN(iban string) bool {
	iban = NormalizeIBAN(iban)
	if !reIBAN.MatchString(iban) {
		return false
	}
	rearranged := iban[4:] + iban[:4]
	var digits strings.Builder
	for _, r := range rearranged {
		if r >= 'A' && r <= 'Z' {
			digits.WriteString(fmt.Sprint(int(r-'A') + 10))
		} else {
			digits.WriteRune(r)
		}
	}
	n, ok := new(big.Int).SetString(digits.String(), 10)
	return ok && new(big.Int).Mod(n, big.NewInt(97)).Int64() == 1
}

// FormatIBAN groups an IBAN by four characters.
func FormatIBAN(iban string) string {
	iban = NormalizeIBAN(iban)
	var parts []string
	for i := 0; i < len(iban); i += 4 {
		parts = append(parts, iban[i:min(i+4, len(iban))])
	}
	return strings.Join(parts, " ")
}

// Payment is a QR payment request.
type Payment struct {
	IBAN     string
	Amount   int64 // minor units
	Currency string
	VS       string // variable symbol
	SS       string // specific symbol
	Message  string
	Payee    string
	DueDate  string // YYYYMMDD
}

// spaydText keeps characters allowed in SPAYD values (no '*', ASCII-safe).
func spaydText(s string, max int) string {
	s = strings.ReplaceAll(s, "*", " ")
	r := []rune(strings.TrimSpace(s))
	if len(r) > max {
		r = r[:max]
	}
	return strings.ToUpper(string(r))
}

// SPAYD returns the Czech "Short Payment Descriptor" (QR Platba, SPD 1.0).
func SPAYD(p Payment) string {
	fields := []string{"SPD*1.0", "ACC:" + NormalizeIBAN(p.IBAN),
		fmt.Sprintf("AM:%d.%02d", p.Amount/100, p.Amount%100), "CC:" + p.Currency}
	if p.DueDate != "" {
		fields = append(fields, "DT:"+p.DueDate)
	}
	if p.Payee != "" {
		fields = append(fields, "RN:"+spaydText(p.Payee, 35))
	}
	if p.Message != "" {
		fields = append(fields, "MSG:"+spaydText(p.Message, 60))
	}
	if p.VS != "" {
		fields = append(fields, "X-VS:"+p.VS)
	}
	if p.SS != "" {
		fields = append(fields, "X-SS:"+p.SS)
	}
	return strings.Join(fields, "*")
}
