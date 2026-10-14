// Package textscan finds contact details and scam patterns in chat messages.
// Contact details are masked and the sender is warned; nothing is blocked.
// The advance-payment pattern raises a moderation flag (plan M4).
package textscan

import (
	"regexp"
	"strings"
	"unicode"

	"golang.org/x/text/runes"
	"golang.org/x/text/transform"
	"golang.org/x/text/unicode/norm"
)

// Flags attached to a message.
const (
	Phone          = "contact_phone"
	Email          = "contact_email"
	BankAccount    = "contact_bank_account"
	AdvancePayment = "advance_payment"
)

// Mask replaces a hidden detail.
const Mask = "[•••]"

var (
	reEmail = regexp.MustCompile(`(?i)[a-z0-9._%+\-]+\s*(?:@|\(at\)|\[at\]|\s(?:at|zavinac|zavináč)\s)\s*[a-z0-9\-]+(?:\s*(?:\.|\(dot\)|\stecka\s|\stečka\s)\s*[a-z0-9\-]+)*\s*(?:\.|\(dot\)|\stecka\s|\stečka\s)\s*[a-z]{2,}`)
	// IBAN (CZ, SK, PL, HU and others): country, check digits, 11-30 alphanumerics in groups.
	reIBAN = regexp.MustCompile(`(?i)\b[a-z]{2}\d{2}(?:[ ]?[a-z0-9]){11,30}\b`)
	// Czech/Slovak domestic account: [prefix-]number/bank code.
	reAccount = regexp.MustCompile(`\b(?:\d{1,6}-)?\d{2,10}\s?/\s?\d{4}\b`)
	// Phone: optional +/00 country code, then 9-12 digits with separators.
	rePhone = regexp.MustCompile(`(?:\+|\b00)?\d(?:[\s.\-/]?\d){8,12}\b`)
)

// fold lowercases and removes diacritics.
func fold(s string) string {
	t := transform.Chain(norm.NFD, runes.Remove(runes.In(unicode.Mn)), norm.NFC)
	out, _, _ := transform.String(t, strings.ToLower(s))
	return out
}

// Scan masks contact details and reports flags. The returned text is what
// both sides see.
func Scan(text string) (string, []string) {
	var flags []string
	add := func(f string) {
		for _, x := range flags {
			if x == f {
				return
			}
		}
		flags = append(flags, f)
	}
	replace := func(re *regexp.Regexp, flag string) {
		text = re.ReplaceAllStringFunc(text, func(string) string { add(flag); return Mask })
	}
	replace(reEmail, Email)
	replace(reIBAN, BankAccount)
	replace(reAccount, BankAccount)
	replace(rePhone, Phone)
	if AdvancePaymentRequested(text) {
		add(AdvancePayment)
	}
	return text, flags
}

var advance = []*regexp.Regexp{
	// "pošlete zálohu předem", "zašlete kauci na účet", "převeďte rezervační poplatek"
	regexp.MustCompile(`\b(posl|zasl|prev|poukaz|uhrad|zaplat|plat|vlozt|vlozi|send|transfer|wire|pay)\w*\b.{0,60}\b(zaloh|kauc|rezervac|poplat|deposit|advance|upfront|booking fee)\w*`),
	regexp.MustCompile(`\b(zaloh|kauc|rezervac\w* poplat|deposit|first month)\w*\b.{0,60}\b(predem|pred prohlidkou|bez prohlidky|in advance|upfront|before (the )?viewing)\b`),
	// Untraceable payment channels and the "keys by courier" scam.
	regexp.MustCompile(`\b(western union|moneygram|paysafecard|bitcoin|btc|kryptomen|crypto|gift card|darkov\w* kart)\w*`),
	regexp.MustCompile(`\b(klic\w*|keys)\b.{0,40}\b(posl\w*|zasl\w*|kuryr\w*|courier|post\w*|by mail)\b`),
}

// AdvancePaymentRequested reports a request to pay before a viewing or
// through an untraceable channel.
func AdvancePaymentRequested(text string) bool {
	f := fold(text)
	for _, re := range advance {
		if re.MatchString(f) {
			return true
		}
	}
	return false
}
