package applications

import (
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
)

func TestIncomeVisible(t *testing.T) {
	now := time.Date(2026, 10, 15, 12, 0, 0, 0, time.UTC)
	recent, old := now.Add(-24*time.Hour), now.Add(-(IncomeProofDays+1)*24*time.Hour)
	cases := []struct {
		status  string
		decided *time.Time
		want    bool
	}{
		{StatusSubmitted, nil, true},
		{StatusInvited, &recent, true},
		{StatusAccepted, &recent, true},
		{StatusAccepted, &old, false},
		{StatusRejected, &recent, false},
		{"withdrawn", &recent, false},
		{StatusPendingConsent, nil, false},
	}
	for _, c := range cases {
		if got := incomeVisible(c.status, c.decided, now); got != c.want {
			t.Errorf("%s decided %v: %v", c.status, c.decided, got)
		}
	}
}

func TestIsAcceptedConflict(t *testing.T) {
	if !isAcceptedConflict(&pgconn.PgError{Code: "23505", ConstraintName: "applications_accepted_per_listing"}) {
		t.Fatal("unique violation on accepted applications not recognized")
	}
	if isAcceptedConflict(&pgconn.PgError{Code: "23505", ConstraintName: "other"}) || isAcceptedConflict(nil) {
		t.Fatal("other errors mapped to 409")
	}
}
