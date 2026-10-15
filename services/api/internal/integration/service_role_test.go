package integration

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"net/url"
	"os"
	"slices"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

// serviceRolePool creates a temporary LOGIN role IN ROLE terra_service (what
// infra/hetzner/db/initdb/13-api-role.sh does for terra_api in production)
// and returns a pool connected as it, next to the owner pool.
func serviceRolePool(t *testing.T) (owner, svc *pgxpool.Pool) {
	t.Helper()
	owner = setup(t)
	ctx := context.Background()
	role := "terra_svc_test_" + randHex(t, 6)
	password := randHex(t, 16)
	if _, err := owner.Exec(ctx, "CREATE ROLE "+pgx.Identifier{role}.Sanitize()+
		" LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE IN ROLE terra_service PASSWORD '"+password+"'"); err != nil {
		t.Fatalf("create login role: %v", err)
	}
	u, err := url.Parse(os.Getenv("TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	u.User = url.UserPassword(role, password)
	svc, err = platformdb.Open(ctx, u.String())
	if err != nil {
		_, _ = owner.Exec(ctx, "DROP ROLE "+pgx.Identifier{role}.Sanitize())
		t.Fatalf("connect as service role: %v", err)
	}
	t.Cleanup(func() {
		svc.Close()
		if _, err := owner.Exec(context.Background(), "DROP ROLE "+pgx.Identifier{role}.Sanitize()); err != nil {
			t.Errorf("drop role %s: %v", role, err)
		}
	})
	return owner, svc
}

func randHex(t *testing.T, n int) string {
	t.Helper()
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		t.Fatal(err)
	}
	return hex.EncodeToString(b)
}

// ADR 0012 point 5: the api and worker log in as a member of terra_service.
// System code sees every org through the system_all policies, db.AsUser still
// narrows to the user's orgs, and the role cannot change the schema.
func TestServiceRole(t *testing.T) {
	owner, svc := serviceRolePool(t)
	ctx := context.Background()

	// Two users, each the owner of one company organization (written as owner).
	var users, orgs [2]uuid.UUID
	for i := range users {
		if err := owner.QueryRow(ctx, "INSERT INTO users (email, display_name) VALUES ($1, 'Svc') RETURNING id",
			"svc-"+randHex(t, 6)+"@example.test").Scan(&users[i]); err != nil {
			t.Fatal(err)
		}
		if err := owner.QueryRow(ctx, "INSERT INTO organizations (kind, name) VALUES ('company', 'Svc org') RETURNING id").
			Scan(&orgs[i]); err != nil {
			t.Fatal(err)
		}
		if _, err := owner.Exec(ctx, "INSERT INTO memberships (org_id, user_id, role) VALUES ($1, $2, 'owner')",
			orgs[i], users[i]); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		_, _ = owner.Exec(context.Background(), "DELETE FROM organizations WHERE id = ANY($1)", orgs[:])
		_, _ = owner.Exec(context.Background(), "DELETE FROM users WHERE id = ANY($1)", users[:])
	})

	t.Run("not privileged", func(t *testing.T) {
		var super, bypass bool
		if err := svc.QueryRow(ctx,
			"SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user").Scan(&super, &bypass); err != nil {
			t.Fatal(err)
		}
		if super || bypass {
			t.Fatalf("service login role has superuser=%v bypassrls=%v", super, bypass)
		}
		var isMember bool
		if err := svc.QueryRow(ctx, "SELECT pg_has_role(current_user, 'terra_service', 'USAGE')").Scan(&isMember); err != nil || !isMember {
			t.Fatalf("login role does not inherit terra_service (err=%v)", err)
		}
	})

	t.Run("system context reads across orgs", func(t *testing.T) {
		var n int
		if err := svc.QueryRow(ctx, "SELECT count(*) FROM organizations WHERE id = ANY($1)", orgs[:]).Scan(&n); err != nil {
			t.Fatal(err)
		}
		if n != 2 {
			t.Fatalf("system query sees %d of 2 organizations", n)
		}
		if err := svc.QueryRow(ctx, "SELECT count(*) FROM memberships WHERE org_id = ANY($1)", orgs[:]).Scan(&n); err != nil || n != 2 {
			t.Fatalf("system query sees %d of 2 memberships (err=%v)", n, err)
		}
		// Tables withheld from terra_app are readable in system context.
		var hash *string
		if err := svc.QueryRow(ctx, "SELECT password_hash FROM users WHERE id = $1", users[0]).Scan(&hash); err != nil {
			t.Fatalf("read users.password_hash: %v", err)
		}
		for _, q := range []string{"SELECT count(*) FROM sessions", "SELECT count(*) FROM auth_tokens"} {
			if err := svc.QueryRow(ctx, q).Scan(&n); err != nil {
				t.Fatalf("%s: %v", q, err)
			}
		}
		// Writes pass the policies' WITH CHECK.
		if _, err := svc.Exec(ctx, "UPDATE organizations SET name = 'Svc org 2' WHERE id = $1", orgs[1]); err != nil {
			t.Fatalf("system update: %v", err)
		}
	})

	t.Run("AsUser still restricts to own orgs", func(t *testing.T) {
		err := platformdb.AsUser(ctx, svc, users[0], func(tx pgx.Tx) error {
			var role string
			if err := tx.QueryRow(ctx, "SELECT current_user").Scan(&role); err != nil {
				return err
			}
			if role != "terra_app" {
				t.Errorf("AsUser runs as %s, want terra_app", role)
			}
			rows, err := tx.Query(ctx, "SELECT id FROM organizations WHERE id = ANY($1)", orgs[:])
			if err != nil {
				return err
			}
			seen, err := pgx.CollectRows(rows, pgx.RowTo[uuid.UUID])
			if err != nil {
				return err
			}
			if len(seen) != 1 || seen[0] != orgs[0] {
				t.Errorf("RLS leak through service role: user A sees %v, want only %s", seen, orgs[0])
			}
			tag, err := tx.Exec(ctx, "UPDATE organizations SET name = 'stolen' WHERE id = $1", orgs[1])
			if err != nil {
				return err
			}
			if tag.RowsAffected() != 0 {
				t.Errorf("user A updated org B")
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
		// Credentials stay out of reach inside AsUser.
		err = platformdb.AsUser(ctx, svc, users[0], func(tx pgx.Tx) error {
			_, err := tx.Exec(ctx, "SELECT count(*) FROM sessions")
			return err
		})
		if !isInsufficientPrivilege(err) {
			t.Fatalf("AsUser read sessions: err=%v, want insufficient_privilege", err)
		}
	})

	t.Run("cannot change the schema", func(t *testing.T) {
		for _, ddl := range []string{
			"CREATE TABLE svc_probe (id int)",
			"DROP TABLE organizations",
			"ALTER TABLE users ADD COLUMN svc_probe int",
			"CREATE ROLE svc_probe_role",
		} {
			_, err := svc.Exec(ctx, ddl)
			if !isInsufficientPrivilege(err) {
				t.Errorf("%s: err=%v, want insufficient_privilege", ddl, err)
			}
		}
	})

	t.Run("system paths that need more than DML", func(t *testing.T) {
		// jobs.RefreshAggregatesWorker (the role owns the view).
		if _, err := svc.Exec(ctx, "REFRESH MATERIALIZED VIEW CONCURRENTLY listing_aggregates"); err != nil {
			t.Fatalf("refresh listing_aggregates: %v", err)
		}
		// RÚIAN import empties its staging table.
		var ok bool
		if err := svc.QueryRow(ctx, "SELECT has_table_privilege('ruian_staging', 'TRUNCATE')").Scan(&ok); err != nil || !ok {
			t.Fatalf("TRUNCATE ruian_staging not granted (err=%v)", err)
		}
		// Schema version is read-only for the service.
		if err := svc.QueryRow(ctx, "SELECT has_table_privilege('goose_db_version', 'INSERT')").Scan(&ok); err != nil || ok {
			t.Fatalf("service role may write goose_db_version (err=%v)", err)
		}
	})
}

// TestServiceRolePolicies guards future migrations: every table with RLS has
// a policy for terra_service (otherwise system code silently sees no rows),
// and every application table and sequence is accessible to it.
func TestServiceRolePolicies(t *testing.T) {
	pool := setup(t)
	ctx := context.Background()

	rows, err := pool.Query(ctx, `
		SELECT c.relname,
		       EXISTS (SELECT 1 FROM pg_policy p
		               WHERE p.polrelid = c.oid AND p.polpermissive
		                 AND 'terra_service'::regrole = ANY (p.polroles)
		                 AND p.polcmd = '*')
		FROM pg_class c
		JOIN pg_namespace n ON n.oid = c.relnamespace
		WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p') AND c.relrowsecurity
		ORDER BY c.relname`)
	if err != nil {
		t.Fatal(err)
	}
	type rls struct {
		name   string
		policy bool
	}
	tables, err := pgx.CollectRows(rows, func(r pgx.CollectableRow) (rls, error) {
		var x rls
		return x, r.Scan(&x.name, &x.policy)
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(tables) < 10 {
		t.Fatalf("only %d RLS tables found; enumeration is broken", len(tables))
	}
	names := make([]string, 0, len(tables))
	for _, tb := range tables {
		names = append(names, tb.name)
		if !tb.policy {
			t.Errorf("table %s has RLS but no system_all policy for terra_service; add "+
				"`CREATE POLICY system_all ON %s TO terra_service USING (true) WITH CHECK (true)` in its migration",
				tb.name, tb.name)
		}
	}
	for _, must := range []string{"organizations", "memberships", "listings", "leases"} {
		if !slices.Contains(names, must) {
			t.Errorf("expected RLS on %s", must)
		}
	}

	rows, err = pool.Query(ctx, `
		SELECT c.relname, c.relkind::text
		FROM pg_class c
		JOIN pg_namespace n ON n.oid = c.relnamespace
		WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p', 'm', 'S')
		  AND NOT EXISTS (SELECT 1 FROM pg_depend d
		                  WHERE d.classid = 'pg_class'::regclass AND d.objid = c.oid AND d.deptype = 'e')
		  AND NOT CASE WHEN c.relkind = 'S'
		               THEN has_sequence_privilege('terra_service', c.oid, 'USAGE')
		               ELSE has_table_privilege('terra_service', c.oid, 'SELECT') END
		ORDER BY 1`)
	if err != nil {
		t.Fatal(err)
	}
	missing, err := pgx.CollectRows(rows, func(r pgx.CollectableRow) (string, error) {
		var name, kind string
		err := r.Scan(&name, &kind)
		return name + " (" + kind + ")", err
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(missing) > 0 {
		t.Errorf("terra_service lacks access to %v", missing)
	}

	t.Run("table privileges of terra_service", func(t *testing.T) {
		// Full DML on every application table except the append-only and
		// schema-owner ones (S-L4, S-F10).
		denied := map[string][]string{
			"lease_events":     {"UPDATE", "DELETE"},
			"ledger_entries":   {"UPDATE", "DELETE"},
			"stripe_events":    {"UPDATE", "DELETE"},
			"invoices":         {"UPDATE", "DELETE"},
			"orders":           {"DELETE"},
			"goose_db_version": {"INSERT", "UPDATE", "DELETE"},
		}
		for _, tb := range appTables(t, pool) {
			for _, priv := range []string{"SELECT", "INSERT", "UPDATE", "DELETE"} {
				want := !slices.Contains(denied[tb.name], priv)
				if got := tablePriv(t, pool, "terra_service", tb.name, priv); got != want {
					t.Errorf("terra_service %s on %s = %v, want %v", priv, tb.name, got, want)
				}
			}
		}
		// Invoices: only the rendered PDF and the sent stamp change.
		for col, want := range map[string]bool{"pdf_key": true, "sent_at": true, "gross_amount": false, "number": false} {
			if got := columnPriv(t, pool, "terra_service", "invoices", col, "UPDATE"); got != want {
				t.Errorf("terra_service UPDATE invoices.%s = %v, want %v", col, got, want)
			}
		}
	})

	t.Run("terra_app cannot write global tables", func(t *testing.T) {
		// V-3: tables without RLS are written in system context only. River's
		// job tables are the exception: request transactions enqueue jobs.
		n := 0
		for _, tb := range appTables(t, pool) {
			if tb.rls || strings.HasPrefix(tb.name, "river_") || tb.kind == "m" {
				continue
			}
			n++
			for _, priv := range []string{"INSERT", "UPDATE", "DELETE", "TRUNCATE"} {
				if tablePriv(t, pool, "terra_app", tb.name, priv) {
					t.Errorf("terra_app has %s on global table %s", priv, tb.name)
				}
			}
		}
		if n < 10 {
			t.Fatalf("only %d global tables checked; enumeration is broken", n)
		}
	})

	t.Run("terra_app append-only tables", func(t *testing.T) {
		// V-4 and earlier milestones: audit, consent, financial, identity and
		// message records are not changed by users.
		denied := map[string][]string{
			"audit_events":           {"UPDATE", "DELETE"},
			"consents":               {"UPDATE", "DELETE"},
			"gdpr_requests":          {"UPDATE", "DELETE"},
			"identity_verifications": {"INSERT", "UPDATE", "DELETE"},
			"invoices":               {"INSERT", "UPDATE", "DELETE"},
			"orders":                 {"UPDATE", "DELETE"},
			"lease_risk_history":     {"INSERT", "UPDATE", "DELETE"},
			"lease_events":           {"UPDATE", "DELETE"},
			"ledger_entries":         {"UPDATE", "DELETE"},
			"messages":               {"UPDATE", "DELETE"},
			"group_messages":         {"UPDATE", "DELETE"},
			"listing_versions":       {"UPDATE", "DELETE"},
			"moderation_cases":       {"UPDATE", "DELETE"},
			// Column-level UPDATE only (checked below).
			"memberships":          {"UPDATE"},
			"invitations":          {"UPDATE"},
			"conversations":        {"UPDATE"},
			"message_attachments":  {"UPDATE"},
			"application_consents": {"UPDATE"},
			"viewing_bookings":     {"UPDATE"},
		}
		for table, privs := range denied {
			for _, priv := range privs {
				if tablePriv(t, pool, "terra_app", table, priv) {
					t.Errorf("terra_app has table-level %s on %s", priv, table)
				}
			}
		}
		for _, c := range []struct {
			table, col string
			want       bool
		}{
			{"orders", "stripe_session_id", true}, {"orders", "status", false},
			{"memberships", "role", true}, {"memberships", "org_id", false}, {"memberships", "user_id", false},
			{"invitations", "revoked_at", true}, {"invitations", "role", false},
			{"application_consents", "consented_at", true}, {"application_consents", "user_id", false},
			{"viewing_bookings", "cancelled_at", true}, {"viewing_bookings", "application_id", false},
			{"conversations", "last_message_at", true}, {"conversations", "seeker_id", false},
			{"message_attachments", "av_status", true}, {"message_attachments", "uploaded_by", false},
		} {
			if got := columnPriv(t, pool, "terra_app", c.table, c.col, "UPDATE"); got != c.want {
				t.Errorf("terra_app UPDATE %s.%s = %v, want %v", c.table, c.col, got, c.want)
			}
		}
	})
}

type appTable struct {
	name, kind string
	rls        bool
}

// appTables lists tables and materialized views in public that do not
// belong to an extension.
func appTables(t *testing.T, pool *pgxpool.Pool) []appTable {
	t.Helper()
	rows, err := pool.Query(context.Background(), `
		SELECT c.relname, c.relkind::text, c.relrowsecurity
		FROM pg_class c
		JOIN pg_namespace n ON n.oid = c.relnamespace
		WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p', 'm')
		  AND NOT EXISTS (SELECT 1 FROM pg_depend d
		                  WHERE d.classid = 'pg_class'::regclass AND d.objid = c.oid AND d.deptype = 'e')
		ORDER BY 1`)
	if err != nil {
		t.Fatal(err)
	}
	out, err := pgx.CollectRows(rows, func(r pgx.CollectableRow) (appTable, error) {
		var x appTable
		return x, r.Scan(&x.name, &x.kind, &x.rls)
	})
	if err != nil {
		t.Fatal(err)
	}
	return out
}

func tablePriv(t *testing.T, pool *pgxpool.Pool, role, table, priv string) bool {
	t.Helper()
	var ok bool
	if err := pool.QueryRow(context.Background(), "SELECT has_table_privilege($1, $2::regclass, $3)",
		role, "public."+table, priv).Scan(&ok); err != nil {
		t.Fatalf("has_table_privilege(%s, %s, %s): %v", role, table, priv, err)
	}
	return ok
}

func columnPriv(t *testing.T, pool *pgxpool.Pool, role, table, col, priv string) bool {
	t.Helper()
	var ok bool
	if err := pool.QueryRow(context.Background(), "SELECT has_column_privilege($1, $2::regclass, $3, $4)",
		role, "public."+table, col, priv).Scan(&ok); err != nil {
		t.Fatalf("has_column_privilege(%s, %s.%s, %s): %v", role, table, col, priv, err)
	}
	return ok
}

func isInsufficientPrivilege(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "42501"
}
