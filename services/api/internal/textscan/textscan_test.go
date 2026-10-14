package textscan

import (
	"slices"
	"testing"
)

func TestScan(t *testing.T) {
	cases := []struct {
		in    string
		out   string
		flags []string
	}{
		{"Dobrý den, mám zájem o prohlídku v úterý.", "Dobrý den, mám zájem o prohlídku v úterý.", nil},
		{"Volejte na +420 777 123 456 kdykoli", "Volejte na [•••] kdykoli", []string{Phone}},
		{"tel. 777123456", "tel. [•••]", []string{Phone}},
		{"pište na jan.novak@seznam.cz", "pište na [•••]", []string{Email}},
		{"jan.novak (at) seznam (dot) cz", "[•••]", []string{Email}},
		{"účet 19-2000145399/0800", "účet [•••]", []string{BankAccount}},
		{"IBAN CZ65 0800 0000 1920 0014 5399", "IBAN [•••]", []string{BankAccount}},
		{"Nájem 22 000 Kč, kauce 44 000 Kč, od 1.11.2026", "Nájem 22 000 Kč, kauce 44 000 Kč, od 1.11.2026", nil},
		{"Pošlete prosím zálohu předem, jsem v zahraničí", "Pošlete prosím zálohu předem, jsem v zahraničí", []string{AdvancePayment}},
		{"Klíče vám zašlu kurýrem po platbě přes Western Union", "Klíče vám zašlu kurýrem po platbě přes Western Union", []string{AdvancePayment}},
		{"Please send the deposit upfront", "Please send the deposit upfront", []string{AdvancePayment}},
		{"Kauce se platí při podpisu smlouvy.", "Kauce se platí při podpisu smlouvy.", nil},
	}
	for _, c := range cases {
		out, flags := Scan(c.in)
		if out != c.out || !slices.Equal(flags, c.flags) {
			t.Errorf("Scan(%q) = %q %v, want %q %v", c.in, out, flags, c.out, c.flags)
		}
	}
}
