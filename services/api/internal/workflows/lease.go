package workflows

import (
	"time"

	"github.com/google/uuid"
	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"

	"github.com/terrareality/terrareality/services/api/internal/leasing"
)

// LeaseWorkflowID is the workflow id of a lease (one lifecycle per lease).
func LeaseWorkflowID(id uuid.UUID) string { return "lease-" + id.String() }

// lifecycleBatch bounds the history: after this many due dates the workflow
// continues as new.
const lifecycleBatch = 24

// LeaseLifecycle drives a signed lease: it activates the lease on the start
// date, sends reminders before and after every due date (D-3, D+1) and
// escalates at D+7 while a share is unpaid, extends the schedule of
// indefinite leases and terminates the lease after its last day. The state
// lives in the database; the workflow only owns the timers.
func LeaseLifecycle(ctx workflow.Context, leaseID uuid.UUID, after time.Time) error {
	var a *leasing.Activities
	ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		StartToCloseTimeout: time.Minute,
		RetryPolicy:         &temporal.RetryPolicy{MaximumInterval: 10 * time.Minute},
	})
	sleepUntil := func(t time.Time) error {
		if d := t.Sub(workflow.Now(ctx)); d > 0 {
			return workflow.Sleep(ctx, d)
		}
		return nil
	}
	var info leasing.Info
	if err := workflow.ExecuteActivity(ctx, a.Info, leaseID).Get(ctx, &info); err != nil {
		return err
	}
	if info.State == "signed" {
		if err := sleepUntil(info.StartsOn); err != nil {
			return err
		}
		if err := workflow.ExecuteActivity(ctx, a.Activate, leaseID).Get(ctx, nil); err != nil {
			return err
		}
	}
	stages := leasing.ReminderStages
	if len(info.Stages) > 0 {
		stages = info.Stages // rules per municipality or group, stored on the lease
	}
	for done := 0; done < lifecycleBatch; {
		var dates []time.Time
		if err := workflow.ExecuteActivity(ctx, a.DueDates, leaseID, after.AddDate(0, 0, 1)).Get(ctx, &dates); err != nil {
			return err
		}
		if len(dates) == 0 {
			var finished bool
			if err := workflow.ExecuteActivity(ctx, a.Finish, leaseID).Get(ctx, &finished); err != nil || finished {
				return err
			}
			var extended bool
			if err := workflow.ExecuteActivity(ctx, a.Extend, leaseID).Get(ctx, &extended); err != nil {
				return err
			}
			if !extended {
				if err := workflow.Sleep(ctx, 24*time.Hour); err != nil {
					return err
				}
			}
			continue
		}
		due := dates[0]
		for _, st := range stages {
			at := due.AddDate(0, 0, st.Offset)
			if at.Before(workflow.Now(ctx).Add(-12 * time.Hour)) {
				continue // long past (lease signed late): skip stale reminders
			}
			if err := sleepUntil(at); err != nil {
				return err
			}
			var unpaid int
			if err := workflow.ExecuteActivity(ctx, a.Remind, leaseID, due, st.Name).Get(ctx, &unpaid); err != nil {
				return err
			}
			if unpaid == 0 {
				break
			}
		}
		after = time.Date(due.Year(), due.Month(), due.Day(), 0, 0, 0, 0, time.UTC)
		done++
		var extended bool
		if err := workflow.ExecuteActivity(ctx, a.Extend, leaseID).Get(ctx, &extended); err != nil {
			return err
		}
	}
	return workflow.NewContinueAsNewError(ctx, LeaseLifecycle, leaseID, after)
}
