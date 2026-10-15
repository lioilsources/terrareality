package integration

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

// rlsFixture builds rows as the schema owner and removes them afterwards.
type rlsFixture struct {
	t      *testing.T
	pool   *pgxpool.Pool
	users  []uuid.UUID
	orgs   []uuid.UUID
	groups []uuid.UUID
}

func (f *rlsFixture) one(sql string, args ...any) uuid.UUID {
	f.t.Helper()
	var id uuid.UUID
	if err := f.pool.QueryRow(context.Background(), sql, args...).Scan(&id); err != nil {
		f.t.Fatalf("%s: %v", sql, err)
	}
	return id
}

func (f *rlsFixture) exec(sql string, args ...any) {
	f.t.Helper()
	if _, err := f.pool.Exec(context.Background(), sql, args...); err != nil {
		f.t.Fatalf("%s: %v", sql, err)
	}
}

func (f *rlsFixture) user(verified bool) (uuid.UUID, string) {
	f.t.Helper()
	email := "rls-" + randHex(f.t, 6) + "@example.test"
	id := f.one(`INSERT INTO users (email, display_name, email_verified_at)
		VALUES ($1, 'Rls', CASE WHEN $2::bool THEN now() END) RETURNING id`, email, verified)
	f.users = append(f.users, id)
	return id, email
}

func (f *rlsFixture) org(name string, members map[uuid.UUID]string) uuid.UUID {
	f.t.Helper()
	id := f.one("INSERT INTO organizations (kind, name) VALUES ('company', $1) RETURNING id", name)
	f.orgs = append(f.orgs, id)
	for u, role := range members {
		f.exec("INSERT INTO memberships (org_id, user_id, role) VALUES ($1, $2, $3)", id, u, role)
	}
	return id
}

func (f *rlsFixture) cleanup() {
	ctx := context.Background()
	_, _ = f.pool.Exec(ctx, "DELETE FROM organizations WHERE id = ANY($1)", f.orgs)
	_, _ = f.pool.Exec(ctx, "DELETE FROM tenant_groups WHERE id = ANY($1)", f.groups)
	_, _ = f.pool.Exec(ctx, "DELETE FROM users WHERE id = ANY($1)", f.users)
}

// execAs runs one statement under db.AsUser and returns the affected rows.
func execAs(pool *pgxpool.Pool, user uuid.UUID, sql string, args ...any) (int64, error) {
	ctx := context.Background()
	var n int64
	err := platformdb.AsUser(ctx, pool, user, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, sql, args...)
		n = tag.RowsAffected()
		return err
	})
	return n, err
}

// scanAs runs one query under db.AsUser and scans its single row.
func scanAs(t *testing.T, pool *pgxpool.Pool, user uuid.UUID, dest any, sql string, args ...any) {
	t.Helper()
	ctx := context.Background()
	if err := platformdb.AsUser(ctx, pool, user, func(tx pgx.Tx) error {
		return tx.QueryRow(ctx, sql, args...).Scan(dest)
	}); err != nil {
		t.Fatalf("%s: %v", sql, err)
	}
}

// wantRows expects a statement to succeed with n affected rows.
func wantRows(t *testing.T, what string, want int64, n int64, err error) {
	t.Helper()
	if err != nil || n != want {
		t.Errorf("%s: %d rows, err=%v; want %d rows", what, n, err, want)
	}
}

// wantDenied expects a policy (WITH CHECK) or privilege error.
func wantDenied(t *testing.T, what string, err error) {
	t.Helper()
	if !isInsufficientPrivilege(err) {
		t.Errorf("%s: err=%v, want insufficient_privilege (42501)", what, err)
	}
}

// Review B-2, S-F5, S-F6, S-F11, V-3 and the invitation guard: the policies
// themselves enforce who may write which rows (migration 00013).
func TestRLSHardening(t *testing.T) {
	pool := setup(t)
	f := &rlsFixture{t: t, pool: pool}
	t.Cleanup(f.cleanup)

	owner, _ := f.user(true)
	admin, _ := f.user(true)
	viewer, _ := f.user(true)
	agent, _ := f.user(true)
	org := f.org("Rls org", map[uuid.UUID]string{owner: "owner", admin: "admin", viewer: "viewer", agent: "agent"})

	t.Run("memberships follow the role matrix", func(t *testing.T) {
		n, err := execAs(pool, viewer, "UPDATE memberships SET role = 'owner' WHERE org_id = $1 AND user_id = $2", org, viewer)
		wantRows(t, "viewer promotes self", 0, n, err)
		n, err = execAs(pool, admin, "UPDATE memberships SET role = 'viewer' WHERE org_id = $1 AND user_id = $2", org, agent)
		wantRows(t, "admin demotes agent", 1, n, err)
		_, err = execAs(pool, admin, "UPDATE memberships SET role = 'owner' WHERE org_id = $1 AND user_id = $2", org, agent)
		wantDenied(t, "admin grants ownership", err)
		n, err = execAs(pool, admin, "DELETE FROM memberships WHERE org_id = $1 AND user_id = $2", org, owner)
		wantRows(t, "admin removes owner", 0, n, err)
		n, err = execAs(pool, owner, "UPDATE memberships SET role = 'agent' WHERE org_id = $1 AND user_id = $2", org, agent)
		wantRows(t, "owner changes a role", 1, n, err)
		_, err = execAs(pool, viewer, "UPDATE memberships SET org_id = org_id WHERE org_id = $1", org)
		wantDenied(t, "column outside the grant", err)
		_, err = execAs(pool, owner, "INSERT INTO memberships (org_id, user_id, role) VALUES ($1, $2, 'viewer')", org, uuid.New())
		wantDenied(t, "insert under RLS", err)
		n, err = execAs(pool, viewer, "DELETE FROM memberships WHERE org_id = $1 AND user_id = $2", org, viewer)
		wantRows(t, "viewer leaves", 1, n, err)
	})

	t.Run("invitations: owners and admins, never owner role", func(t *testing.T) {
		ins := `INSERT INTO invitations (org_id, email, role, token_hash, expires_at)
			VALUES ($1, $2, $3, gen_random_bytes(32), now() + interval '1 day')`
		_, err := execAs(pool, admin, ins, org, "rls-inv-"+randHex(t, 4)+"@example.test", "owner")
		wantDenied(t, "admin invites an owner", err)
		_, err = execAs(pool, agent, ins, org, "rls-inv-"+randHex(t, 4)+"@example.test", "viewer")
		wantDenied(t, "agent invites", err)
		n, err := execAs(pool, admin, ins, org, "rls-inv-"+randHex(t, 4)+"@example.test", "viewer")
		wantRows(t, "admin invites a viewer", 1, n, err)
	})

	t.Run("group invitations need a verified e-mail", func(t *testing.T) {
		creator, creatorEmail := f.user(true)
		invitee, inviteeEmail := f.user(false)
		group := f.one("INSERT INTO tenant_groups (name, created_by) VALUES ('Rls group', $1) RETURNING id", creator)
		f.groups = append(f.groups, group)
		f.exec(`INSERT INTO group_members (group_id, user_id, invited_email, role, joined_at)
			VALUES ($1, $2, $3, 'admin', now())`, group, creator, creatorEmail)
		f.exec("INSERT INTO group_members (group_id, invited_email) VALUES ($1, $2)", group, inviteeEmail)

		var seen int
		scanAs(t, pool, invitee, &seen, "SELECT count(*) FROM tenant_groups WHERE id = $1", group)
		if seen != 0 {
			t.Errorf("unverified invitee sees the group")
		}
		scanAs(t, pool, invitee, &seen, "SELECT count(*) FROM group_members WHERE group_id = $1", group)
		if seen != 0 {
			t.Errorf("unverified invitee sees %d members", seen)
		}
		join := `UPDATE group_members SET user_id = $1, joined_at = now()
			WHERE group_id = $2 AND invited_email = $3 AND user_id IS NULL`
		n, err := execAs(pool, invitee, join, invitee, group, inviteeEmail)
		wantRows(t, "unverified invitee joins", 0, n, err)

		f.exec("UPDATE users SET email_verified_at = now() WHERE id = $1", invitee)
		scanAs(t, pool, invitee, &seen, "SELECT count(*) FROM tenant_groups WHERE id = $1", group)
		if seen != 1 {
			t.Errorf("verified invitee does not see the group")
		}
		n, err = execAs(pool, invitee, join, invitee, group, inviteeEmail)
		wantRows(t, "verified invitee joins", 1, n, err)

		_, err = execAs(pool, invitee, "UPDATE group_members SET role = 'admin' WHERE group_id = $1 AND user_id = $2", group, invitee)
		wantDenied(t, "member promotes self", err)
		_, err = execAs(pool, invitee, "UPDATE group_members SET user_id = $1 WHERE group_id = $2 AND user_id = $3", invitee, group, creator)
		wantDenied(t, "member takes over another member", err)

		var name *string
		scanAs(t, pool, viewer, &name, "SELECT group_display_name($1)", group)
		if name != nil {
			t.Errorf("unrelated user reads group name %q", *name)
		}
		scanAs(t, pool, invitee, &name, "SELECT group_display_name($1)", group)
		if name == nil || *name != "Rls group" {
			t.Errorf("member reads group name %v", name)
		}
	})

	// Landlord organization with a listing and a lease.
	landlord, _ := f.user(true)
	tenant, tenantEmail := f.user(true)
	applicant, _ := f.user(true)
	other, _ := f.user(true)
	lorg := f.org("Rls landlord", map[uuid.UUID]string{landlord: "owner"})
	addr := f.one(`INSERT INTO addresses (org_id, house_number, city, postal_code, location, label)
		VALUES ($1, '1', 'Praha', '11000', ST_SetSRID(ST_MakePoint(14.42, 50.08), 4326)::geography, 'Rls 1, Praha')
		RETURNING id`, lorg)
	prop := f.one("INSERT INTO properties (org_id, address_id, kind, name) VALUES ($1, $2, 'other', 'Rls') RETURNING id", lorg, addr)
	unit := f.one("INSERT INTO units (org_id, property_id, kind, label) VALUES ($1, $2, 'apartment', 'Rls') RETURNING id", lorg, prop)
	listing := f.one("INSERT INTO listings (org_id, unit_id) VALUES ($1, $2) RETURNING id", lorg, unit)
	lease := f.one(`INSERT INTO leases (org_id, jurisdiction_code, currency, template, template_version, property_address,
		starts_on, rent_amount, payee_iban, payee_name)
		VALUES ($1, 'CZ', 'CZK', 'byt_doba_neurcita', '1', 'Rls 1, Praha', '2026-01-01', 1500000, 'CZ6508000000192000145399', 'Rls')
		RETURNING id`, lorg)
	f.exec(`INSERT INTO lease_parties (lease_id, org_id, role, user_id, name, email, share_bps, position)
		VALUES ($1, $2, 'tenant', $3, 'Tenant', $4, 10000, 1)`, lease, lorg, tenant, tenantEmail)

	t.Run("lease parties read, the organization writes", func(t *testing.T) {
		var seen int
		scanAs(t, pool, tenant, &seen, "SELECT count(*) FROM lease_parties WHERE lease_id = $1", lease)
		if seen != 1 {
			t.Errorf("tenant sees %d parties", seen)
		}
		n, err := execAs(pool, tenant, "UPDATE lease_parties SET share_bps = 0 WHERE lease_id = $1", lease)
		wantRows(t, "tenant changes the share", 0, n, err)
		_, err = execAs(pool, tenant, `INSERT INTO lease_parties (lease_id, org_id, role, name, position)
			VALUES ($1, $2, 'co_tenant', 'X', 9)`, lease, lorg)
		wantDenied(t, "tenant adds a party", err)
		n, err = execAs(pool, landlord, "UPDATE lease_parties SET share_bps = 10000 WHERE lease_id = $1", lease)
		wantRows(t, "landlord changes the share", 1, n, err)
	})

	t.Run("organization names only for related callers", func(t *testing.T) {
		var name *string
		scanAs(t, pool, tenant, &name, "SELECT org_display_name($1)", lorg)
		if name == nil || *name != "Rls landlord" {
			t.Errorf("lease party reads org name %v", name)
		}
		scanAs(t, pool, other, &name, "SELECT org_display_name($1)", lorg)
		if name != nil {
			t.Errorf("unrelated user reads org name %q", *name)
		}
	})

	t.Run("applicants cannot decide their application", func(t *testing.T) {
		ins := `INSERT INTO applications (listing_id, org_id, applicant_id, status) VALUES ($1, $2, $3, $4)`
		_, err := execAs(pool, applicant, ins, listing, lorg, applicant, "accepted")
		wantDenied(t, "insert accepted", err)
		_, err = execAs(pool, applicant, ins, listing, lorg, other, "submitted")
		wantDenied(t, "insert for someone else", err)
		n, err := execAs(pool, applicant, ins, listing, lorg, applicant, "submitted")
		wantRows(t, "insert submitted", 1, n, err)
		app := f.one("SELECT id FROM applications WHERE listing_id = $1 AND applicant_id = $2", listing, applicant)

		_, err = execAs(pool, applicant, "UPDATE applications SET status = 'accepted' WHERE id = $1", app)
		wantDenied(t, "applicant accepts", err)
		n, err = execAs(pool, landlord, "UPDATE applications SET status = 'invited' WHERE id = $1", app)
		wantRows(t, "landlord invites", 1, n, err)

		cons := "INSERT INTO application_consents (application_id, user_id, consented_at) VALUES ($1, $2, $3)"
		_, err = execAs(pool, applicant, cons, app, other, time.Now())
		wantDenied(t, "consent on behalf of another", err)
		n, err = execAs(pool, applicant, cons, app, other, nil)
		wantRows(t, "pending consent row", 1, n, err)
		n, err = execAs(pool, landlord, "UPDATE application_consents SET consented_at = now() WHERE application_id = $1", app)
		wantRows(t, "landlord consents for the applicant", 0, n, err)
	})

	t.Run("listing_search writes stay within the organization", func(t *testing.T) {
		ins := `INSERT INTO listing_search (listing_id, org_id, version, unit_kind, rent_amount, currency, title,
			location, city, tsv, published_at)
			VALUES ($1, $2, 1, 'apartment', 1500000, 'CZK', '{}',
			ST_SetSRID(ST_MakePoint(14.42, 50.08), 4326)::geography, 'Praha', ''::tsvector, now())`
		_, err := execAs(pool, owner, ins, listing, lorg)
		wantDenied(t, "foreign org indexes a listing", err)
		n, err := execAs(pool, landlord, ins, listing, lorg)
		wantRows(t, "own listing indexed", 1, n, err)
		var seen int
		scanAs(t, pool, other, &seen, "SELECT count(*) FROM listing_search WHERE listing_id = $1", listing)
		if seen != 1 {
			t.Errorf("public index row not readable: %d", seen)
		}
		n, err = execAs(pool, owner, "DELETE FROM listing_search WHERE listing_id = $1", listing)
		wantRows(t, "foreign org removes a listing", 0, n, err)
		_, err = execAs(pool, owner, "UPDATE filter_schemas SET position = position")
		wantDenied(t, "app role writes a global table", err)
	})
}
