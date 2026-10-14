package applications

import (
	"slices"
	"strings"
	"time"
)

// Lifestyle tags a roommate profile can carry. Pairs in conflicts exclude
// each other in matching.
var Lifestyle = []string{"non_smoker", "smoker", "pets", "no_pets", "quiet", "social", "early_bird", "night_owl",
	"works_from_home", "student", "tidy", "vegetarian"}

var conflicts = [][2]string{{"non_smoker", "smoker"}, {"pets", "no_pets"}, {"quiet", "social"}, {"early_bird", "night_owl"}}

// MatchProfile is the part of a profile that matching uses.
type MatchProfile struct {
	AdminPath string // ltree text, "" = anywhere
	BudgetMax int64
	MoveIn    *time.Time
	Lifestyle []string
}

// inArea reports whether two ltree paths overlap (one contains the other).
func inArea(a, b string) bool {
	if a == "" || b == "" {
		return true
	}
	return a == b || strings.HasPrefix(a, b+".") || strings.HasPrefix(b, a+".")
}

func conflictCount(a, b []string) int {
	n := 0
	for _, c := range conflicts {
		if (slices.Contains(a, c[0]) && slices.Contains(b, c[1])) || (slices.Contains(a, c[1]) && slices.Contains(b, c[0])) {
			n++
		}
	}
	return n
}

func overlap(a, b []string) float64 {
	if len(a) == 0 || len(b) == 0 {
		return 0.5 // unknown: neutral
	}
	common := 0
	for _, x := range a {
		if slices.Contains(b, x) {
			common++
		}
	}
	union := len(a) + len(b) - common
	return float64(common) / float64(union)
}

// ScoreProfiles rates two seekers as flatmates, 0-100 (v0: filters and
// weights, no learning): area 30, budget 25, move-in 15, lifestyle 30,
// minus 25 per conflicting habit.
func ScoreProfiles(a, b MatchProfile) int {
	if !inArea(a.AdminPath, b.AdminPath) {
		return 0
	}
	score := 30.0
	if a.BudgetMax > 0 && b.BudgetMax > 0 {
		lo, hi := min(a.BudgetMax, b.BudgetMax), max(a.BudgetMax, b.BudgetMax)
		score += 25 * float64(lo) / float64(hi)
	}
	if a.MoveIn != nil && b.MoveIn != nil {
		days := a.MoveIn.Sub(*b.MoveIn).Hours() / 24
		if days < 0 {
			days = -days
		}
		score += 15 * max(0, 1-days/60)
	} else {
		score += 7.5
	}
	score += 30 * overlap(a.Lifestyle, b.Lifestyle)
	score -= 25 * float64(conflictCount(a.Lifestyle, b.Lifestyle))
	return int(min(max(score, 0), 100) + 0.5)
}

// ListingFacts is what matching needs about a room listing.
type ListingFacts struct {
	AdminPath  string
	Rent       int64
	Attributes map[string]any
}

// ScoreListing rates a seeker for a room: budget 40, area 30, house rules 30.
func ScoreListing(p MatchProfile, l ListingFacts) int {
	if !inArea(p.AdminPath, l.AdminPath) {
		return 0
	}
	score := 30.0
	switch {
	case l.Rent <= p.BudgetMax:
		score += 40
	case p.BudgetMax > 0:
		score += 40 * max(0, 1-float64(l.Rent-p.BudgetMax)/float64(p.BudgetMax)*4)
	}
	rules := 30.0
	if pets, ok := l.Attributes["pets"].([]any); ok && len(pets) == 0 && slices.Contains(p.Lifestyle, "pets") {
		rules -= 20
	}
	if smoking, ok := l.Attributes["smoking"].(bool); ok && !smoking && slices.Contains(p.Lifestyle, "smoker") {
		rules -= 20
	}
	return int(min(max(score+max(rules, 0), 0), 100) + 0.5)
}
