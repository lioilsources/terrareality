// Package workflows holds Temporal workflows. Long-running business processes
// (lease lifecycle, dunning, settlements) live here from milestone M6 on; M0
// ships a Ping workflow that proves the worker wiring end to end.
package workflows

import (
	"context"
	"time"

	"go.temporal.io/sdk/workflow"
)

// TaskQueue is the default Temporal task queue for the platform.
const TaskQueue = "terra-main"

// Ping returns "pong <name>" via an activity.
func Ping(ctx workflow.Context, name string) (string, error) {
	ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{StartToCloseTimeout: 10 * time.Second})
	var out string
	err := workflow.ExecuteActivity(ctx, PingActivity, name).Get(ctx, &out)
	return out, err
}

// PingActivity is the activity behind Ping.
func PingActivity(_ context.Context, name string) (string, error) {
	return "pong " + name, nil
}
