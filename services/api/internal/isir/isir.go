// Package isir checks the Czech insolvency register (ISIR). The result shown
// to landlords is only "no record" or "record"; details stay in the register.
package isir

import (
	"context"
	"strings"
	"time"
)

// Person identifies who to look up (from a verified identity).
type Person struct {
	GivenName  string
	FamilyName string
	Birthdate  time.Time
}

// Result of a check.
const (
	Clear  = "clear"
	Record = "record"
)

// Checker looks a person up.
type Checker interface {
	Check(ctx context.Context, p Person) (string, error)
}

// Mock reports a record for family names starting with "Insolvent" (tests
// and demos) and no record otherwise.
type Mock struct{}

// Check implements Checker.
func (Mock) Check(_ context.Context, p Person) (string, error) {
	if strings.HasPrefix(strings.ToLower(p.FamilyName), "insolvent") {
		return Record, nil
	}
	return Clear, nil
}
