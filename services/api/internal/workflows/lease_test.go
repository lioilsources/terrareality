package workflows

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/mock"
	"go.temporal.io/sdk/testsuite"

	"github.com/terrareality/terrareality/services/api/internal/leasing"
)

type reminder struct {
	stage string
	at    time.Time
}

// runLifecycle runs the workflow for one due date; paidAfter is the stage
// after which Remind reports everything paid ("" = never).
func runLifecycle(t *testing.T, paidAfter string) []reminder {
	t.Helper()
	var s testsuite.WorkflowTestSuite
	env := s.NewTestWorkflowEnvironment()
	a := &leasing.Activities{}
	env.RegisterActivity(a)
	start := time.Date(2026, 11, 1, 0, 0, 0, 0, time.UTC)
	env.SetStartTime(start.Add(-48 * time.Hour))
	id := uuid.New()
	due := time.Date(2026, 11, 15, 8, 0, 0, 0, time.UTC)
	end := time.Date(2026, 12, 1, 0, 0, 0, 0, time.UTC)

	env.OnActivity(a.Info, mock.Anything, id).Return(leasing.Info{State: "signed", StartsOn: start, EndsOn: &end}, nil)
	activatedAt := time.Time{}
	env.OnActivity(a.Activate, mock.Anything, id).Return(func(_ context.Context, _ uuid.UUID) error {
		activatedAt = env.Now()
		return nil
	})
	served := false
	env.OnActivity(a.DueDates, mock.Anything, id, mock.Anything).Return(func(_ context.Context, _ uuid.UUID, _ time.Time) ([]time.Time, error) {
		if served {
			return nil, nil
		}
		served = true
		return []time.Time{due}, nil
	})
	var got []reminder
	paid := false
	env.OnActivity(a.Remind, mock.Anything, id, due, mock.Anything).Return(func(_ context.Context, _ uuid.UUID, _ time.Time, stage string) (int, error) {
		got = append(got, reminder{stage, env.Now()})
		if paid {
			return 0, nil
		}
		if stage == paidAfter {
			paid = true
		}
		return 2, nil
	})
	env.OnActivity(a.Extend, mock.Anything, id).Return(false, nil)
	env.OnActivity(a.Finish, mock.Anything, id).Return(func(_ context.Context, _ uuid.UUID) (bool, error) {
		return env.Now().After(end), nil
	})
	env.ExecuteWorkflow(LeaseLifecycle, id, time.Time{})
	if !env.IsWorkflowCompleted() || env.GetWorkflowError() != nil {
		t.Fatalf("workflow: completed=%v err=%v", env.IsWorkflowCompleted(), env.GetWorkflowError())
	}
	if !activatedAt.Equal(start) {
		t.Fatalf("activated at %v, want %v", activatedAt, start)
	}
	return got
}

// Acceptance M6: seven days after the due date without payment the workflow escalates.
func TestLeaseLifecycleEscalatesAfterSevenDays(t *testing.T) {
	got := runLifecycle(t, "")
	if len(got) != 3 || got[0].stage != "upcoming" || got[1].stage != "overdue" || got[2].stage != "escalation" {
		t.Fatalf("reminders %+v", got)
	}
	due := time.Date(2026, 11, 15, 8, 0, 0, 0, time.UTC)
	if !got[0].at.Equal(due.AddDate(0, 0, -3)) || !got[2].at.Equal(due.AddDate(0, 0, 7)) {
		t.Fatalf("timing %+v", got)
	}
}

func TestLeaseLifecycleStopsWhenPaid(t *testing.T) {
	got := runLifecycle(t, "upcoming")
	if len(got) != 2 || got[1].stage != "overdue" {
		t.Fatalf("reminders %+v", got)
	}
}
