package leasing

import (
	"fmt"
	"time"
)

// Terms are the payment terms of a lease.
type Terms struct {
	StartsOn time.Time
	EndsOn   *time.Time // nil = indefinite
	Rent     int64      // per month, minor units
	Services int64      // advance payments per month
	Deposit  int64
	DueDay   int
}

// Share is a paying party with its share in basis points.
type Share struct {
	PartyID  string
	ShareBps int
}

// Item is one obligation with its split between parties.
type Item struct {
	Kind   string // rent | deposit
	Period string // YYYY-MM for rent
	DueOn  time.Time
	Amount int64
	Splits map[string]int64 // party id -> amount
}

// IndefiniteHorizon is how many months ahead an indefinite lease is
// scheduled; the lifecycle workflow extends it.
const IndefiniteHorizon = 12

// SplitAmount divides amount by shares; rounding leftovers go to the first party.
func SplitAmount(amount int64, shares []Share) map[string]int64 {
	out := map[string]int64{}
	total := 0
	for _, s := range shares {
		total += s.ShareBps
	}
	if total == 0 || len(shares) == 0 {
		return out
	}
	var assigned int64
	for _, s := range shares {
		part := amount * int64(s.ShareBps) / int64(total)
		out[s.PartyID] = part
		assigned += part
	}
	out[shares[0].PartyID] += amount - assigned
	for k, v := range out {
		if v == 0 {
			delete(out, k)
		}
	}
	return out
}

func dueIn(month time.Time, day int, starts time.Time) time.Time {
	due := time.Date(month.Year(), month.Month(), day, 0, 0, 0, 0, time.UTC)
	if due.Before(starts) {
		return starts // first month: due on the start date at the earliest
	}
	return due
}

// Schedule lists the deposit and the monthly payments (rent plus service
// advances in one payment) from the start month on: for a fixed term until
// the end, for an indefinite term from fromMonth for IndefiniteHorizon months.
func Schedule(t Terms, shares []Share, fromMonth time.Time) []Item {
	var out []Item
	start := time.Date(t.StartsOn.Year(), t.StartsOn.Month(), 1, 0, 0, 0, 0, time.UTC)
	if fromMonth.IsZero() || fromMonth.Before(start) {
		if t.Deposit > 0 {
			out = append(out, Item{Kind: "deposit", DueOn: t.StartsOn, Amount: t.Deposit, Splits: SplitAmount(t.Deposit, shares)})
		}
		fromMonth = start
	}
	end := fromMonth.AddDate(0, IndefiniteHorizon, 0)
	if t.EndsOn != nil {
		end = time.Date(t.EndsOn.Year(), t.EndsOn.Month(), 1, 0, 0, 0, 0, time.UTC).AddDate(0, 1, 0)
	}
	monthly := t.Rent + t.Services
	for m := fromMonth; m.Before(end); m = m.AddDate(0, 1, 0) {
		out = append(out, Item{Kind: "rent", Period: fmt.Sprintf("%04d-%02d", m.Year(), m.Month()),
			DueOn: dueIn(m, t.DueDay, t.StartsOn), Amount: monthly, Splits: SplitAmount(monthly, shares)})
	}
	return out
}
