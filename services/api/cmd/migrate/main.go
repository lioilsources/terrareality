// Command migrate runs goose commands against DATABASE_URL using the embedded
// migrations. Usage: migrate [up|down|status|redo|reset|version]
package main

import (
	"context"
	"database/sql"
	"fmt"
	"os"

	_ "github.com/jackc/pgx/v5/stdlib"

	"github.com/terrareality/terrareality/services/api/internal/jobs"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	"github.com/terrareality/terrareality/services/api/internal/platform/db"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		fail(err)
	}
	cmd := "up"
	var args []string
	if len(os.Args) > 1 {
		cmd, args = os.Args[1], os.Args[2:]
	}
	sqlDB, err := sql.Open("pgx", cfg.DatabaseURL)
	if err != nil {
		fail(err)
	}
	defer sqlDB.Close()
	ctx := context.Background()
	if err := db.MigrateCmd(ctx, sqlDB, cmd, args...); err != nil {
		fail(err)
	}
	if cmd == "up" {
		pool, err := db.Open(ctx, cfg.DatabaseURL)
		if err != nil {
			fail(err)
		}
		defer pool.Close()
		if err := jobs.MigrateRiver(ctx, pool); err != nil {
			fail(err)
		}
	}
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, "migrate:", err)
	os.Exit(1)
}
