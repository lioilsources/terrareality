// Package leasing implements leases: drafting from templates, proposal and
// negotiation, electronic signatures, the payment schedule split between
// co-tenants, QR payments, bank transaction matching, a double-entry ledger
// and a hash-chained event log. The platform never receives or holds money
// (ADR 0002); payments go to the landlord's account and are only recorded.
//
// Landlord-side writes run with row-level security (db.AsUser). Tenant-side
// changes (signing, requesting changes, confirming the settlement) run in
// system context after the caller's access was checked under RLS, because
// the lease rows belong to the landlord's organization (ADR 0009).
package leasing

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/mail"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/portfolio"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

// Jobs enqueues background work in the caller's transaction.
type Jobs interface {
	StartLifecycle(ctx context.Context, tx pgx.Tx, leaseID uuid.UUID) error
}

// Service implements leases for the API (and the lifecycle activities).
type Service struct {
	Pool              *pgxpool.Pool
	Render            Renderer
	Signers           map[string]SignatureProvider
	Bank              BankProvider
	Blob              storage.Blob
	Scanner           media.Scanner // contract scans of imported leases; nil: not scanned (media.NoScanner)
	Jobs              Jobs
	Outbox            notify.Outbox
	Mail              *notify.Renderer
	Pusher            notify.Pusher // nil: no push notifications
	WebBaseURL        string
	TemplatesReviewed bool // false: documents carry a DRAFT watermark (legal review pending)
	Log               *slog.Logger
	Now               func() time.Time
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func (s *Service) asUser(ctx context.Context, p *auth.Principal, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return platformdb.AsUser(ctx, s.Pool, p.UserID, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

func (s *Service) system(ctx context.Context, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return platformdb.InTx(ctx, s.Pool, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

var errNotFound = apperr.NotFound("lease_not_found", "lease not found")

// Access describes the caller's relation to a lease.
type Access struct {
	Lease    db.Lease
	Party    *db.LeaseParty // the caller's party (tenant side or the landlord signer)
	Landlord bool           // organization member with the leases permission
}

// claim links parties invited by e-mail to the caller's account, only once
// the caller verified that e-mail (an account registered with someone
// else's address must not become a party of their lease).
func (s *Service) claim(ctx context.Context, p *auth.Principal) {
	if err := db.New(s.Pool).ClaimLeaseParties(ctx, p.UserID); err != nil {
		s.warn("claim lease parties", err)
	}
}

// access loads a lease visible to the caller (RLS) and their role in it.
func (s *Service) access(ctx context.Context, p *auth.Principal, id uuid.UUID) (Access, error) {
	s.claim(ctx, p)
	var a Access
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		l, err := q.GetLease(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			return errNotFound
		}
		if err != nil {
			return err
		}
		a.Lease = l
		if _, err := org.Access(ctx, q, p.UserID, l.OrgID, org.PermLeases); err == nil {
			a.Landlord = true
		}
		parties, err := q.ListLeaseParties(ctx, id)
		if err != nil {
			return err
		}
		for i := range parties {
			pp := parties[i]
			if (pp.UserID != nil && *pp.UserID == p.UserID && pp.Role != "landlord") || (a.Landlord && pp.Role == "landlord") {
				a.Party = &pp
				break
			}
		}
		if !a.Landlord && a.Party == nil {
			return errNotFound
		}
		return nil
	})
	return a, err
}

// appendEvent adds a hash-chained event (locks the lease row for the sequence).
func appendEvent(ctx context.Context, q *db.Queries, l db.Lease, kind string, actor *uuid.UUID, data map[string]any) (db.LeaseEvent, error) {
	if _, err := q.LockLease(ctx, l.ID); err != nil {
		return db.LeaseEvent{}, err
	}
	prev, seq := GenesisHash, int32(1)
	if last, err := q.LastLeaseEvent(ctx, l.ID); err == nil {
		prev, seq = last.Hash, last.Seq+1
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return db.LeaseEvent{}, err
	}
	payload := map[string]any{"lease_id": l.ID, "seq": seq, "kind": kind, "at": time.Now().UTC().Format(time.RFC3339Nano),
		"data": data}
	if actor != nil {
		payload["actor"] = actor.String()
	}
	canon, err := Canonical(payload)
	if err != nil {
		return db.LeaseEvent{}, err
	}
	return q.InsertLeaseEvent(ctx, db.InsertLeaseEventParams{LeaseID: l.ID, OrgID: l.OrgID, Seq: seq, Kind: kind,
		Payload: canon, PrevHash: prev, Hash: ChainHash(prev, canon)})
}

// ---------------------------------------------------------------------------
// Drafting.

// PartyInput is a tenant-side party of a new lease.
type PartyInput struct {
	Name     string
	Email    string
	Role     string // tenant | co_tenant | subtenant | guarantor
	ShareBps int
}

// Input is a lease draft.
type Input struct {
	ListingID       *uuid.UUID
	ApplicationID   *uuid.UUID
	Template        string
	StartsOn        time.Time
	EndsOn          *time.Time
	Rent            int64
	Services        int64
	Deposit         int64
	DueDay          int32
	NoticeMonths    int32
	PayeeIBAN       string
	PayeeName       string
	Clauses         []string
	PropertyAddress string
	RuianID         *int64 // optional RÚIAN address of a lease without a listing (portfolio place)
	UnitLabel       string
	Parties         []PartyInput // empty with ApplicationID: taken from the application
}

// Clauses landlords can add.
var Clauses = []string{"pets_allowed", "no_smoking", "inventory", "indexation", "sublet_forbidden", "early_termination"}

func invalid(code, msg string) error { return apperr.Unprocessable(code, msg) }

func (s *Service) validate(in *Input, depositMaxMonths int32) error {
	return validate(in, depositMaxMonths, true)
}

// validate checks a lease and its parties and fills defaults (notice
// period, equal shares). Parties of a lease made on the platform need an
// e-mail (they sign here); parties of an imported lease may have none.
func validate(in *Input, depositMaxMonths int32, needEmail bool) error {
	if !slices.Contains(Templates, in.Template) {
		return invalid("invalid_template", "unknown lease template")
	}
	switch {
	case in.Template == "byt_doba_urcita" && in.EndsOn == nil:
		return invalid("end_required", "a fixed-term lease needs an end date")
	case in.Template == "byt_doba_neurcita" && in.EndsOn != nil:
		return invalid("end_not_allowed", "an indefinite lease has no end date")
	case in.EndsOn != nil && !in.EndsOn.After(in.StartsOn):
		return invalid("invalid_term", "the lease must end after it starts")
	case in.Rent <= 0:
		return invalid("rent_required", "set the rent")
	case in.Deposit > int64(depositMaxMonths)*in.Rent:
		return invalid("deposit_too_high", fmt.Sprintf("the deposit may be at most %d months of rent", depositMaxMonths))
	case in.DueDay < 1 || in.DueDay > 28:
		return invalid("invalid_due_day", "the due day is 1 to 28")
	}
	in.PayeeIBAN = NormalizeIBAN(in.PayeeIBAN)
	if !ValidIBAN(in.PayeeIBAN) {
		return invalid("invalid_iban", "enter a valid IBAN of the landlord's account")
	}
	if strings.TrimSpace(in.PayeeName) == "" {
		return invalid("payee_required", "enter the account holder")
	}
	if in.NoticeMonths == 0 {
		in.NoticeMonths = 3
	}
	for _, c := range in.Clauses {
		if !slices.Contains(Clauses, c) {
			return invalid("invalid_clause", "unknown clause "+c)
		}
	}
	tenants := 0
	total := 0
	for i := range in.Parties {
		pp := &in.Parties[i]
		pp.Name, pp.Email = strings.TrimSpace(pp.Name), strings.ToLower(strings.TrimSpace(pp.Email))
		if pp.Name == "" || (needEmail && pp.Email == "") {
			return invalid("party_incomplete", "every tenant needs a name and an e-mail")
		}
		if !needEmail && pp.Email != "" { // the contract checks the format of API input; this is for the CSV import
			if a, err := mail.ParseAddress(pp.Email); err != nil || a.Address != pp.Email {
				return invalid("invalid_email", "enter a valid e-mail of "+pp.Name)
			}
		}
		if !slices.Contains([]string{"tenant", "co_tenant", "subtenant", "guarantor"}, pp.Role) {
			return invalid("invalid_role", "unknown party role")
		}
		if pp.Role != "guarantor" {
			tenants++
			total += pp.ShareBps
		}
	}
	if tenants == 0 {
		return invalid("tenant_required", "add at least one tenant")
	}
	if in.Template == "spolecny_najem" && tenants < 2 {
		return invalid("joint_needs_two", "a joint tenancy needs at least two tenants")
	}
	if total == 0 { // equal shares
		left := 10000
		n := tenants
		for i := range in.Parties {
			if in.Parties[i].Role != "guarantor" {
				in.Parties[i].ShareBps = left / n
				left -= in.Parties[i].ShareBps
				n--
			}
		}
	} else if total != 10000 {
		return invalid("shares_total", "payment shares must add up to 100 %")
	}
	return nil
}

func date(t *time.Time) pgtype.Date {
	if t == nil {
		return pgtype.Date{}
	}
	return pgtype.Date{Time: *t, Valid: true}
}

// Create drafts a lease (from an accepted application or with explicit parties).
func (s *Service) Create(ctx context.Context, p *auth.Principal, orgID uuid.UUID, in Input) (uuid.UUID, error) {
	sys := db.New(s.Pool)
	var juris string
	var place portfolio.Place
	var rules portfolio.Resolved
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		m, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases)
		if err != nil {
			return err
		}
		juris = m.Org.JurisdictionCode
		if in.ApplicationID != nil {
			a, err := q.GetApplication(ctx, *in.ApplicationID)
			if err != nil || a.OrgID != orgID {
				return apperr.NotFound("application_not_found", "application not found")
			}
			in.ListingID = &a.ListingID
		} else if in.ListingID != nil {
			// Published listings of other organizations are readable; a lease
			// may only refer to the organization's own listing.
			if _, err := q.GetListing(ctx, db.GetListingParams{ID: *in.ListingID, OrgID: orgID}); err != nil {
				return apperr.NotFound("listing_not_found", "listing not found")
			}
		}
		if in.ListingID != nil {
			lc, err := q.GetListingContext(ctx, *in.ListingID)
			if err != nil {
				return apperr.NotFound("listing_not_found", "listing not found")
			}
			if in.PropertyAddress == "" {
				in.PropertyAddress = lc.AddressLabel
			}
			if in.UnitLabel == "" {
				in.UnitLabel = strings.TrimSpace(strings.Join([]string{ptr(lc.Layout), lc.UnitLabel}, " "))
			}
		}
		if place, err = portfolio.Locate(ctx, q, in.ListingID, in.RuianID, in.PropertyAddress); err != nil {
			return err
		}
		rules, err = portfolio.Resolve(ctx, q, orgID, place, uuid.Nil)
		return err
	})
	if err != nil {
		return uuid.Nil, err
	}
	if in.NoticeMonths == 0 && rules.Rules.NoticeMonths != nil {
		in.NoticeMonths = int32(*rules.Rules.NoticeMonths)
	}
	if len(in.Parties) == 0 && in.ApplicationID != nil {
		people, err := sys.ApplicationPeople(ctx, *in.ApplicationID)
		if err != nil {
			return uuid.Nil, err
		}
		role := "tenant"
		if len(people) > 1 {
			role = "co_tenant"
		}
		for _, pp := range people {
			in.Parties = append(in.Parties, PartyInput{Name: pp.DisplayName, Email: pp.Email, Role: role})
		}
	}
	if strings.TrimSpace(in.PropertyAddress) == "" {
		return uuid.Nil, invalid("address_required", "enter the address of the flat")
	}
	j, err := sys.GetJurisdiction(ctx, juris)
	if err != nil {
		return uuid.Nil, err
	}
	if err := s.validate(&in, j.DepositMaxMonths); err != nil {
		return uuid.Nil, err
	}
	var id uuid.UUID
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		l, err := q.CreateLease(ctx, db.CreateLeaseParams{OrgID: orgID, ListingID: in.ListingID, ApplicationID: in.ApplicationID,
			JurisdictionCode: juris, Currency: j.Currency, Template: in.Template, TemplateVersion: TemplateVersion,
			PropertyAddress: in.PropertyAddress, UnitLabel: in.UnitLabel, StartsOn: date(&in.StartsOn), EndsOn: date(in.EndsOn),
			RentAmount: in.Rent, ServicesAmount: in.Services, DepositAmount: in.Deposit, DueDay: in.DueDay,
			NoticeMonths: in.NoticeMonths, PayeeIban: in.PayeeIBAN, PayeeName: in.PayeeName, Clauses: orEmpty(in.Clauses),
			Terms: []byte("{}"), CreatedBy: &p.UserID})
		if err != nil {
			return err
		}
		id = l.ID
		if err := portfolio.Apply(ctx, q, l, place, rules); err != nil {
			return err
		}
		if err := s.writeParties(ctx, q, l, p.UserID, in); err != nil {
			return err
		}
		if _, err := appendEvent(ctx, q, l, "created", &p.UserID, map[string]any{"template": in.Template,
			"template_version": TemplateVersion, "rent": in.Rent, "deposit": in.Deposit}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "lease", EntityID: &id, Action: "lease.create"})
	})
	return id, err
}

func ptr(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func orEmpty(s []string) []string {
	if s == nil {
		return []string{}
	}
	return s
}

func (s *Service) writeParties(ctx context.Context, q *db.Queries, l db.Lease, landlordUser uuid.UUID, in Input) error {
	if err := q.DeleteLeaseTenants(ctx, l.ID); err != nil {
		return err
	}
	parties, err := q.ListLeaseParties(ctx, l.ID)
	if err != nil {
		return err
	}
	if len(parties) == 0 {
		if _, err := q.AddLeaseParty(ctx, db.AddLeasePartyParams{LeaseID: l.ID, OrgID: l.OrgID, Role: "landlord",
			UserID: &landlordUser, Name: in.PayeeName, Position: 0}); err != nil {
			return err
		}
	}
	sys := db.New(s.Pool)
	for i, pp := range in.Parties {
		var uid *uuid.UUID
		if u, err := sys.VerifiedUserByEmail(ctx, pp.Email); err == nil { // unverified: linked on first access after verification
			uid = &u.ID
		}
		email := pp.Email
		if _, err := q.AddLeaseParty(ctx, db.AddLeasePartyParams{LeaseID: l.ID, OrgID: l.OrgID, Role: pp.Role, UserID: uid,
			Name: pp.Name, Email: &email, ShareBps: int32(pp.ShareBps), Position: int32(i + 1)}); err != nil {
			return err
		}
	}
	return nil
}

// Update edits a draft (or a lease in negotiation) and its parties.
func (s *Service) Update(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID, in Input) error {
	a, err := s.access(ctx, p, id)
	if err != nil {
		return err
	}
	if !a.Landlord || a.Lease.OrgID != orgID {
		return errNotFound
	}
	j, err := db.New(s.Pool).GetJurisdiction(ctx, a.Lease.JurisdictionCode)
	if err != nil {
		return err
	}
	if in.PropertyAddress == "" {
		in.PropertyAddress = a.Lease.PropertyAddress
	}
	if in.UnitLabel == "" {
		in.UnitLabel = a.Lease.UnitLabel
	}
	if err := s.validate(&in, j.DepositMaxMonths); err != nil {
		return err
	}
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		n, err := q.UpdateLeaseDraft(ctx, db.UpdateLeaseDraftParams{ID: id, OrgID: orgID, Template: in.Template,
			StartsOn: date(&in.StartsOn), EndsOn: date(in.EndsOn), RentAmount: in.Rent, ServicesAmount: in.Services,
			DepositAmount: in.Deposit, DueDay: in.DueDay, NoticeMonths: in.NoticeMonths, PayeeIban: in.PayeeIBAN,
			PayeeName: in.PayeeName, Clauses: orEmpty(in.Clauses), PropertyAddress: in.PropertyAddress, UnitLabel: in.UnitLabel})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("lease_locked", "only drafts and leases in negotiation can be edited")
		}
		place, err := portfolio.Locate(ctx, q, a.Lease.ListingID, in.RuianID, in.PropertyAddress)
		if err != nil {
			return err
		}
		rules, err := portfolio.Resolve(ctx, q, orgID, place, id)
		if err != nil {
			return err
		}
		if err := portfolio.Apply(ctx, q, a.Lease, place, rules); err != nil {
			return err
		}
		if err := s.writeParties(ctx, q, a.Lease, p.UserID, in); err != nil {
			return err
		}
		if _, err := appendEvent(ctx, q, a.Lease, "updated", &p.UserID, map[string]any{"rent": in.Rent, "deposit": in.Deposit,
			"template": in.Template}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "lease", EntityID: &id, Action: "lease.update"})
	})
}

// ---------------------------------------------------------------------------
// Proposal, negotiation and signatures.

func money(minor int64, currency string) string {
	whole := fmt.Sprintf("%d", minor/100)
	var b strings.Builder
	for i, r := range whole {
		if i > 0 && (len(whole)-i)%3 == 0 {
			b.WriteString(" ")
		}
		b.WriteRune(r)
	}
	if minor%100 != 0 {
		fmt.Fprintf(&b, ",%02d", minor%100)
	}
	if currency == "CZK" {
		return b.String() + " Kč"
	}
	return b.String() + " " + currency
}

func dmy(d pgtype.Date) any {
	if !d.Valid {
		return nil
	}
	return d.Time.Format("2. 1. 2006")
}

// documentData is the JSON the templates read.
func (s *Service) documentData(l db.Lease, parties []db.LeaseParty, docID string) map[string]any {
	ps := []map[string]any{}
	for _, p := range parties {
		m := map[string]any{"role": p.Role, "name": p.Name, "email": ptr((*string)(p.Email))}
		if p.Role != "landlord" && p.Role != "guarantor" {
			m["share_pct"] = float64(p.ShareBps) / 100
		}
		ps = append(ps, m)
	}
	return map[string]any{"draft": !s.TemplatesReviewed, "code": l.Code, "document_id": docID,
		"generated_at": s.now().In(prague).Format("2. 1. 2006"), "parties": ps,
		"property":  map[string]string{"address": l.PropertyAddress, "unit": l.UnitLabel},
		"starts_on": dmy(l.StartsOn), "ends_on": dmy(l.EndsOn), "rent": money(l.RentAmount, l.Currency),
		"services": money(l.ServicesAmount, l.Currency), "deposit": money(l.DepositAmount, l.Currency),
		"due_day": l.DueDay, "notice_months": l.NoticeMonths,
		"payee": map[string]string{"iban": FormatIBAN(l.PayeeIban), "name": l.PayeeName}, "clauses": l.Clauses}
}

var prague = func() *time.Location {
	l, err := time.LoadLocation("Europe/Prague")
	if err != nil {
		return time.UTC
	}
	return l
}()

// Propose renders the lease document and asks all parties to sign it.
func (s *Service) Propose(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) error {
	a, err := s.access(ctx, p, id)
	if err != nil {
		return err
	}
	if !a.Landlord || a.Lease.OrgID != orgID {
		return errNotFound
	}
	if a.Lease.State != "draft" && a.Lease.State != "negotiating" {
		return apperr.Conflict("lease_locked", "this lease was already proposed or signed")
	}
	sys := db.New(s.Pool)
	parties, err := sys.ListLeaseParties(ctx, id)
	if err != nil {
		return err
	}
	n, err := sys.CountLeaseDocuments(ctx, id)
	if err != nil {
		return err
	}
	docID := uuid.New()
	pdf, err := s.Render.Render(ctx, a.Lease.Template, s.documentData(a.Lease, parties, docID.String()[:8]))
	if err != nil {
		return err
	}
	sum := sha256.Sum256(pdf)
	key := fmt.Sprintf("leases/%s/%s.pdf", id, docID)
	if err := s.Blob.Put(ctx, key, "application/pdf", pdf); err != nil {
		return err
	}
	filename := fmt.Sprintf("smlouva-%d-v%d.pdf", a.Lease.Code, n+1)
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		doc, err := q.InsertLeaseDocument(ctx, db.InsertLeaseDocumentParams{LeaseID: id, OrgID: orgID, Kind: "final",
			Version: n + 1, ObjectKey: key, Filename: filename, Sha256: sum[:]})
		if err != nil {
			return err
		}
		for _, pp := range parties {
			if pp.Role == "guarantor" {
				continue
			}
			if _, err := q.InsertSignature(ctx, db.InsertSignatureParams{LeaseID: id, OrgID: orgID, DocumentID: doc.ID,
				PartyID: pp.ID, Provider: "mock"}); err != nil {
				return err
			}
		}
		if n, err := q.SetLeaseState(ctx, db.SetLeaseStateParams{State: "proposed", ID: id,
			FromStates: []string{"draft", "negotiating"}}); err != nil || n == 0 {
			if err == nil {
				err = apperr.Conflict("lease_locked", "this lease changed meanwhile")
			}
			return err
		}
		if _, err := appendEvent(ctx, q, a.Lease, "proposed", &p.UserID, map[string]any{"document_id": doc.ID,
			"document_sha256": hex.EncodeToString(sum[:]), "version": doc.Version}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "lease", EntityID: &id, Action: "lease.propose"})
	})
	if err != nil {
		return err
	}
	return s.notifyParties(ctx, id, "lease_proposed", false, nil)
}

// RequestChanges is a tenant's answer to a proposal: back to negotiation.
func (s *Service) RequestChanges(ctx context.Context, p *auth.Principal, id uuid.UUID, comment string) error {
	a, err := s.access(ctx, p, id)
	if err != nil {
		return err
	}
	if a.Party == nil || a.Party.Role == "landlord" {
		return apperr.Forbidden("tenant_only", "only tenants can request changes")
	}
	comment = strings.TrimSpace(comment)
	if comment == "" || len([]rune(comment)) > 2000 {
		return invalid("comment_required", "describe the changes you ask for")
	}
	err = s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		n, err := q.SetLeaseState(ctx, db.SetLeaseStateParams{State: "negotiating", ChangeRequest: &comment, ID: id,
			FromStates: []string{"proposed"}})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("lease_not_proposed", "changes can be requested only for a proposed lease")
		}
		_, err = appendEvent(ctx, q, a.Lease, "changes_requested", &p.UserID, map[string]any{"comment": comment})
		return err
	})
	if err != nil {
		return err
	}
	return s.notifyParties(ctx, id, "lease_changes_requested", true, map[string]any{"Comment": comment})
}

// Sign signs the current document as the caller's party.
func (s *Service) Sign(ctx context.Context, p *auth.Principal, id uuid.UUID, provider, ip, ua string) (SignResult, error) {
	a, err := s.access(ctx, p, id)
	if err != nil {
		return SignResult{}, err
	}
	if a.Party == nil {
		return SignResult{}, apperr.Forbidden("not_a_party", "you are not a party of this lease")
	}
	if a.Lease.State != "proposed" {
		return SignResult{}, apperr.Conflict("lease_not_proposed", "only a proposed lease can be signed")
	}
	signer, ok := s.Signers[provider]
	if !ok {
		return SignResult{}, invalid("invalid_provider", "this signature method is not available")
	}
	sys := db.New(s.Pool)
	doc, err := sys.LatestLeaseDocument(ctx, db.LatestLeaseDocumentParams{LeaseID: id, Kind: "final"})
	if err != nil {
		return SignResult{}, err
	}
	res, err := signer.Sign(ctx, SignRequest{DocumentSHA256: doc.Sha256, PartyName: a.Party.Name,
		PartyEmail: ptr((*string)(a.Party.Email)), IP: ip, UserAgent: ua})
	if err != nil || !res.Signed {
		return res, err
	}
	evidence, _ := json.Marshal(res.Evidence)
	var complete bool
	err = s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		// Re-check under the lease lock: a request for changes or a new
		// proposal may have happened since access() read the lease.
		l, err := q.GetLeaseForUpdate(ctx, id)
		if err != nil {
			return err
		}
		if l.State != "proposed" {
			return apperr.Conflict("lease_not_proposed", "only a proposed lease can be signed")
		}
		cur, err := q.LatestLeaseDocument(ctx, db.LatestLeaseDocumentParams{LeaseID: id, Kind: "final"})
		if err != nil {
			return err
		}
		if cur.ID != doc.ID {
			return apperr.Conflict("document_changed", "a new version of the lease was proposed meanwhile")
		}
		n, err := q.CompleteSignature(ctx, db.CompleteSignatureParams{DocumentID: doc.ID, PartyID: a.Party.ID,
			ExternalID: &res.ExternalID, Evidence: evidence, Provider: provider})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("already_signed", "you have already signed this document")
		}
		evSum := sha256.Sum256(evidence)
		if _, err := appendEvent(ctx, q, a.Lease, "signed", &p.UserID, map[string]any{"party_id": a.Party.ID,
			"role": a.Party.Role, "provider": provider, "document_sha256": hex.EncodeToString(doc.Sha256),
			"evidence_sha256": hex.EncodeToString(evSum[:])}); err != nil {
			return err
		}
		pending, err := q.CountPendingSignatures(ctx, doc.ID)
		if err != nil || pending > 0 {
			return err
		}
		complete = true
		return s.finalize(ctx, q, tx, l)
	})
	if err != nil {
		return SignResult{}, err
	}
	if complete {
		_ = s.notifyParties(ctx, id, "lease_signed", true, nil)
	}
	return res, nil
}

// finalize runs when the last party signed: the payment schedule and its
// ledger postings are created and the lifecycle workflow is started.
func (s *Service) finalize(ctx context.Context, q *db.Queries, tx pgx.Tx, l db.Lease) error {
	n, err := q.MarkLeaseSigned(ctx, db.MarkLeaseSignedParams{ID: l.ID, WorkflowID: ptrTo("lease-" + l.ID.String())})
	if err != nil {
		return err
	}
	if n == 0 {
		return apperr.Conflict("lease_not_proposed", "only a proposed lease can be signed")
	}
	if err := s.schedule(ctx, q, l, time.Time{}); err != nil {
		return err
	}
	if _, err := appendEvent(ctx, q, l, "fully_signed", nil, map[string]any{"code": l.Code}); err != nil {
		return err
	}
	if s.Jobs != nil {
		return s.Jobs.StartLifecycle(ctx, tx, l.ID)
	}
	return nil
}

func ptrTo[T any](v T) *T { return &v }

// shares are the paying parties of a lease (tenant side, share > 0) and
// every tenant-side party id (opening balances may be owed by any of them).
func (s *Service) shares(ctx context.Context, q *db.Queries, l db.Lease) ([]Share, []string, error) {
	parties, err := q.ListLeaseParties(ctx, l.ID)
	if err != nil {
		return nil, nil, err
	}
	var shares []Share
	var all []string
	for _, p := range parties {
		if p.Role == "landlord" {
			continue
		}
		all = append(all, p.ID.String())
		if p.Role != "guarantor" && p.ShareBps > 0 {
			shares = append(shares, Share{PartyID: p.ID.String(), ShareBps: int(p.ShareBps)})
		}
	}
	return shares, all, nil
}

func leaseTerms(l db.Lease) Terms {
	var ends *time.Time
	if l.EndsOn.Valid {
		ends = &l.EndsOn.Time
	}
	return Terms{StartsOn: l.StartsOn.Time, EndsOn: ends, Rent: l.RentAmount, Services: l.ServicesAmount,
		Deposit: l.DepositAmount, DueDay: int(l.DueDay)}
}

// schedule creates obligations, splits and their receivable postings.
func (s *Service) schedule(ctx context.Context, q *db.Queries, l db.Lease, from time.Time) error {
	shares, parties, err := s.shares(ctx, q, l)
	if err != nil {
		return err
	}
	return book(ctx, q, l, parties, Schedule(leaseTerms(l), shares, from))
}

// book writes scheduled items: the obligation, a split per party and its
// balanced receivable posting. Items already scheduled are skipped.
func book(ctx context.Context, q *db.Queries, l db.Lease, parties []string, items []Item) error {
	for _, it := range items {
		o, err := q.InsertObligation(ctx, db.InsertObligationParams{LeaseID: l.ID, OrgID: l.OrgID, Kind: it.Kind,
			Period: it.Period, DueOn: date(&it.DueOn), Amount: it.Amount, Currency: l.Currency})
		if errors.Is(err, pgx.ErrNoRows) {
			continue // already scheduled
		}
		if err != nil {
			return err
		}
		for _, id := range parties {
			amount := it.Splits[id]
			if amount == 0 {
				continue
			}
			pid := uuid.MustParse(id)
			sp, err := q.InsertSplit(ctx, db.InsertSplitParams{ObligationID: o.ID, LeaseID: l.ID, OrgID: l.OrgID, PartyID: pid, Amount: amount})
			if err != nil {
				return err
			}
			if err := post(ctx, q, l, it.DueOn, it.Kind+" "+it.Period, &sp.ID, receivableLegs(it.Kind, pid, amount)...); err != nil {
				return err
			}
		}
	}
	return nil
}

// receivableLegs is the posting of a party's share of an item: the party
// owes it (receivable) against income, or against deposit_held for a
// deposit. An opening balance is unpaid rent and services of the time
// before the cutover: income as well.
func receivableLegs(kind string, party uuid.UUID, amount int64) []leg {
	credit := "income"
	if kind == "deposit" {
		credit = "deposit_held"
	}
	return []leg{{"receivable", &party, amount}, {credit, nil, -amount}}
}

// heldDepositLegs is the posting of a deposit the landlord collected before
// the cutover of an imported lease: the money is in the landlord's account
// (cash) and owed back at the end (deposit_held); nobody owes anything.
func heldDepositLegs(amount int64) []leg {
	return []leg{{"cash", nil, amount}, {"deposit_held", nil, -amount}}
}

type leg struct {
	account string
	party   *uuid.UUID
	amount  int64
}

// post writes one balanced posting.
func post(ctx context.Context, q *db.Queries, l db.Lease, day time.Time, memo string, split *uuid.UUID, legs ...leg) error {
	var sum int64
	for _, x := range legs {
		sum += x.amount
	}
	if sum != 0 {
		return fmt.Errorf("unbalanced posting %q: %d", memo, sum)
	}
	id := uuid.New()
	for _, x := range legs {
		if err := q.InsertLedgerEntry(ctx, db.InsertLedgerEntryParams{LeaseID: l.ID, OrgID: l.OrgID, PostingID: id,
			Account: x.account, PartyID: x.party, SplitID: split, Amount: x.amount, Memo: memo, BookedOn: date(&day)}); err != nil {
			return err
		}
	}
	return nil
}

// ---------------------------------------------------------------------------
// Notifications.

// notifyParties e-mails the tenant side (and the landlord's members when
// landlord is true) about a lease and queues the same event as a push, in
// one system transaction.
func (s *Service) notifyParties(ctx context.Context, id uuid.UUID, key string, landlord bool, data map[string]any) error {
	return s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		l, err := q.GetLease(ctx, id)
		if err != nil {
			return err
		}
		if err := s.mailParties(ctx, q, tx, l, key, landlord, data); err != nil {
			return err
		}
		s.pushParties(ctx, q, tx, l, key, landlord)
		return nil
	})
}

func (s *Service) mailParties(ctx context.Context, q *db.Queries, tx pgx.Tx, l db.Lease, key string, landlord bool, data map[string]any) error {
	if s.Outbox == nil {
		return nil
	}
	id := l.ID
	parties, err := q.ListLeaseParties(ctx, id)
	if err != nil {
		return err
	}
	type rcpt struct{ email, locale, link string }
	var to []rcpt
	for _, p := range parties {
		if p.Role == "landlord" || p.Email == nil || !contactable(l.Origin, p.UserID) {
			continue
		}
		locale := "cs"
		if p.UserID != nil {
			if u, err := q.GetUser(ctx, *p.UserID); err == nil {
				locale = u.Locale
			}
		}
		to = append(to, rcpt{*p.Email, locale, s.WebBaseURL + "/smlouvy/" + id.String()})
	}
	if landlord {
		members, err := q.OrgMessagingMembers(ctx, l.OrgID)
		if err != nil {
			return err
		}
		for _, m := range members {
			to = append(to, rcpt{m.Email, m.Locale, s.WebBaseURL + "/admin/orgs/" + l.OrgID.String() + "/smlouvy/" + id.String()})
		}
	}
	for _, r := range to {
		d := map[string]any{"Code": l.Code, "VS": VariableSymbol(l), "Address": l.PropertyAddress, "Link": r.link}
		for k, v := range data {
			d[k] = v
		}
		m, err := s.Mail.Render(notify.Email, r.email, r.locale, key, d)
		if err != nil {
			return err
		}
		if err := s.Outbox.Enqueue(ctx, tx, m); err != nil {
			return err
		}
	}
	return nil
}
