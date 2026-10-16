package leasing

import (
	"bytes"
	"context"
	"encoding/csv"
	"encoding/hex"
	"errors"
	"fmt"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/portfolio"
)

// Detail is a lease with everything both sides see.
type Detail struct {
	Access
	Parties    []db.LeaseParty
	Documents  []db.LeaseDocument
	Signatures []db.ListSignaturesRow
	Debt       []db.DebtByPartyRow
}

// Get returns a lease the caller can see.
func (s *Service) Get(ctx context.Context, p *auth.Principal, id uuid.UUID) (Detail, error) {
	a, err := s.access(ctx, p, id)
	if err != nil {
		return Detail{}, err
	}
	d := Detail{Access: a}
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		if d.Parties, err = q.ListLeaseParties(ctx, id); err != nil {
			return err
		}
		if d.Documents, err = q.ListLeaseDocuments(ctx, id); err != nil {
			return err
		}
		if doc, err := q.LatestLeaseDocument(ctx, db.LatestLeaseDocumentParams{LeaseID: id, Kind: "final"}); err == nil {
			if d.Signatures, err = q.ListSignatures(ctx, doc.ID); err != nil {
				return err
			}
		}
		today := s.now()
		d.Debt, err = q.DebtByParty(ctx, db.DebtByPartyParams{AsOf: date(&today), LeaseID: id})
		return err
	})
	return d, err
}

// DocumentURL returns a short-lived download link of a lease document.
func (s *Service) DocumentURL(ctx context.Context, d db.LeaseDocument) string {
	u, err := s.Blob.PresignGet(ctx, d.ObjectKey, 15*time.Minute)
	if err != nil {
		s.Log.Warn("presign lease document", "err", err)
	}
	return u
}

// List returns a page of the organization's leases, newest first, older
// than the lease before.
func (s *Service) List(ctx context.Context, p *auth.Principal, orgID uuid.UUID, before *uuid.UUID, limit int32) ([]db.ListOrgLeasesRow, error) {
	var out []db.ListOrgLeasesRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases); err != nil {
			return err
		}
		var err error
		out, err = q.ListOrgLeases(ctx, db.ListOrgLeasesParams{OrgID: orgID, Before: before, Lim: limit})
		return err
	})
	return out, err
}

// Mine returns the caller's leases as a tenant.
func (s *Service) Mine(ctx context.Context, p *auth.Principal) ([]db.ListMyLeasesRow, error) {
	s.claim(ctx, p)
	var out []db.ListMyLeasesRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		out, err = q.ListMyLeases(ctx, &p.UserID)
		return err
	})
	return out, err
}

// Obligation is one payment share with its QR payment.
type Obligation struct {
	db.ListObligationsRow
	SPAYD string
	Mine  bool
}

// Obligations lists the schedule; tenants see everything but get QR codes
// for their own shares only (joint liability: they may see who is behind).
func (s *Service) Obligations(ctx context.Context, p *auth.Principal, id uuid.UUID) ([]Obligation, error) {
	a, err := s.access(ctx, p, id)
	if err != nil {
		return nil, err
	}
	var rows []db.ListObligationsRow
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		rows, err = q.ListObligations(ctx, id)
		return err
	})
	if err != nil {
		return nil, err
	}
	out := make([]Obligation, 0, len(rows))
	for _, r := range rows {
		o := Obligation{ListObligationsRow: r}
		o.Mine = a.Party != nil && a.Party.ID == r.PartyID
		if r.PaidAmount < r.SplitAmount && (o.Mine || a.Landlord) {
			o.SPAYD = s.spayd(a.Lease, r.Kind, r.Period, r.Position, r.SplitAmount-r.PaidAmount, r.DueOn.Time)
		}
		out = append(out, o)
	}
	return out, nil
}

func (s *Service) spayd(l db.Lease, kind, period string, position int32, amount int64, due time.Time) string {
	msg := "Najem " + period
	if kind == "deposit" {
		msg = "Kauce"
	}
	return SPAYD(Payment{IBAN: l.PayeeIban, Amount: amount, Currency: l.Currency, VS: strconv.FormatInt(l.Code, 10),
		SS: strconv.Itoa(int(position)), Message: msg, Payee: l.PayeeName, DueDate: due.Format("20060102")})
}

// SplitPayment returns the QR payment of one share (the caller must be the
// paying party or the landlord).
func (s *Service) SplitPayment(ctx context.Context, p *auth.Principal, splitID uuid.UUID) (string, error) {
	sp, err := db.New(s.Pool).GetSplit(ctx, splitID)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", apperr.NotFound("split_not_found", "payment not found")
	}
	if err != nil {
		return "", err
	}
	a, err := s.access(ctx, p, sp.LeaseID)
	if err != nil {
		return "", err
	}
	if !a.Landlord && (a.Party == nil || a.Party.ID != sp.PartyID) {
		return "", apperr.NotFound("split_not_found", "payment not found")
	}
	if sp.PaidAmount >= sp.Amount {
		return "", apperr.Conflict("already_paid", "this payment is settled")
	}
	return s.spayd(a.Lease, sp.Kind, sp.Period, sp.Position, sp.Amount-sp.PaidAmount, sp.DueOn.Time), nil
}

// errOverpaid: the payment would exceed what is still due on the share.
var errOverpaid = invalid("invalid_amount", "the amount exceeds what is due")

// applyPayment books a payment of a split (system context, inside tx). The
// lease and the split are locked (in this order, like appendEvent) and the
// amount is checked against what is still open, so concurrent bookings
// (bank match, confirmation, manual entry) never overpay a share. It returns
// errOverpaid without failing the transaction.
func (s *Service) applyPayment(ctx context.Context, q *db.Queries, splitID uuid.UUID, amount int64, day time.Time, source string, actor *uuid.UUID) error {
	sp, err := q.GetSplit(ctx, splitID)
	if err != nil {
		return err
	}
	if _, err := q.LockLease(ctx, sp.LeaseID); err != nil {
		return err
	}
	locked, err := q.LockSplit(ctx, splitID)
	if err != nil {
		return err
	}
	if amount <= 0 || locked.PaidAmount+amount > locked.Amount {
		return errOverpaid
	}
	l, err := q.GetLease(ctx, sp.LeaseID)
	if err != nil {
		return err
	}
	_, err = q.AddSplitPayment(ctx, db.AddSplitPaymentParams{ID: splitID, PaidAmount: amount})
	if errors.Is(err, pgx.ErrNoRows) {
		return errOverpaid
	}
	if err != nil {
		return err
	}
	if err := q.CloseObligationIfPaid(ctx, sp.ObligationID); err != nil {
		return err
	}
	memo := "payment " + sp.Kind + " " + sp.Period
	if err := post(ctx, q, l, day, memo, &splitID, leg{"cash", nil, amount}, leg{"receivable", &sp.PartyID, -amount}); err != nil {
		return err
	}
	_, err = appendEvent(ctx, q, l, "payment_recorded", actor, map[string]any{"split_id": splitID, "amount": amount,
		"booked_on": day.Format("2006-01-02"), "source": source})
	return err
}

// MarkPaid is the landlord's manual confirmation that a share arrived.
func (s *Service) MarkPaid(ctx context.Context, p *auth.Principal, orgID, splitID uuid.UUID, amount int64, day time.Time) error {
	sp, err := db.New(s.Pool).GetSplit(ctx, splitID)
	if err != nil || sp.OrgID != orgID {
		return apperr.NotFound("split_not_found", "payment not found")
	}
	if amount <= 0 {
		amount = sp.Amount - sp.PaidAmount
	}
	if amount <= 0 || sp.PaidAmount+amount > sp.Amount {
		return errOverpaid // checked again under the split lock in applyPayment
	}
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "obligation_split", EntityID: &splitID,
			Action: "payment.mark_paid", Diff: map[string]any{"amount": amount}})
	})
	if err != nil {
		return err
	}
	return s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		if err := s.applyPayment(ctx, q, splitID, amount, day, "manual", &p.UserID); err != nil {
			return err
		}
		s.pushPayment(ctx, q, tx, splitID, amount)
		return nil
	})
}

// Ledger returns the ledger of a lease.
func (s *Service) Ledger(ctx context.Context, p *auth.Principal, id uuid.UUID) ([]db.ListLedgerRow, error) {
	if _, err := s.access(ctx, p, id); err != nil {
		return nil, err
	}
	var out []db.ListLedgerRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		out, err = q.ListLedger(ctx, id)
		return err
	})
	return out, err
}

// LedgerCSV exports the ledger.
func LedgerCSV(rows []db.ListLedgerRow) []byte {
	var b bytes.Buffer
	w := csv.NewWriter(&b)
	_ = w.Write([]string{"booked_on", "posting_id", "account", "party", "amount", "memo"})
	for _, r := range rows {
		amount := fmt.Sprintf("%d.%02d", r.Amount/100, abs(r.Amount%100))
		if r.Amount < 0 && r.Amount > -100 {
			amount = "-" + amount
		}
		_ = w.Write([]string{r.BookedOn.Time.Format("2006-01-02"), r.PostingID.String(), r.Account, portfolio.CSVSafe(r.PartyName),
			amount, portfolio.CSVSafe(r.Memo)})
	}
	w.Flush()
	return b.Bytes()
}

func abs(x int64) int64 {
	if x < 0 {
		return -x
	}
	return x
}

// Events returns the event log and whether the hash chain verifies.
func (s *Service) Events(ctx context.Context, p *auth.Principal, id uuid.UUID) ([]db.LeaseEvent, int, error, error) {
	if _, err := s.access(ctx, p, id); err != nil {
		return nil, 0, nil, err
	}
	var events []db.LeaseEvent
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		events, err = q.ListLeaseEvents(ctx, id)
		return err
	})
	if err != nil {
		return nil, 0, nil, err
	}
	chain := make([]ChainEvent, len(events))
	for i, e := range events {
		chain[i] = ChainEvent{Seq: e.Seq, Payload: e.Payload, PrevHash: e.PrevHash, Hash: e.Hash}
	}
	n, verr := VerifyChain(chain)
	return events, n, verr, nil
}

// HeadHash is the hex hash of the last event (empty without events).
func HeadHash(events []db.LeaseEvent) string {
	if len(events) == 0 {
		return ""
	}
	return hex.EncodeToString(events[len(events)-1].Hash)
}

// Notice delivery window: the delivery date may lie at most NoticeBackDays
// in the past (a notice delivered by post and recorded late) and at most
// NoticeAheadDays in the future (handed over in the next days).
const (
	NoticeBackDays  = 30
	NoticeAheadDays = 7
)

// Statutory reasons of a landlord's notice (§ 2288 of the Civil Code). The
// first four are odst. 1 (any lease), the last odst. 2 (indefinite term only).
const (
	NoticeGrossBreach    = "gross_breach_tenant"
	NoticeConviction     = "conviction"
	NoticePublicInterest = "public_interest_vacate"
	NoticeOtherSerious   = "other_serious_reason"
	NoticeOwnUse         = "flat_needed_for_landlord_or_relative"
)

// NoticeReasons lists the landlord notice reasons.
var NoticeReasons = []string{NoticeGrossBreach, NoticeConviction, NoticePublicInterest, NoticeOtherSerious, NoticeOwnUse}

// LandlordNoticeMonths is the statutory notice period of a landlord's notice
// under § 2288 (three months); a longer agreed period applies instead.
const LandlordNoticeMonths = 3

// NoticeInput is a notice: the delivery date and, for the landlord, the
// statutory reason with an explanation.
type NoticeInput struct {
	DeliveredOn time.Time
	Reason      string
	Explanation string
}

var errReasonRequired = apperr.Unprocessable("landlord_notice_reason_required",
	"a landlord's notice needs a statutory reason (§ 2288 of the Civil Code)")

// checkLandlordReason validates a landlord's reason against the lease.
func checkLandlordReason(l db.Lease, in NoticeInput) error {
	if !slices.Contains(NoticeReasons, in.Reason) {
		return errReasonRequired
	}
	if in.Reason == NoticeOtherSerious && strings.TrimSpace(in.Explanation) == "" {
		return apperr.Unprocessable("landlord_notice_reason_required",
			"explain the other serious reason (§ 2288 odst. 1 písm. d of the Civil Code)")
	}
	// § 2288 odst. 2 applies to leases for an indefinite term only.
	if in.Reason == NoticeOwnUse && (l.EndsOn.Valid || l.Template == "byt_doba_urcita") {
		return apperr.Unprocessable("notice_reason_not_applicable",
			"this reason applies to leases for an indefinite term only")
	}
	return nil
}

// GiveNotice records a notice; the lease ends at the end of the notice
// period, later obligations are cancelled. A tenant or co-tenant gives it
// without a reason (not a guarantor or subtenant); the landlord states a
// statutory reason (§ 2288 OZ) and the period is at least three months.
func (s *Service) GiveNotice(ctx context.Context, p *auth.Principal, id uuid.UUID, in NoticeInput) (time.Time, error) {
	a, err := s.access(ctx, p, id)
	if err != nil {
		return time.Time{}, err
	}
	by := "tenant"
	months := int(a.Lease.NoticeMonths)
	switch {
	case a.Party != nil && (a.Party.Role == "tenant" || a.Party.Role == "co_tenant"):
		in.Reason, in.Explanation = "", ""
	case a.Landlord:
		if err := checkLandlordReason(a.Lease, in); err != nil {
			return time.Time{}, err
		}
		by = "landlord"
		months = max(months, LandlordNoticeMonths)
	default:
		return time.Time{}, apperr.Forbidden("notice_not_allowed", "only a tenant or the landlord can give notice")
	}
	deliveredOn := in.DeliveredOn
	now := s.now().In(prague)
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	deliveredOn = time.Date(deliveredOn.Year(), deliveredOn.Month(), deliveredOn.Day(), 0, 0, 0, 0, time.UTC)
	if deliveredOn.Before(today.AddDate(0, 0, -NoticeBackDays)) || deliveredOn.After(today.AddDate(0, 0, NoticeAheadDays)) {
		return time.Time{}, invalid("invalid_delivered_on",
			fmt.Sprintf("the notice must be delivered between %d days ago and %d days from today", NoticeBackDays, NoticeAheadDays))
	}
	first := time.Date(deliveredOn.Year(), deliveredOn.Month(), 1, 0, 0, 0, 0, time.UTC).AddDate(0, 1, 0)
	end := first.AddDate(0, months, -1)
	if a.Lease.EndsOn.Valid && a.Lease.EndsOn.Time.Before(end) {
		end = a.Lease.EndsOn.Time
	}
	err = s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		n, err := q.SetLeaseNotice(ctx, db.SetLeaseNoticeParams{ID: id, NoticeOn: date(&deliveredOn)})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("lease_not_active", "notice can be given on a signed or active lease")
		}
		if err := q.SetLeaseEnd(ctx, db.SetLeaseEndParams{ID: id, EndsOn: date(&end)}); err != nil {
			return err
		}
		if err := q.CancelObligationsAfter(ctx, db.CancelObligationsAfterParams{LeaseID: id, DueOn: date(&end)}); err != nil {
			return err
		}
		data := map[string]any{"by": by, "delivered_on": deliveredOn.Format("2006-01-02"), "ends_on": end.Format("2006-01-02"),
			"notice_months": months}
		if a.Party != nil {
			data["party_id"], data["role"] = a.Party.ID, a.Party.Role
		}
		if by == "landlord" {
			data["reason"] = in.Reason
			if e := strings.TrimSpace(in.Explanation); e != "" {
				data["explanation"] = e
			}
		}
		_, err = appendEvent(ctx, q, a.Lease, "notice_given", &p.UserID, data)
		return err
	})
	if err == nil {
		_ = s.notifyParties(ctx, id, "lease_notice", true, map[string]any{"EndsOn": end.Format("2. 1. 2006")})
	}
	return end, err
}

// ConfirmSettlement records that the caller agrees with the deposit
// settlement after the lease ended. When every party agreed the lease is
// settled; a dispute simply leaves it terminated (mediation is outside the
// platform).
func (s *Service) ConfirmSettlement(ctx context.Context, p *auth.Principal, id uuid.UUID) (bool, error) {
	a, err := s.access(ctx, p, id)
	if err != nil {
		return false, err
	}
	if a.Lease.State != "terminated" {
		return false, apperr.Conflict("lease_not_terminated", "the deposit is settled after the lease ends")
	}
	if a.Party == nil {
		return false, errNotFound
	}
	var settled bool
	err = s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		if a.Party.Role == "landlord" {
			if _, err := q.ConfirmSettlement(ctx, db.ConfirmSettlementParams{LeaseID: id, UserID: a.Party.UserID}); err != nil {
				return err
			}
		} else if _, err := q.ConfirmSettlement(ctx, db.ConfirmSettlementParams{LeaseID: id, UserID: &p.UserID}); err != nil {
			return err
		}
		if _, err := appendEvent(ctx, q, a.Lease, "settlement_confirmed", &p.UserID, map[string]any{"party_id": a.Party.ID}); err != nil {
			return err
		}
		parties, err := q.ListLeaseParties(ctx, id)
		if err != nil {
			return err
		}
		for _, pp := range parties {
			if pp.Role != "guarantor" && pp.SettlementOkAt == nil {
				return nil
			}
		}
		settled = true
		if err := q.SystemSetLeaseState(ctx, db.SystemSetLeaseStateParams{ID: id, State: "settled"}); err != nil {
			return err
		}
		_, err = appendEvent(ctx, q, a.Lease, "settled", nil, map[string]any{})
		return err
	})
	return settled, err
}

// ---------------------------------------------------------------------------
// Bank connections and matching.

// ConnectBank starts linking the landlord's account. The mock links at once.
func (s *Service) ConnectBank(ctx context.Context, p *auth.Principal, orgID uuid.UUID, institution, redirect string) (db.BankConnection, string, error) {
	if s.Bank == nil {
		return db.BankConnection{}, "", apperr.Unprocessable("bank_unavailable", "bank connections are not configured")
	}
	var conn db.BankConnection
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases); err != nil {
			return err
		}
		var err error
		conn, err = q.CreateBankConnection(ctx, db.CreateBankConnectionParams{OrgID: orgID, Provider: s.Bank.Name(),
			InstitutionID: institution, Status: "pending", CreatedBy: &p.UserID})
		return err
	})
	if err != nil {
		return conn, "", err
	}
	link, err := s.Bank.Link(ctx, institution, redirect, conn.ID.String())
	if err != nil {
		return conn, "", err
	}
	if _, err := s.Pool.Exec(ctx, `UPDATE bank_connections SET requisition_id = $2 WHERE id = $1`, conn.ID, link.RequisitionID); err != nil {
		return conn, "", err
	}
	conn.RequisitionID = link.RequisitionID
	if s.Bank.Name() == "mock" {
		conn, err = s.FinishBank(ctx, p, orgID, conn.ID)
	}
	return conn, link.URL, err
}

// FinishBank completes linking after the landlord returned from the bank.
func (s *Service) FinishBank(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) (db.BankConnection, error) {
	var conn db.BankConnection
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases); err != nil {
			return err
		}
		var err error
		conn, err = q.GetBankConnection(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && conn.OrgID != orgID) {
			return apperr.NotFound("connection_not_found", "bank connection not found")
		}
		return err
	})
	if err != nil {
		return conn, err
	}
	accounts, err := s.Bank.Accounts(ctx, conn.RequisitionID)
	if errors.Is(err, ErrNotLinked) {
		return conn, apperr.Conflict("bank_not_linked", "finish the authorization at your bank first")
	}
	if err != nil || len(accounts) == 0 {
		return conn, fmt.Errorf("bank accounts: %w", err)
	}
	q := db.New(s.Pool)
	if err := q.SetBankConnectionLinked(ctx, db.SetBankConnectionLinkedParams{ID: id, Status: "linked",
		AccountID: accounts[0][0], Iban: accounts[0][1]}); err != nil {
		return conn, err
	}
	return q.GetBankConnection(ctx, id)
}

// SyncResult counts what a sync did.
type SyncResult struct{ New, Matched, Suggested int }

// Sync fetches new transactions of a linked connection and matches them.
// Each transaction is stored and matched in one transaction, so a failed
// match leaves no row behind that later syncs would skip as seen.
func (s *Service) Sync(ctx context.Context, connID uuid.UUID) (SyncResult, error) {
	var res SyncResult
	q := db.New(s.Pool)
	conn, err := q.GetBankConnection(ctx, connID)
	if err != nil || conn.Status != "linked" {
		return res, err
	}
	since := s.now().AddDate(0, 0, -90)
	if conn.LastSyncedAt != nil {
		since = conn.LastSyncedAt.AddDate(0, 0, -3)
	}
	txns, err := s.Bank.Transactions(ctx, conn.AccountID, since)
	if err != nil {
		return res, err
	}
	for _, t := range txns {
		var status string
		err := s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
			row, err := q.InsertBankTransaction(ctx, db.InsertBankTransactionParams{OrgID: conn.OrgID, ConnectionID: conn.ID,
				ExternalID: t.ExternalID, BookedOn: date(&t.BookedOn), Amount: t.Amount, Currency: t.Currency,
				VariableSymbol: t.VariableSymbol, SpecificSymbol: t.SpecificSymbol, CounterpartyName: t.CounterpartyName,
				CounterpartyAccount: t.CounterpartyAccount, Remittance: t.Remittance})
			if errors.Is(err, pgx.ErrNoRows) {
				status = "seen"
				return nil
			}
			if err != nil {
				return err
			}
			status, err = s.match(ctx, q, tx, row)
			return err
		})
		if err != nil {
			return res, err
		}
		if status == "seen" {
			continue
		}
		res.New++
		switch status {
		case "matched":
			res.Matched++
		case "suggested":
			res.Suggested++
		}
	}
	return res, q.TouchBankConnection(ctx, conn.ID)
}

// match pairs an incoming transaction with an open share of the same
// currency: by variable symbol (lease code) and specific symbol (party
// position) with the exact amount automatically; by symbol with another
// amount, by symbol without a specific symbol when several tenants owe that
// amount, or by amount and date alone, as a suggestion the landlord confirms.
// It runs in the transaction that stored t.
func (s *Service) match(ctx context.Context, q *db.Queries, tx pgx.Tx, t db.BankTransaction) (string, error) {
	if t.Amount <= 0 {
		return "ignored", q.SetTransactionMatch(ctx, db.SetTransactionMatchParams{ID: t.ID,
			MatchStatus: "ignored", MatchNote: "outgoing"})
	}
	suggest := func(split uuid.UUID, note string) (string, error) {
		return "suggested", q.SetTransactionMatch(ctx, db.SetTransactionMatchParams{ID: t.ID, MatchStatus: "suggested",
			SplitID: &split, MatchNote: note})
	}
	type cand struct {
		id       uuid.UUID
		open     int64
		position int32
	}
	if code, err := strconv.ParseInt(t.VariableSymbol, 10, 64); err == nil {
		rows, err := q.OpenSplitsForCode(ctx, db.OpenSplitsForCodeParams{OrgID: t.OrgID, Code: code, Currency: t.Currency})
		if err != nil {
			return "", err
		}
		var cands, exact []cand
		payers := map[int32]bool{}
		for _, r := range rows {
			if t.SpecificSymbol == "" || t.SpecificSymbol == strconv.Itoa(int(r.Position)) {
				c := cand{r.ID, r.Amount - r.PaidAmount, r.Position}
				cands = append(cands, c)
				if c.open == t.Amount {
					exact = append(exact, c)
					payers[c.position] = true
				}
			}
		}
		if len(exact) > 0 && len(payers) > 1 {
			// No specific symbol and several tenants owe this amount: whose
			// payment it is would be a guess.
			return suggest(exact[0].id, "variable symbol and amount match several tenants")
		}
		if len(exact) > 0 {
			c := exact[0] // the oldest open share of that tenant
			err := s.applyPayment(ctx, q, c.id, t.Amount, t.BookedOn.Time, "bank", nil)
			if errors.Is(err, errOverpaid) { // paid meanwhile
				return suggest(c.id, "variable symbol and amount match, the share was paid meanwhile")
			}
			if err != nil {
				return "", err
			}
			if err := q.SetTransactionMatch(ctx, db.SetTransactionMatchParams{ID: t.ID, MatchStatus: "matched",
				SplitID: &c.id, MatchNote: "variable symbol and amount"}); err != nil {
				return "", err
			}
			s.pushPayment(ctx, q, tx, c.id, t.Amount)
			return "matched", nil
		}
		if len(cands) > 0 {
			return suggest(cands[0].id, "variable symbol matches, amount differs")
		}
	}
	rows, err := q.OpenSplitsByAmount(ctx, db.OpenSplitsByAmountParams{OrgID: t.OrgID, Amount: t.Amount, Currency: t.Currency,
		Day: t.BookedOn})
	if err != nil {
		return "", err
	}
	if len(rows) == 1 {
		return suggest(rows[0].ID, "amount and date match, no variable symbol")
	}
	return "unmatched", nil
}

// ConfirmMatch is the landlord's confirmation of a suggested (or manual) match.
func (s *Service) ConfirmMatch(ctx context.Context, p *auth.Principal, orgID, txID, splitID uuid.UUID) error {
	q := db.New(s.Pool)
	t, err := q.GetBankTransaction(ctx, txID)
	if err != nil || t.OrgID != orgID {
		return apperr.NotFound("transaction_not_found", "transaction not found")
	}
	if t.MatchStatus == "matched" {
		return apperr.Conflict("already_matched", "this transaction is already matched")
	}
	sp, err := q.GetSplit(ctx, splitID)
	if err != nil || sp.OrgID != orgID {
		return apperr.NotFound("split_not_found", "payment not found")
	}
	if sp.Currency != t.Currency {
		return invalid("currency_mismatch", "the payment is in another currency than the share")
	}
	if t.Amount <= 0 || sp.PaidAmount >= sp.Amount {
		return apperr.Conflict("already_paid", "this payment is settled")
	}
	if err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "bank_transaction", EntityID: &txID,
			Action: "payment.confirm_match", Diff: map[string]any{"split_id": splitID}})
	}); err != nil {
		return err
	}
	return s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		n, err := q.MatchTransaction(ctx, db.MatchTransactionParams{ID: txID, SplitID: &splitID, MatchNote: "confirmed by the landlord"})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("already_matched", "this transaction is already matched")
		}
		if _, err := q.LockLease(ctx, sp.LeaseID); err != nil {
			return err
		}
		locked, err := q.LockSplit(ctx, splitID)
		if err != nil {
			return err
		}
		amount := min(t.Amount, locked.Amount-locked.PaidAmount)
		if amount <= 0 {
			return apperr.Conflict("already_paid", "this payment is settled")
		}
		if err := s.applyPayment(ctx, q, splitID, amount, t.BookedOn.Time, "bank_confirmed", &p.UserID); err != nil {
			return err
		}
		s.pushPayment(ctx, q, tx, splitID, amount)
		return nil
	})
}

// IgnoreTransaction marks a transaction as unrelated.
func (s *Service) IgnoreTransaction(ctx context.Context, p *auth.Principal, orgID, txID uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases); err != nil {
			return err
		}
		t, err := q.GetBankTransaction(ctx, txID)
		if err != nil {
			return apperr.NotFound("transaction_not_found", "transaction not found")
		}
		if t.MatchStatus == "matched" {
			return apperr.Conflict("already_matched", "this transaction is already matched")
		}
		return q.SetTransactionMatch(ctx, db.SetTransactionMatchParams{ID: txID, MatchStatus: "ignored", MatchNote: "ignored by the landlord"})
	})
}

// BankOverview returns connections and a page of transactions (newest
// first, older than the transaction before) for the landlord's bank page.
func (s *Service) BankOverview(ctx context.Context, p *auth.Principal, orgID uuid.UUID, status *string, before *uuid.UUID, limit int32) ([]db.BankConnection, []db.BankTransaction, error) {
	var conns []db.BankConnection
	var txns []db.BankTransaction
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases); err != nil {
			return err
		}
		var err error
		if conns, err = q.ListBankConnections(ctx, orgID); err != nil {
			return err
		}
		txns, err = q.ListBankTransactions(ctx, db.ListBankTransactionsParams{OrgID: orgID, Status: status, Before: before, Lim: limit})
		return err
	})
	return conns, txns, err
}

// SyncOrg syncs the caller's organization's linked connections now.
func (s *Service) SyncOrg(ctx context.Context, p *auth.Principal, orgID uuid.UUID) (SyncResult, error) {
	conns, _, err := s.BankOverview(ctx, p, orgID, nil, nil, 1)
	var total SyncResult
	if err != nil {
		return total, err
	}
	for _, c := range conns {
		r, err := s.Sync(ctx, c.ID)
		if err != nil {
			return total, err
		}
		total.New, total.Matched, total.Suggested = total.New+r.New, total.Matched+r.Matched, total.Suggested+r.Suggested
	}
	return total, nil
}

// SyncAll syncs every linked connection (periodic job).
func (s *Service) SyncAll(ctx context.Context) error {
	conns, err := db.New(s.Pool).LinkedBankConnections(ctx)
	if err != nil {
		return err
	}
	for _, c := range conns {
		if _, err := s.Sync(ctx, c.ID); err != nil {
			s.Log.Warn("bank sync", "connection", c.ID, "err", err)
		}
	}
	return nil
}
