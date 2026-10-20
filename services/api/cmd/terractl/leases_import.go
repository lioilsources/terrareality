package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/jobs"
	"github.com/terrareality/terrareality/services/api/internal/leasing"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

const leasesUsage = "usage: terractl leases import --org <org-id-or-name> --csv <file> [--dry-run]"

// leasesCmd implements
//
//	terractl leases import --org <org-id-or-name> --csv existing-leases.csv [--dry-run]
//
// Concierge onboarding of leases a landlord signed on paper (M9): every row
// of the CSV is checked first and all problems are printed; nothing is
// written unless the whole file is valid, and then all leases are imported
// in one transaction (all or nothing). A dry run does the same import and
// rolls it back. The operator acts for the organization: the landlord party
// is its owner, events and the audit record say "terractl". Imported
// tenants are not contacted (docs/runbooks/seed-praha.md).
func leasesCmd(ctx context.Context, pool *pgxpool.Pool, args []string, out io.Writer) error {
	if len(args) == 0 || args[0] != "import" {
		return errors.New(leasesUsage)
	}
	fs := flag.NewFlagSet("leases import", flag.ContinueOnError)
	orgRef := fs.String("org", "", "organization id or exact name")
	csvPath := fs.String("csv", "", "CSV, columns: "+strings.Join(leasing.ImportColumns, ","))
	dryRun := fs.Bool("dry-run", false, "validate and import in a transaction that is rolled back")
	if err := fs.Parse(args[1:]); err != nil {
		return err
	}
	if *orgRef == "" || *csvPath == "" {
		return errors.New(leasesUsage)
	}
	if err := platformdb.Migrate(ctx, pool); err != nil {
		return err
	}
	if err := jobs.MigrateRiver(ctx, pool); err != nil {
		return err
	}
	f, err := os.Open(*csvPath)
	if err != nil {
		return err
	}
	defer f.Close()
	rc, err := jobs.NewInsertOnlyClient(pool)
	if err != nil {
		return err
	}
	svc := &leasing.Service{Pool: pool, Jobs: jobs.LeaseJobs{Client: rc}, Log: slog.Default()}
	return importLeases(ctx, svc, *orgRef, f, *dryRun, time.Now(), out)
}

// importLeases resolves the organization, parses and checks the CSV and
// imports it (or, with dryRun, rolls the import back).
func importLeases(ctx context.Context, svc *leasing.Service, orgRef string, csv io.Reader, dryRun bool, now time.Time, out io.Writer) error {
	q := db.New(svc.Pool)
	o, err := resolveOrg(ctx, q, orgRef)
	if err != nil {
		return err
	}
	j, err := q.GetJurisdiction(ctx, o.JurisdictionCode)
	if err != nil {
		return err
	}
	leases, problems := leasing.ParseImportCSV(csv, j.DepositMaxMonths, pragueDay(now))
	if len(problems) > 0 {
		for _, p := range problems {
			fmt.Fprintln(out, p.String())
		}
		return fmt.Errorf("%d problems in the CSV, nothing imported", len(problems))
	}
	var owner *uuid.UUID
	if id, err := q.FirstOrgOwner(ctx, o.ID); err == nil {
		owner = &id
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return err
	} else {
		fmt.Fprintf(out, "note: %q has no owner yet (invitation not accepted); the landlord party stays unlinked\n", o.Name)
	}
	res, err := svc.ImportBatch(ctx, o.ID, owner, leases, dryRun)
	if err != nil {
		return fmt.Errorf("nothing imported: %w", err)
	}
	verb := "imported"
	if dryRun {
		verb = "would import"
	}
	for i, r := range res {
		in := leases[i].Input
		var opening int64
		for _, p := range in.Parties {
			opening += p.OpeningBalance
		}
		vs := in.VariableSymbol
		if vs == "" {
			vs = fmt.Sprint(r.Code)
		}
		fmt.Fprintf(out, "%s lease %s: %s %s, %d tenant(s), %s from %s, cutover %s, VS %s, opening balance %s, deposit held %v",
			verb, r.Ref, in.Lease.PropertyAddress, in.Lease.UnitLabel, len(in.Parties), r.State,
			in.Lease.StartsOn.Format("2006-01-02"), in.CutoverOn.Format("2006-01-02"), vs, czk(opening), in.DepositHeld)
		if !dryRun {
			fmt.Fprintf(out, " -> %s (code %d)", r.ID, r.Code)
		}
		fmt.Fprintln(out)
	}
	if dryRun {
		fmt.Fprintf(out, "dry run: %d leases for %q are valid, nothing was written\n", len(res), o.Name)
	} else {
		fmt.Fprintf(out, "%d leases imported for %q; tenants were not contacted (invite them from the lease page)\n", len(res), o.Name)
	}
	return nil
}

// resolveOrg finds an organization by id or by its exact (case-insensitive) name.
func resolveOrg(ctx context.Context, q *db.Queries, ref string) (db.Organization, error) {
	if id, err := uuid.Parse(ref); err == nil {
		o, err := q.GetOrganization(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			return o, fmt.Errorf("organization %s not found", id)
		}
		return o, err
	}
	orgs, err := q.OrganizationsByName(ctx, ref)
	if err != nil {
		return db.Organization{}, err
	}
	switch len(orgs) {
	case 0:
		return db.Organization{}, fmt.Errorf("no organization named %q", ref)
	case 1:
		return orgs[0], nil
	}
	ids := make([]string, len(orgs))
	for i, o := range orgs {
		ids[i] = o.ID.String()
	}
	return db.Organization{}, fmt.Errorf("%d organizations are named %q, pass the id: %s", len(orgs), ref, strings.Join(ids, ", "))
}

func pragueDay(now time.Time) time.Time {
	if loc, err := time.LoadLocation("Europe/Prague"); err == nil {
		now = now.In(loc)
	}
	return time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
}

func czk(minor int64) string {
	if minor%100 == 0 {
		return fmt.Sprintf("%d Kč", minor/100)
	}
	return fmt.Sprintf("%d,%02d Kč", minor/100, minor%100)
}
