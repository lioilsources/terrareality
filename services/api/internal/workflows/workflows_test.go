package workflows

import (
	"testing"

	"go.temporal.io/sdk/testsuite"
)

func TestPing(t *testing.T) {
	var ts testsuite.WorkflowTestSuite
	env := ts.NewTestWorkflowEnvironment()
	env.RegisterActivity(PingActivity)
	env.ExecuteWorkflow(Ping, "terra")
	if !env.IsWorkflowCompleted() || env.GetWorkflowError() != nil {
		t.Fatalf("workflow failed: %v", env.GetWorkflowError())
	}
	var out string
	if err := env.GetWorkflowResult(&out); err != nil || out != "pong terra" {
		t.Fatalf("got %q, %v", out, err)
	}
}
