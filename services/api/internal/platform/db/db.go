// Package db owns the PostgreSQL connection pool and schema migrations.
package db

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/lioilsources/ol1n_platform_kit/schema"
	"github.com/lioilsources/ol1n_platform_kit/tenancy"
	pgxvec "github.com/pgvector/pgvector-go/pgx"
	"github.com/pressly/goose/v3"

	"github.com/terrareality/terrareality/services/api/migrations"
)

// rls is TerraReality's row-level security setup (ADR 0004) for the kit.
var rls = tenancy.Tenancy{Role: "terra_app", UserSetting: tenancy.DefaultUserSetting}

// KitMigrations is the platform kit's own goose history (ADR 0013). It runs
// after TerraReality's migrations, whose history already created its tables.
func KitMigrations() tenancy.MigrationSet { return schema.Migrations() }

var _ embed.FS // migrations are embedded in the migrations package

// Open creates a pgx pool and verifies connectivity.
func Open(ctx context.Context, url string) (*pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		return nil, fmt.Errorf("parse DATABASE_URL: %w", err)
	}
	// pgx defaults to max(4, CPUs); a search runs five queries in parallel.
	if cfg.MaxConns < 16 {
		cfg.MaxConns = 16
	}
	cfg.MaxConnLifetime = time.Hour
	cfg.MaxConnIdleTime = 10 * time.Minute
	// pgvector types (embeddings); the extension exists from migration 00001.
	// On a brand-new database the first connection precedes migrations, so a
	// missing type is tolerated and registered on later connections.
	cfg.AfterConnect = func(ctx context.Context, conn *pgx.Conn) error {
		_ = pgxvec.RegisterTypes(ctx, conn)
		return nil
	}
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}
	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping database: %w", err)
	}
	return pool, nil
}

// migrateLock serialises migrators that share one database: api and worker
// both start with MIGRATE_ON_START, and test packages run in parallel against
// terra_test. Goose 3.29 takes no lock of its own, so two of them racing end in
// "duplicate key value violates unique constraint pg_extension_name_index".
const migrateLock int64 = 0x74657272615f6d67 // "terra_mg"

// locked runs fn while holding migrateLock on one dedicated session.
func locked(ctx context.Context, sqlDB *sql.DB, fn func() error) error {
	conn, err := sqlDB.Conn(ctx)
	if err != nil {
		return fmt.Errorf("migrate lock: %w", err)
	}
	defer conn.Close()
	if _, err := conn.ExecContext(ctx, "SELECT pg_advisory_lock($1)", migrateLock); err != nil {
		return fmt.Errorf("migrate lock: %w", err)
	}
	defer func() {
		_, _ = conn.ExecContext(context.WithoutCancel(ctx), "SELECT pg_advisory_unlock($1)", migrateLock)
	}()
	return fn()
}

// Migrate applies all pending goose migrations embedded in the binary, then
// the platform kit's migrations (no-ops over tables TerraReality created).
func Migrate(ctx context.Context, pool *pgxpool.Pool) error {
	sqlDB := stdlib.OpenDBFromPool(pool)
	defer sqlDB.Close()
	if err := locked(ctx, sqlDB, func() error {
		return withGoose(func() error { return goose.UpContext(ctx, sqlDB, ".") })
	}); err != nil {
		return err
	}
	kit := KitMigrations()
	if err := tenancy.Migrate(ctx, pool, migrateLock, kit); err != nil {
		return err
	}
	// Like goose_db_version (00012, 00013): the schema version is the
	// migration owner's business; the app and service roles only read it.
	_, err := pool.Exec(ctx, "REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON "+
		pgx.Identifier{kit.Table}.Sanitize()+" FROM terra_app, terra_service")
	return err
}

// SchemaVersion returns the current goose schema version.
func SchemaVersion(ctx context.Context, pool *pgxpool.Pool) (int64, error) {
	sqlDB := stdlib.OpenDBFromPool(pool)
	defer sqlDB.Close()
	var v int64
	err := withGoose(func() error {
		var err error
		v, err = goose.GetDBVersionContext(ctx, sqlDB)
		return err
	})
	return v, err
}

// MigrateCmd runs an arbitrary goose command (up, down, status, redo...).
func MigrateCmd(ctx context.Context, sqlDB *sql.DB, command string, args ...string) error {
	return locked(ctx, sqlDB, func() error {
		return withGoose(func() error { return goose.RunContext(ctx, command, sqlDB, ".", args...) })
	})
}

func withGoose(fn func() error) error {
	goose.SetBaseFS(migrations.FS)
	if err := goose.SetDialect("postgres"); err != nil {
		return err
	}
	return fn()
}

// InTx runs fn in a transaction as the owner role (system context: auth,
// jobs, backoffice). Authorization is the caller's responsibility.
func InTx(ctx context.Context, pool *pgxpool.Pool, fn func(pgx.Tx) error) error {
	return tenancy.InTx(ctx, pool, fn)
}

// AsUser runs fn in a transaction with row-level security enforced for the
// given user: the role switches to terra_app and app.current_user is set, so
// org-scoped tables only expose rows of the user's organizations.
func AsUser(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, fn func(pgx.Tx) error) error {
	return rls.AsUser(ctx, pool, userID, fn)
}

// Elevate ends row-level security for the rest of an AsUser transaction: the
// role returns to the login role (system context) and app.current_user is
// cleared. Callers first check the user's access under RLS, then do the
// system part of the same change (notifications to other users, the e-mail
// outbox) in the same transaction, so both commit or roll back together.
func Elevate(ctx context.Context, tx pgx.Tx) error {
	return rls.Elevate(ctx, tx)
}
