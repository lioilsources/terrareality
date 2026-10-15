package ai

import (
	"strings"
	"testing"
	"unicode/utf8"
)

func TestTruncateRunesKeepsUTF8(t *testing.T) {
	s := strings.Repeat("ř", 200) // two bytes each: a byte cut at 120 splits one
	got := truncateRunes(s, MaxTitleRunes)
	if !utf8.ValidString(got) || utf8.RuneCountInString(got) != MaxTitleRunes {
		t.Fatalf("got %d runes, valid %v", utf8.RuneCountInString(got), utf8.ValidString(got))
	}
	if truncateRunes("Byt 2+kk", MaxTitleRunes) != "Byt 2+kk" {
		t.Fatal("short text changed")
	}
}
