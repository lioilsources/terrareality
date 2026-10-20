package leasing

// Existing leases (M9). A landlord joining the platform brings flats that
// are already rented on paper contracts. Such a lease is imported straight
// into its running state: no proposal, no rendered document (so no DRAFT
// watermark) and no signatures, because it was signed outside the platform;
// the hash-chained log records that with an "imported" event.
//
// The platform tracks payments from the cutover date on. Nothing before it
// is scheduled (no past months turn into debt, reminders, escalations or
// risk); what the tenants owed at the cutover is one opening-balance
// obligation due on the cutover day, and a deposit the landlord already
// holds is booked without a receivable. Existing tenants keep paying with
// the variable symbol of their standing order (leases.variable_symbol).
//
// Tenants of a paper contract never agreed to hear from the platform: they
// get no e-mail or push until the landlord invites them (InviteParty) and
// they sign in with the invited address (contactable, ClaimLeaseParties).

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"net/http"
	"net/mail"
	"path"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

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

// Lease origins.
const (
	OriginPlatform = "platform" // drafted, proposed and signed here
	OriginImported = "imported" // signed on paper before the landlord joined
)

// Cutover window: the cutover may lie at most CutoverBackDays in the past
// (an import late in the month still tracks the month's payment from its
// first day) and at most CutoverAheadMonths in the future. It is never
// before the start of the lease nor after its end. Default: the first day
// of the next month (or the start date, when the lease starts later).
const (
	CutoverBackDays    = 31
	CutoverAheadMonths = 12
)

// VariableSymbol is the symbol a lease's payments carry: the tenants'
// existing symbol of an imported lease when set, else the lease code.
func VariableSymbol(l db.Lease) string {
	if l.VariableSymbol != nil && *l.VariableSymbol != "" {
		return *l.VariableSymbol
	}
	return strconv.FormatInt(l.Code, 10)
}

// NormalizeVS returns a Czech variable symbol (1 to 10 digits) without
// spaces and leading zeros, which banks drop; "" when s is not one.
func NormalizeVS(s string) string {
	s = strings.Join(strings.Fields(s), "")
	if s == "" || len(s) > 10 {
		return ""
	}
	for _, r := range s {
		if r < '0' || r > '9' {
			return ""
		}
	}
	return strings.TrimLeft(s, "0")
}

// ImportParty is a tenant-side party of an imported lease. The e-mail is
// optional; nobody is contacted at import.
type ImportParty struct {
	PartyInput
	OpeningBalance int64 // owed at the cutover, minor units (0: nothing)
}

// ImportInput is a lease signed outside the platform.
type ImportInput struct {
	Lease          Input // terms, place and payee; Lease.Parties and Lease.Clauses are ignored
	Parties        []ImportParty
	CutoverOn      *time.Time // nil: DefaultCutover
	DepositHeld    bool       // the landlord holds the deposit already
	VariableSymbol string     // the tenants' existing symbol ("" = the lease code)
}

// DefaultCutover is the first day of the month after today, or the start
// date when the lease starts later.
func DefaultCutover(today, startsOn time.Time) time.Time {
	c := time.Date(today.Year(), today.Month(), 1, 0, 0, 0, 0, time.UTC).AddDate(0, 1, 0)
	if s := day(startsOn); s.After(c) {
		return s
	}
	return c
}

// ValidateImport checks an imported lease without the database and fills
// defaults (cutover, notice period, equal shares, normalized symbol and
// IBAN). today is the Prague calendar day.
func ValidateImport(in *ImportInput, depositMaxMonths int32, today time.Time) error {
	today = day(today)
	in.Lease.Clauses = nil // the paper contract has its own clauses
	in.Lease.Parties = nil
	for _, p := range in.Parties {
		in.Lease.Parties = append(in.Lease.Parties, p.PartyInput)
	}
	in.Lease.PropertyAddress = strings.TrimSpace(in.Lease.PropertyAddress)
	if in.Lease.PropertyAddress == "" {
		return invalid("address_required", "enter the address of the flat")
	}
	if len(in.Parties) == 0 {
		return invalid("tenant_required", "add at least one tenant")
	}
	if err := validate(&in.Lease, depositMaxMonths, false); err != nil {
		return err
	}
	for i := range in.Parties { // normalized names, e-mails and shares
		in.Parties[i].PartyInput = in.Lease.Parties[i]
		switch {
		case in.Parties[i].OpeningBalance < 0:
			return invalid("invalid_opening_balance", "an opening balance is what a tenant owes: zero or more")
		case in.Parties[i].OpeningBalance > 0 && in.Parties[i].Role == "guarantor":
			return invalid("opening_balance_guarantor", "an opening balance belongs to a tenant, not a guarantor")
		}
	}
	in.Lease.StartsOn = day(in.Lease.StartsOn)
	if in.Lease.EndsOn != nil {
		e := day(*in.Lease.EndsOn)
		in.Lease.EndsOn = &e
		if e.Before(today) {
			return invalid("lease_ended", "this lease has already ended")
		}
	}
	cut := DefaultCutover(today, in.Lease.StartsOn)
	if in.CutoverOn != nil {
		cut = day(*in.CutoverOn)
	}
	in.CutoverOn = &cut
	switch {
	case cut.Before(in.Lease.StartsOn):
		return invalid("cutover_before_start", "the platform cannot track payments before the lease starts")
	case cut.Before(today.AddDate(0, 0, -CutoverBackDays)):
		return invalid("cutover_too_old", fmt.Sprintf("the cutover may lie at most %d days in the past; put older debt into the opening balance", CutoverBackDays))
	case cut.After(today.AddDate(0, CutoverAheadMonths, 0)):
		return invalid("cutover_too_far", fmt.Sprintf("the cutover may lie at most %d months ahead", CutoverAheadMonths))
	case in.Lease.EndsOn != nil && cut.After(*in.Lease.EndsOn):
		return invalid("cutover_after_end", "the cutover must be before the lease ends")
	}
	if in.VariableSymbol != "" {
		vs := NormalizeVS(in.VariableSymbol)
		if vs == "" {
			return invalid("invalid_variable_symbol", "a variable symbol has 1 to 10 digits")
		}
		in.VariableSymbol = vs
	}
	if in.Lease.Deposit == 0 {
		in.DepositHeld = false
	}
	return nil
}

func errSymbolTaken(vs string) error {
	return apperr.Conflict("variable_symbol_taken", "another lease of the organization already uses variable symbol "+vs)
}

// Import creates a lease signed outside the platform, directly signed or
// active, with its schedule from the cutover on, and starts its lifecycle.
func (s *Service) Import(ctx context.Context, p *auth.Principal, orgID uuid.UUID, in ImportInput) (uuid.UUID, error) {
	var id uuid.UUID
	err := s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		m, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases)
		if err != nil {
			return err
		}
		id, err = s.importLease(ctx, q, tx, m.Org.JurisdictionCode, orgID, &p.UserID, &p.UserID, in, "api")
		return err
	})
	return id, err
}

// Imported is one lease created by ImportBatch.
type Imported struct {
	Ref   string
	ID    uuid.UUID
	Code  int64
	State string
}

// errDryRun rolls a dry-run batch back.
var errDryRun = errors.New("dry run")

// ImportBatch imports leases for an organization in one system transaction
// (terractl leases import, concierge onboarding): all or nothing. The
// landlord party is linked to onBehalfOf (the organization's owner; nil
// while the owner has not accepted the invitation yet); events and the
// audit record name no user actor and say the operator imported them. A
// dry run does everything, then rolls back.
func (s *Service) ImportBatch(ctx context.Context, orgID uuid.UUID, onBehalfOf *uuid.UUID, leases []ParsedLease, dryRun bool) ([]Imported, error) {
	o, err := db.New(s.Pool).GetOrganization(ctx, orgID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperr.NotFound("org_not_found", "organization not found")
	}
	if err != nil {
		return nil, err
	}
	run := *s
	if dryRun {
		run.Jobs = nil // nothing to start for leases that are rolled back
	}
	var out []Imported
	err = s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		for _, pl := range leases {
			id, err := run.importLease(ctx, q, tx, o.JurisdictionCode, orgID, onBehalfOf, nil, pl.Input, "terractl")
			if err != nil {
				return fmt.Errorf("lease %s (lines %s): %w", pl.Ref, joinInts(pl.Lines), err)
			}
			l, err := q.GetLease(ctx, id)
			if err != nil {
				return err
			}
			out = append(out, Imported{Ref: pl.Ref, ID: id, Code: l.Code, State: l.State})
		}
		if dryRun {
			return errDryRun
		}
		return nil
	})
	if errors.Is(err, errDryRun) {
		err = nil
	}
	if err != nil {
		return nil, err
	}
	return out, nil
}

func joinInts(xs []int) string {
	parts := make([]string, len(xs))
	for i, x := range xs {
		parts[i] = strconv.Itoa(x)
	}
	return strings.Join(parts, ", ")
}

// importLease creates an imported lease in tx (RLS for the API, system
// context for terractl). landlordUser is the account of the landlord party,
// actor the user recorded in the event log (nil: the operator).
func (s *Service) importLease(ctx context.Context, q *db.Queries, tx pgx.Tx, juris string, orgID uuid.UUID,
	landlordUser, actor *uuid.UUID, in ImportInput, source string) (uuid.UUID, error) {
	sys := db.New(s.Pool)
	j, err := sys.GetJurisdiction(ctx, juris)
	if err != nil {
		return uuid.Nil, err
	}
	if in.Lease.ListingID != nil {
		// Only the organization's own listing (published listings of others are readable).
		if _, err := q.GetListing(ctx, db.GetListingParams{ID: *in.Lease.ListingID, OrgID: orgID}); err != nil {
			return uuid.Nil, apperr.NotFound("listing_not_found", "listing not found")
		}
		lc, err := q.GetListingContext(ctx, *in.Lease.ListingID)
		if err != nil {
			return uuid.Nil, apperr.NotFound("listing_not_found", "listing not found")
		}
		if strings.TrimSpace(in.Lease.PropertyAddress) == "" {
			in.Lease.PropertyAddress = lc.AddressLabel
		}
		if in.Lease.UnitLabel == "" {
			in.Lease.UnitLabel = strings.TrimSpace(strings.Join([]string{ptr(lc.Layout), lc.UnitLabel}, " "))
		}
	}
	place, err := portfolio.Locate(ctx, q, in.Lease.ListingID, in.Lease.RuianID, in.Lease.PropertyAddress)
	if err != nil {
		return uuid.Nil, err
	}
	rules, err := portfolio.Resolve(ctx, q, orgID, place, uuid.Nil)
	if err != nil {
		return uuid.Nil, err
	}
	if in.Lease.NoticeMonths == 0 && rules.Rules.NoticeMonths != nil {
		in.Lease.NoticeMonths = int32(*rules.Rules.NoticeMonths)
	}
	today := day(s.now().In(prague))
	if err := ValidateImport(&in, j.DepositMaxMonths, today); err != nil {
		return uuid.Nil, err
	}
	var vs *string
	if in.VariableSymbol != "" {
		taken, err := q.VariableSymbolTaken(ctx, db.VariableSymbolTakenParams{OrgID: orgID, Symbol: in.VariableSymbol})
		if err != nil {
			return uuid.Nil, err
		}
		if taken {
			return uuid.Nil, errSymbolTaken(in.VariableSymbol)
		}
		vs = &in.VariableSymbol
	}
	// A lease that has started runs; one starting later is signed and the
	// lifecycle workflow activates it on the start date.
	state := "active"
	if in.Lease.StartsOn.After(today) {
		state = "signed"
	}
	cut := *in.CutoverOn
	l, err := q.ImportLease(ctx, db.ImportLeaseParams{OrgID: orgID, ListingID: in.Lease.ListingID, JurisdictionCode: juris,
		Currency: j.Currency, State: state, Template: in.Lease.Template, TemplateVersion: TemplateVersion,
		PropertyAddress: in.Lease.PropertyAddress, UnitLabel: in.Lease.UnitLabel, StartsOn: date(&in.Lease.StartsOn),
		EndsOn: date(in.Lease.EndsOn), RentAmount: in.Lease.Rent, ServicesAmount: in.Lease.Services,
		DepositAmount: in.Lease.Deposit, DueDay: in.Lease.DueDay, NoticeMonths: in.Lease.NoticeMonths,
		PayeeIban: in.Lease.PayeeIBAN, PayeeName: in.Lease.PayeeName, CreatedBy: actor, CutoverOn: date(&cut),
		VariableSymbol: vs, DepositHeld: in.DepositHeld})
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.ConstraintName == "leases_org_variable_symbol" {
		return uuid.Nil, errSymbolTaken(in.VariableSymbol)
	}
	if err != nil {
		return uuid.Nil, err
	}
	if err := q.SetLeaseWorkflow(ctx, db.SetLeaseWorkflowParams{ID: l.ID, WorkflowID: ptrTo("lease-" + l.ID.String())}); err != nil {
		return uuid.Nil, err
	}
	if err := portfolio.Apply(ctx, q, l, place, rules); err != nil {
		return uuid.Nil, err
	}
	if _, err := q.AddLeaseParty(ctx, db.AddLeasePartyParams{LeaseID: l.ID, OrgID: orgID, Role: "landlord",
		UserID: landlordUser, Name: in.Lease.PayeeName, Position: 0}); err != nil {
		return uuid.Nil, err
	}
	opening := map[string]int64{}
	var openingTotal int64
	for i, pp := range in.Parties {
		var email *string
		if pp.Email != "" {
			e := pp.Email
			email = &e
		}
		party, err := q.AddImportedParty(ctx, db.AddImportedPartyParams{LeaseID: l.ID, OrgID: orgID, Role: pp.Role,
			Name: pp.Name, Email: email, ShareBps: int32(pp.ShareBps), Position: int32(i + 1)})
		if err != nil {
			return uuid.Nil, err
		}
		if pp.OpeningBalance > 0 {
			opening[party.ID.String()] = pp.OpeningBalance
			openingTotal += pp.OpeningBalance
		}
	}
	shares, parties, err := s.shares(ctx, q, l)
	if err != nil {
		return uuid.Nil, err
	}
	items := ImportSchedule(leaseTerms(l), shares, Cutover{On: cut, DepositHeld: in.DepositHeld, Opening: opening})
	if err := book(ctx, q, l, parties, items); err != nil {
		return uuid.Nil, err
	}
	if in.DepositHeld {
		if err := post(ctx, q, l, cut, "deposit held before cutover", nil, heldDepositLegs(l.DepositAmount)...); err != nil {
			return uuid.Nil, err
		}
	}
	data := map[string]any{"signed_outside_platform": true, "source": source, "template": in.Lease.Template,
		"starts_on": in.Lease.StartsOn.Format("2006-01-02"), "cutover_on": cut.Format("2006-01-02"), "rent": in.Lease.Rent,
		"services": in.Lease.Services, "deposit": in.Lease.Deposit, "deposit_held": in.DepositHeld,
		"opening_balance": openingTotal, "variable_symbol": VariableSymbol(l)}
	if actor == nil && landlordUser != nil {
		data["on_behalf_of"] = landlordUser.String()
	}
	if _, err := appendEvent(ctx, q, l, "imported", actor, data); err != nil {
		return uuid.Nil, err
	}
	if err := audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "lease", EntityID: &l.ID, Action: "lease.import",
		ActorID: actor, Diff: map[string]any{"source": source, "cutover_on": cut.Format("2006-01-02"),
			"opening_balance": openingTotal, "deposit_held": in.DepositHeld}}); err != nil {
		return uuid.Nil, err
	}
	// The lifecycle job is system work (the job queue is not an RLS table),
	// enqueued in this transaction like finalize does after the signatures.
	if err := platformdb.Elevate(ctx, tx); err != nil {
		return uuid.Nil, err
	}
	if s.Jobs != nil {
		if err := s.Jobs.StartLifecycle(ctx, tx, l.ID); err != nil {
			return uuid.Nil, err
		}
	}
	return l.ID, nil
}

// ---------------------------------------------------------------------------
// Inviting tenants of an imported lease.

// InviteParty invites a tenant-side party of an imported lease to the
// tenant portal: it stores the (corrected) e-mail, marks the party invited
// and e-mails the link. The party is linked to an account only when its
// holder signs in with this verified address (ClaimLeaseParties); until
// then the tenant gets no reminders.
func (s *Service) InviteParty(ctx context.Context, p *auth.Principal, orgID, leaseID, partyID uuid.UUID, email string) error {
	a, err := s.access(ctx, p, leaseID)
	if err != nil {
		return err
	}
	if !a.Landlord || a.Lease.OrgID != orgID {
		return errNotFound
	}
	if a.Lease.Origin != OriginImported {
		return apperr.Conflict("lease_not_imported", "tenants of a lease made here are invited by the proposal")
	}
	if !Running(a.Lease.State) {
		return apperr.Conflict("lease_not_active", "only tenants of a running lease can be invited")
	}
	return s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		parties, err := q.ListLeaseParties(ctx, leaseID)
		if err != nil {
			return err
		}
		var party *db.LeaseParty
		for i := range parties {
			if parties[i].ID == partyID && parties[i].Role != "landlord" {
				party = &parties[i]
			}
		}
		if party == nil {
			return apperr.NotFound("party_not_found", "party not found")
		}
		if party.UserID != nil {
			return apperr.Conflict("party_linked", "this tenant already uses the tenant portal")
		}
		email = strings.ToLower(strings.TrimSpace(email))
		if email == "" && party.Email != nil {
			email = *party.Email
		}
		if addr, err := mail.ParseAddress(email); err != nil || addr.Address != email {
			return invalid("invalid_email", "enter the tenant's e-mail")
		}
		n, err := q.InviteLeaseParty(ctx, db.InviteLeasePartyParams{Email: &email, ID: partyID, LeaseID: leaseID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("party_linked", "this tenant already uses the tenant portal")
		}
		if _, err := appendEvent(ctx, q, a.Lease, "party_invited", &p.UserID, map[string]any{"party_id": partyID,
			"role": party.Role}); err != nil {
			return err
		}
		if err := audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "lease", EntityID: &leaseID,
			Action: "lease.invite_party", Diff: map[string]any{"party_id": partyID}}); err != nil {
			return err
		}
		if s.Outbox == nil {
			return nil
		}
		// The e-mail goes to someone outside the organization: system part.
		if err := platformdb.Elevate(ctx, tx); err != nil {
			return err
		}
		m, err := s.Mail.Render(notify.Email, email, "cs", "lease_invitation", map[string]any{"Name": party.Name,
			"Landlord": a.Lease.PayeeName, "Address": a.Lease.PropertyAddress, "Email": email,
			"Link": s.WebBaseURL + "/smlouvy/" + leaseID.String()})
		if err != nil {
			return err
		}
		return s.Outbox.Enqueue(ctx, tx, m)
	})
}

// ---------------------------------------------------------------------------
// The scan of the paper contract.

// MaxScanBytes limits a contract scan.
const MaxScanBytes = 20 << 20

// ScanUpload is a presigned upload slot for a contract scan.
type ScanUpload struct {
	Key       string
	UploadURL string
}

func scanPrefix(leaseID uuid.UUID) string { return "leases/" + leaseID.String() + "/scan-" }

// landlordImported checks that the caller manages the imported lease.
func (s *Service) landlordImported(ctx context.Context, p *auth.Principal, orgID, leaseID uuid.UUID) (Access, error) {
	a, err := s.access(ctx, p, leaseID)
	if err != nil {
		return a, err
	}
	if !a.Landlord || a.Lease.OrgID != orgID {
		return a, errNotFound
	}
	if a.Lease.Origin != OriginImported {
		return a, apperr.Conflict("lease_not_imported", "a lease made here has its signed document already")
	}
	return a, nil
}

// CreateScanUpload reserves a storage key for the scan of an imported
// lease's paper contract (PUT the file, then CompleteScanUpload).
func (s *Service) CreateScanUpload(ctx context.Context, p *auth.Principal, orgID, leaseID uuid.UUID, contentType string, size int64) (ScanUpload, error) {
	if contentType != "application/pdf" && contentType != "image/jpeg" && contentType != "image/png" {
		return ScanUpload{}, apperr.Unprocessable("attachment_type", "upload a PDF, JPEG or PNG")
	}
	if size <= 0 || size > MaxScanBytes {
		return ScanUpload{}, apperr.Unprocessable("attachment_size", "the file is limited to 20 MB")
	}
	if _, err := s.landlordImported(ctx, p, orgID, leaseID); err != nil {
		return ScanUpload{}, err
	}
	key := scanPrefix(leaseID) + uuid.NewString()
	u, err := s.Blob.PresignPut(ctx, key, 15*time.Minute)
	return ScanUpload{Key: key, UploadURL: u}, err
}

// scanTypes are the accepted scans by sniffed type, with the file extension.
var scanTypes = map[string]string{"application/pdf": ".pdf", "image/jpeg": ".jpg", "image/png": ".png"}

// CompleteScanUpload checks the uploaded scan (size, sniffed type, malware)
// and attaches it to the lease as a document of kind 'scan'; it becomes the
// lease's contract scan (an earlier one stays in the documents).
func (s *Service) CompleteScanUpload(ctx context.Context, p *auth.Principal, orgID, leaseID uuid.UUID, key, filename string) error {
	a, err := s.landlordImported(ctx, p, orgID, leaseID)
	if err != nil {
		return err
	}
	if !strings.HasPrefix(key, scanPrefix(leaseID)) || strings.Contains(key, "..") {
		return apperr.NotFound("upload_not_found", "upload not found")
	}
	// Bounded read: the presigned PUT does not limit the size.
	data, err := s.Blob.GetLimited(ctx, key, MaxScanBytes)
	switch {
	case errors.Is(err, storage.ErrTooLarge):
		_ = s.Blob.Delete(ctx, key)
		return apperr.Unprocessable("attachment_size", "the file is limited to 20 MB")
	case errors.Is(err, storage.ErrNotFound):
		return apperr.Unprocessable("attachment_missing", "upload the file first")
	case err != nil:
		return err
	}
	sniffed, _, _ := strings.Cut(http.DetectContentType(data), ";")
	ext, ok := scanTypes[sniffed]
	if !ok {
		_ = s.Blob.Delete(ctx, key)
		return apperr.Unprocessable("attachment_type", "upload a PDF, JPEG or PNG")
	}
	var scanner media.Scanner = media.NoScanner{}
	if s.Scanner != nil {
		scanner = s.Scanner
	}
	if status, _, err := scanner.Scan(ctx, data); err != nil {
		return err
	} else if status == "infected" {
		_ = s.Blob.Delete(ctx, key)
		return apperr.Unprocessable("attachment_infected", "the file was rejected by the malware scanner")
	}
	filename = path.Base(strings.ReplaceAll(filename, "\\", "/"))
	filename = strings.TrimSuffix(filename, path.Ext(filename))
	if filename == "" || filename == "." || len([]rune(filename)) > 200 || !utf8.ValidString(filename) {
		filename = fmt.Sprintf("smlouva-%d-sken", a.Lease.Code)
	}
	filename += ext // the extension follows the checked content
	sum := sha256.Sum256(data)
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		n, err := q.CountLeaseDocuments(ctx, leaseID)
		if err != nil {
			return err
		}
		doc, err := q.InsertLeaseDocument(ctx, db.InsertLeaseDocumentParams{LeaseID: leaseID, OrgID: orgID, Kind: "scan",
			Version: n + 1, ObjectKey: key, Filename: filename, Sha256: sum[:]})
		if err != nil {
			return err
		}
		if err := q.SetLeaseContractScan(ctx, db.SetLeaseContractScanParams{ID: leaseID, ContractMediaID: &doc.ID}); err != nil {
			return err
		}
		if _, err := appendEvent(ctx, q, a.Lease, "contract_scan_attached", &p.UserID, map[string]any{"document_id": doc.ID,
			"document_sha256": hex.EncodeToString(sum[:])}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "lease", EntityID: &leaseID,
			Action: "lease.contract_scan", Diff: map[string]any{"document_id": doc.ID}})
	})
}

// scanContentType is the served type of a scan by its (checked) extension.
func scanContentType(filename string) string {
	for ct, ext := range scanTypes {
		if strings.EqualFold(path.Ext(filename), ext) {
			return ct
		}
	}
	return ""
}
