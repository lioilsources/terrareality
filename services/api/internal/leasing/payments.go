package leasing

import (
	"bytes"
	"context"
	"encoding/csv"
	"encoding/hex"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
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

// List returns the organization's leases.
func (s *Service) List(ctx context.Context, p *auth.Principal, orgID uuid.UUID) ([]db.ListOrgLeasesRow, error) {
	var out []db.ListOrgLeasesRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermLeases); err != nil {
			return err
		}
		var err error
		out, err = q.ListOrgLeases(ctx, orgID)
		return err
	})
	return out, err
}

// Mine returns the caller's leases as a tenant.
func (s *Service) Mine(ctx context.Context, p *auth.Principal) ([]db.ListMyLeasesRow, error) {
	if u, err := db.New(s.Pool).GetUser(ctx, p.UserID); err == nil {
		_ = db.New(s.Pool).ClaimLeaseParties(ctx, db.ClaimLeasePartiesParams{UserID: &p.UserID, Column2: u.Email})
	}
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

// applyPayment books a payment of a split (system context, inside tx).
func (s *Service) applyPayment(ctx context.Context, q *db.Queries, splitID uuid.UUID, amount int64, day time.Time, source string, actor *uuid.UUID) error {
	sp, err := q.GetSplit(ctx, splitID)
	if err != nil {
		return err
	}
	l, err := q.GetLease(ctx, sp.LeaseID)
	if err != nil {
		return err
	}
	if _, err := q.AddSplitPayment(ctx, db.AddSplitPaymentParams{ID: splitID, PaidAmount: amount}); err != nil {
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
		return invalid("invalid_amount", "the amount exceeds what is due")
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
	return s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		return s.applyPayment(ctx, q, splitID, amount, day, "manual", &p.UserID)
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
		_ = w.Write([]string{r.BookedOn.Time.Format("2006-01-02"), r.PostingID.String(), r.Account, r.PartyName,
			fmt.Sprintf("%d.%02d", r.Amount/100, abs(r.Amount%100)), r.Memo})
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

// GiveNotice records a notice by either side; the lease ends at the end of
// the notice period, later obligations are cancelled.
func (s *Service) GiveNotice(ctx context.Context, p *auth.Principal, id uuid.UUID, deliveredOn time.Time) (time.Time, error) {
	a, err := s.access(ctx, p, id)
	if err != nil {
		return time.Time{}, err
	}
	if a.Party == nil && !a.Landlord {
		return time.Time{}, errNotFound
	}
	first := time.Date(deliveredOn.Year(), deliveredOn.Month(), 1, 0, 0, 0, 0, time.UTC).AddDate(0, 1, 0)
	end := first.AddDate(0, int(a.Lease.NoticeMonths), -1)
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
		by := "tenant"
		if a.Landlord {
			by = "landlord"
		}
		_, err = appendEvent(ctx, q, a.Lease, "notice_given", &p.UserID, map[string]any{"by": by,
			"delivered_on": deliveredOn.Format("2006-01-02"), "ends_on": end.Format("2006-01-02")})
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
		row, err := q.InsertBankTransaction(ctx, db.InsertBankTransactionParams{OrgID: conn.OrgID, ConnectionID: conn.ID,
			ExternalID: t.ExternalID, BookedOn: date(&t.BookedOn), Amount: t.Amount, Currency: t.Currency,
			VariableSymbol: t.VariableSymbol, SpecificSymbol: t.SpecificSymbol, CounterpartyName: t.CounterpartyName,
			CounterpartyAccount: t.CounterpartyAccount, Remittance: t.Remittance})
		if errors.Is(err, pgx.ErrNoRows) {
			continue // seen before
		}
		if err != nil {
			return res, err
		}
		res.New++
		status, err := s.match(ctx, row)
		if err != nil {
			return res, err
		}
		switch status {
		case "matched":
			res.Matched++
		case "suggested":
			res.Suggested++
		}
	}
	return res, q.TouchBankConnection(ctx, conn.ID)
}

// match pairs an incoming transaction with an open share: by variable symbol
// (lease code) and specific symbol (party position) with the exact amount
// automatically; by symbol with another amount, or by amount and date alone,
// as a suggestion the landlord confirms.
func (s *Service) match(ctx context.Context, t db.BankTransaction) (string, error) {
	if t.Amount <= 0 {
		return "ignored", db.New(s.Pool).SetTransactionMatch(ctx, db.SetTransactionMatchParams{ID: t.ID,
			MatchStatus: "ignored", MatchNote: "outgoing"})
	}
	q := db.New(s.Pool)
	type cand struct {
		id       uuid.UUID
		open     int64
		position int32
	}
	var cands []cand
	if code, err := strconv.ParseInt(t.VariableSymbol, 10, 64); err == nil {
		rows, err := q.OpenSplitsForCode(ctx, db.OpenSplitsForCodeParams{OrgID: t.OrgID, Code: code})
		if err != nil {
			return "", err
		}
		for _, r := range rows {
			if t.SpecificSymbol == "" || t.SpecificSymbol == strconv.Itoa(int(r.Position)) {
				cands = append(cands, cand{r.ID, r.Amount - r.PaidAmount, r.Position})
			}
		}
		for _, c := range cands {
			if c.open == t.Amount {
				return "matched", s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
					if err := q.SetTransactionMatch(ctx, db.SetTransactionMatchParams{ID: t.ID, MatchStatus: "matched",
						SplitID: &c.id, MatchNote: "variable symbol and amount"}); err != nil {
						return err
					}
					return s.applyPayment(ctx, q, c.id, t.Amount, t.BookedOn.Time, "bank", nil)
				})
			}
		}
		if len(cands) > 0 {
			return "suggested", q.SetTransactionMatch(ctx, db.SetTransactionMatchParams{ID: t.ID, MatchStatus: "suggested",
				SplitID: &cands[0].id, MatchNote: "variable symbol matches, amount differs"})
		}
	}
	rows, err := q.OpenSplitsByAmount(ctx, db.OpenSplitsByAmountParams{OrgID: t.OrgID, Amount: t.Amount, Day: t.BookedOn})
	if err != nil {
		return "", err
	}
	if len(rows) == 1 {
		return "suggested", q.SetTransactionMatch(ctx, db.SetTransactionMatchParams{ID: t.ID, MatchStatus: "suggested",
			SplitID: &rows[0].ID, MatchNote: "amount and date match, no variable symbol"})
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
	amount := min(t.Amount, sp.Amount-sp.PaidAmount)
	if amount <= 0 {
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
	return s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		if err := q.SetTransactionMatch(ctx, db.SetTransactionMatchParams{ID: txID, MatchStatus: "matched", SplitID: &splitID,
			MatchNote: "confirmed by the landlord"}); err != nil {
			return err
		}
		return s.applyPayment(ctx, q, splitID, amount, t.BookedOn.Time, "bank_confirmed", &p.UserID)
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

// BankOverview returns connections and transactions for the landlord's bank page.
func (s *Service) BankOverview(ctx context.Context, p *auth.Principal, orgID uuid.UUID, status *string) ([]db.BankConnection, []db.BankTransaction, error) {
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
		txns, err = q.ListBankTransactions(ctx, db.ListBankTransactionsParams{OrgID: orgID, Status: status})
		return err
	})
	return conns, txns, err
}

// SyncOrg syncs the caller's organization's linked connections now.
func (s *Service) SyncOrg(ctx context.Context, p *auth.Principal, orgID uuid.UUID) (SyncResult, error) {
	conns, _, err := s.BankOverview(ctx, p, orgID, nil)
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
