package applications

import (
	"testing"
	"time"
)

func TestScoreProfiles(t *testing.T) {
	d := func(day int) *time.Time { x := time.Date(2026, 11, day, 0, 0, 0, 0, time.UTC); return &x }
	a := MatchProfile{AdminPath: "cz.praha.praha6", BudgetMax: 1_000_000, MoveIn: d(1), Lifestyle: []string{"non_smoker", "quiet", "tidy"}}
	twin := MatchProfile{AdminPath: "cz.praha", BudgetMax: 1_000_000, MoveIn: d(1), Lifestyle: []string{"non_smoker", "quiet", "tidy"}}
	clash := MatchProfile{AdminPath: "cz.praha.praha6", BudgetMax: 1_000_000, MoveIn: d(1), Lifestyle: []string{"smoker", "social"}}
	elsewhere := MatchProfile{AdminPath: "cz.brno", BudgetMax: 1_000_000}
	if s := ScoreProfiles(a, twin); s != 100 {
		t.Fatalf("twin %d", s)
	}
	if s := ScoreProfiles(a, clash); s >= 40 {
		t.Fatalf("clash %d", s)
	}
	if s := ScoreProfiles(a, elsewhere); s != 0 {
		t.Fatalf("other city %d", s)
	}
	if ScoreProfiles(a, twin) != ScoreProfiles(twin, a) {
		t.Fatal("not symmetric")
	}
}

func TestScoreListing(t *testing.T) {
	p := MatchProfile{AdminPath: "cz.praha", BudgetMax: 1_000_000, Lifestyle: []string{"pets"}}
	ok := ListingFacts{AdminPath: "cz.praha.praha6.dejvice", Rent: 950_000, Attributes: map[string]any{"pets": []any{"dogs"}}}
	pricey := ListingFacts{AdminPath: "cz.praha.praha6", Rent: 1_300_000}
	noPets := ListingFacts{AdminPath: "cz.praha.praha6", Rent: 950_000, Attributes: map[string]any{"pets": []any{}}}
	if s := ScoreListing(p, ok); s != 100 {
		t.Fatalf("fit %d", s)
	}
	if s := ScoreListing(p, pricey); s >= 70 {
		t.Fatalf("over budget %d", s)
	}
	if ScoreListing(p, noPets) >= ScoreListing(p, ok) {
		t.Fatal("pet rule ignored")
	}
}
