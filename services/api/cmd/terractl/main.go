// Command terractl is the operator CLI.
//
//	terractl staff grant <email>    mark an existing user as platform staff
//	terractl staff revoke <email>   remove staff rights
//	terractl seed-dev               create dev accounts (APP_ENV=dev|test only)
//	terractl ruian import <file>    import RÚIAN address points (CSV or ZIP of CSVs)
//	terractl admin import <file>    import administrative units (GeoJSON, see infra/README-geo.md)
//	terractl seed-search <n>        ensure n synthetic published listings (APP_ENV=dev|test only)
//	terractl reindex                rebuild the search index from approved versions
package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/ruian"
	"github.com/terrareality/terrareality/services/api/internal/search"
)

// Dev accounts created by seed-dev. The password is public on purpose and
// the command refuses to run outside dev/test.
const (
	devStaffEmail = "staff@terra.local"
	devOwnerEmail = "owner@terra.local"
	devPassword   = "terra-dev-password"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "terractl:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	ctx := context.Background()
	pool, err := platformdb.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()
	q := db.New(pool)
	switch {
	case len(args) == 3 && args[0] == "staff" && (args[1] == "grant" || args[1] == "revoke"):
		u, err := q.GetUserByEmail(ctx, args[2])
		if err != nil {
			return fmt.Errorf("user %s: %w", args[2], err)
		}
		if err := q.SetStaff(ctx, db.SetStaffParams{ID: u.ID, IsStaff: args[1] == "grant"}); err != nil {
			return err
		}
		fmt.Printf("%s staff=%v\n", u.Email, args[1] == "grant")
		return nil
	case len(args) == 3 && args[0] == "ruian" && args[1] == "import":
		if err := platformdb.Migrate(ctx, pool); err != nil {
			return err
		}
		n, err := ruian.ImportFile(ctx, pool, args[2])
		fmt.Printf("imported %d address points\n", n)
		return err
	case len(args) == 3 && args[0] == "admin" && args[1] == "import":
		if err := platformdb.Migrate(ctx, pool); err != nil {
			return err
		}
		f, err := os.Open(args[2])
		if err != nil {
			return err
		}
		defer f.Close()
		n, err := search.ImportGeoJSON(ctx, pool, f)
		fmt.Printf("imported %d administrative units\n", n)
		return err
	case len(args) == 2 && args[0] == "seed-search":
		if cfg.Env != "dev" && cfg.Env != "test" {
			return errors.New("seed-search only runs with APP_ENV=dev or test")
		}
		var count int
		if _, err := fmt.Sscan(args[1], &count); err != nil {
			return err
		}
		if _, err := ruian.SeedSample(ctx, pool); err != nil {
			return err
		}
		if _, err := search.SeedFromRuian(ctx, pool); err != nil {
			return err
		}
		n, err := search.Synthetic(ctx, pool, count)
		fmt.Printf("added %d synthetic listings\n", n)
		return err
	case len(args) == 1 && args[0] == "reindex":
		ids, err := q.PublishedListingIDs(ctx)
		if err != nil {
			return err
		}
		n := 0
		for _, id := range ids {
			if err := (search.Indexer{}).Index(ctx, q, id); err != nil {
				return fmt.Errorf("listing %s: %w", id, err)
			}
			n++
		}
		if err := q.RefreshListingAggregates(ctx); err != nil {
			return err
		}
		fmt.Printf("reindexed %d listings\n", n)
		return nil
	case len(args) == 1 && args[0] == "seed-dev":
		if cfg.Env != "dev" && cfg.Env != "test" {
			return errors.New("seed-dev only runs with APP_ENV=dev or test")
		}
		if err := platformdb.Migrate(ctx, pool); err != nil {
			return err
		}
		for _, a := range []struct {
			email, name string
			staff       bool
		}{{devStaffEmail, "Terra Staff", true}, {devOwnerEmail, "Olga Majitelová", false}} {
			if err := seedUser(ctx, pool, a.email, a.name, a.staff); err != nil {
				return err
			}
			fmt.Printf("%s / %s (staff=%v)\n", a.email, devPassword, a.staff)
		}
		return nil
	}
	return errors.New("usage: terractl staff grant|revoke <email> | seed-dev | ruian import <file> | admin import <file> | seed-search <n> | reindex")
}

func seedUser(ctx context.Context, pool *pgxpool.Pool, email, name string, staff bool) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		if _, err := q.GetUserByEmail(ctx, email); err == nil {
			return nil
		}
		hash, err := auth.HashPassword(devPassword)
		if err != nil {
			return err
		}
		now := time.Now()
		u, err := q.CreateUser(ctx, db.CreateUserParams{Email: email, PasswordHash: &hash, DisplayName: name, Locale: "cs", EmailVerifiedAt: &now})
		if err != nil {
			return err
		}
		o, err := q.CreateOrganization(ctx, db.CreateOrganizationParams{Kind: "personal", Name: name, JurisdictionCode: "CZ", PersonalOwnerID: &u.ID})
		if err != nil {
			return err
		}
		if err := q.AddMembership(ctx, db.AddMembershipParams{OrgID: o.ID, UserID: u.ID, Role: "owner"}); err != nil {
			return err
		}
		return q.SetStaff(ctx, db.SetStaffParams{ID: u.ID, IsStaff: staff})
	})
}
