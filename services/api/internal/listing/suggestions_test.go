package listing

import (
	"testing"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

func TestRedactionQueued(t *testing.T) {
	cases := []struct {
		sg   db.AiSuggestion
		want bool
	}{
		{db.AiSuggestion{Kind: "privacy_blur", Status: "pending", Decision: []byte(`{"accept":true}`)}, true},
		{db.AiSuggestion{Kind: "privacy_blur", Status: "pending"}, false},
		{db.AiSuggestion{Kind: "privacy_blur", Status: "accepted", Decision: []byte(`{"accept":true}`)}, false},
		{db.AiSuggestion{Kind: "privacy_blur", Status: "rejected", Decision: []byte(`{"accept":false}`)}, false},
		{db.AiSuggestion{Kind: "text", Status: "pending", Decision: []byte(`{"accept":true}`)}, false},
	}
	for i, c := range cases {
		if got := redactionQueued(c.sg); got != c.want {
			t.Errorf("case %d: %v", i, got)
		}
	}
}

func TestCheckTextsCountsRunes(t *testing.T) {
	long := I18n{CS: string(make([]rune, 121))}
	if len(checkTexts(long, I18n{})) != 1 {
		t.Fatal("121 characters accepted as a title")
	}
	if len(checkTexts(I18n{CS: "Světlý byt"}, I18n{CS: "Popis"})) != 0 {
		t.Fatal("valid texts rejected")
	}
}
