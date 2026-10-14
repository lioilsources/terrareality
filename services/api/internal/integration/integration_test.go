// Package integration runs tests against a real PostgreSQL (infra/dev, database
// terra_test). They are skipped when TEST_DATABASE_URL is not set.
package integration

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/health"
	"github.com/terrareality/terrareality/services/api/internal/jobs"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

func setup(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}
	ctx := context.Background()
	pool, err := platformdb.Open(ctx, url)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	if err := platformdb.Migrate(ctx, pool); err != nil {
		t.Fatalf("migrate: %v", err)
	}
	if err := jobs.MigrateRiver(ctx, pool); err != nil {
		t.Fatalf("river migrate: %v", err)
	}
	return pool
}

func TestMigrationsInstallExtensions(t *testing.T) {
	pool := setup(t)
	want := []string{"postgis", "vector", "pg_trgm", "unaccent", "ltree", "citext", "pgcrypto"}
	for _, ext := range want {
		var ok bool
		if err := pool.QueryRow(context.Background(),
			"SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = $1)", ext).Scan(&ok); err != nil || !ok {
			t.Errorf("extension %s missing (err=%v)", ext, err)
		}
	}
	v, err := platformdb.SchemaVersion(context.Background(), pool)
	if err != nil || v < 1 {
		t.Fatalf("schema version %d err %v", v, err)
	}
}

func TestUUIDv7IsTimeOrdered(t *testing.T) {
	pool := setup(t)
	q := db.New(pool)
	ctx := context.Background()
	a, err := q.NewUUIDv7(ctx)
	if err != nil {
		t.Fatal(err)
	}
	time.Sleep(2 * time.Millisecond)
	b, _ := q.NewUUIDv7(ctx)
	if a.Version() != 7 || b.Version() != 7 {
		t.Fatalf("not v7: %s %s", a, b)
	}
	if a.String() >= b.String() {
		t.Fatalf("not ordered: %s >= %s", a, b)
	}
}

func TestHeartbeatJobFeedsHealthCheck(t *testing.T) {
	pool := setup(t)
	q := db.New(pool)
	ctx := context.Background()
	if _, err := pool.Exec(ctx, "DELETE FROM app_meta WHERE key = $1", jobs.HeartbeatKey); err != nil {
		t.Fatal(err)
	}
	check := health.WorkerHeartbeat(q, jobs.HeartbeatKey, time.Minute)
	if err := check(ctx); err == nil {
		t.Fatal("expected failure before first heartbeat")
	}
	w := &jobs.HeartbeatWorker{Q: q}
	if err := w.Work(ctx, nil); err != nil {
		t.Fatal(err)
	}
	if err := check(ctx); err != nil {
		t.Fatalf("expected healthy after heartbeat: %v", err)
	}
}
