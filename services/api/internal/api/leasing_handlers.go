package api

import (
	"bytes"
	"context"
	"encoding/hex"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"
	qrcode "github.com/skip2/go-qrcode"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/leasing"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

func dateDTO(d pgtype.Date) *openapi_types.Date {
	if !d.Valid {
		return nil
	}
	return &openapi_types.Date{Time: d.Time}
}

func leaseSummary(l db.Lease, tenants, orgName *string) gen.LeaseSummary {
	return gen.LeaseSummary{Id: l.ID, OrgId: l.OrgID, Code: l.Code, State: gen.LeaseState(l.State),
		Origin: gen.LeaseOrigin(l.Origin), CutoverOn: dateDTO(l.CutoverOn), VariableSymbol: l.VariableSymbol,
		Template: gen.LeaseTemplate(l.Template), PropertyAddress: l.PropertyAddress, UnitLabel: &l.UnitLabel,
		StartsOn: *dateDTO(l.StartsOn), EndsOn: dateDTO(l.EndsOn), RentAmount: l.RentAmount, Currency: l.Currency,
		CreatedAt: l.CreatedAt, TenantNames: tenants, OrgName: orgName}
}

func importInput(b gen.LeaseImportInput) leasing.ImportInput {
	in := leasing.ImportInput{Lease: leasing.Input{ListingID: b.ListingId, Template: string(b.Template),
		StartsOn: b.StartsOn.Time, Rent: b.RentAmount, PayeeIBAN: b.PayeeIban, PayeeName: b.PayeeName, DueDay: 15,
		PropertyAddress: b.PropertyAddress, RuianID: b.RuianId}}
	if b.EndsOn != nil {
		t := b.EndsOn.Time
		in.Lease.EndsOn = &t
	}
	if b.ServicesAmount != nil {
		in.Lease.Services = *b.ServicesAmount
	}
	if b.DepositAmount != nil {
		in.Lease.Deposit = *b.DepositAmount
	}
	if b.DueDay != nil {
		in.Lease.DueDay = int32(*b.DueDay)
	}
	if b.NoticeMonths != nil {
		in.Lease.NoticeMonths = int32(*b.NoticeMonths)
	}
	if b.UnitLabel != nil {
		in.Lease.UnitLabel = *b.UnitLabel
	}
	if b.CutoverOn != nil {
		t := b.CutoverOn.Time
		in.CutoverOn = &t
	}
	if b.DepositHeld != nil {
		in.DepositHeld = *b.DepositHeld
	}
	if b.VariableSymbol != nil {
		in.VariableSymbol = *b.VariableSymbol
	}
	for _, p := range b.Parties {
		pi := leasing.ImportParty{PartyInput: leasing.PartyInput{Name: p.Name, Role: string(p.Role)}}
		if p.Email != nil {
			pi.Email = string(*p.Email)
		}
		if p.ShareBps != nil {
			pi.ShareBps = *p.ShareBps
		}
		if p.OpeningBalance != nil {
			pi.OpeningBalance = *p.OpeningBalance
		}
		in.Parties = append(in.Parties, pi)
	}
	return in
}

func leaseInput(b gen.LeaseInput) leasing.Input {
	in := leasing.Input{ListingID: b.ListingId, ApplicationID: b.ApplicationId, Template: string(b.Template),
		StartsOn: b.StartsOn.Time, Rent: b.RentAmount, PayeeIBAN: b.PayeeIban, PayeeName: b.PayeeName, DueDay: 15}
	if b.EndsOn != nil {
		t := b.EndsOn.Time
		in.EndsOn = &t
	}
	if b.ServicesAmount != nil {
		in.Services = *b.ServicesAmount
	}
	if b.DepositAmount != nil {
		in.Deposit = *b.DepositAmount
	}
	if b.DueDay != nil {
		in.DueDay = int32(*b.DueDay)
	}
	if b.NoticeMonths != nil {
		in.NoticeMonths = int32(*b.NoticeMonths)
	}
	if b.Clauses != nil {
		for _, c := range *b.Clauses {
			in.Clauses = append(in.Clauses, string(c))
		}
	}
	if b.PropertyAddress != nil {
		in.PropertyAddress = *b.PropertyAddress
	}
	in.RuianID = b.RuianId
	if b.UnitLabel != nil {
		in.UnitLabel = *b.UnitLabel
	}
	if b.Parties != nil {
		for _, p := range *b.Parties {
			share := 0
			if p.ShareBps != nil {
				share = *p.ShareBps
			}
			in.Parties = append(in.Parties, leasing.PartyInput{Name: p.Name, Email: string(p.Email), Role: string(p.Role), ShareBps: share})
		}
	}
	return in
}

func (s *Server) leaseDetail(ctx context.Context, p *auth.Principal, id uuid.UUID) (gen.LeaseDetail, error) {
	d, err := s.Leases.Get(ctx, p, id)
	if err != nil {
		return gen.LeaseDetail{}, err
	}
	l := d.Lease
	out := gen.LeaseDetail{Lease: leaseSummary(l, nil, nil), LandlordView: d.Landlord, PayeeIban: leasing.FormatIBAN(l.PayeeIban),
		PayeeName: l.PayeeName, DueDay: int(l.DueDay), NoticeMonths: int(l.NoticeMonths), DepositAmount: l.DepositAmount,
		ServicesAmount: l.ServicesAmount, DepositHeld: l.DepositHeld, Clauses: l.Clauses, ChangeRequest: l.ChangeRequest,
		Parties: []gen.LeaseParty{}, Documents: []gen.LeaseDocument{}, SignProviders: []gen.SignProvider{}}
	for _, sp := range s.Leases.SignProviders() {
		out.SignProviders = append(out.SignProviders, gen.SignProvider{Id: gen.SignProviderId(sp.ID), Level: gen.SignProviderLevel(sp.Level)})
	}
	if out.Clauses == nil {
		out.Clauses = []string{}
	}
	signed := map[uuid.UUID]*time.Time{}
	for _, sg := range d.Signatures {
		signed[sg.PartyID] = sg.SignedAt
	}
	debt := map[uuid.UUID]int64{}
	for _, x := range d.Debt {
		debt[x.PartyID] = x.Debt
		out.TotalDebt += x.Debt
	}
	for _, pp := range d.Parties {
		me := d.Party != nil && d.Party.ID == pp.ID
		gp := gen.LeaseParty{Id: pp.ID, Role: gen.LeasePartyRole(pp.Role), Name: pp.Name,
			ShareBps: int(pp.ShareBps), Position: int(pp.Position), Me: me, SignedAt: signed[pp.ID], HasAccount: pp.UserID != nil}
		// Contact details of co-tenants and guarantors are the landlord's
		// business; a tenant-side caller sees their own and the landlord's.
		if d.Landlord || me || pp.Role == "landlord" {
			gp.Email = (*string)(pp.Email)
		}
		if d.Landlord {
			gp.InvitedAt = pp.InvitedAt
		}
		if v, ok := debt[pp.ID]; ok {
			gp.Debt = &v
		}
		out.Parties = append(out.Parties, gp)
	}
	for _, doc := range d.Documents {
		u := s.Leases.DocumentURL(ctx, doc)
		out.Documents = append(out.Documents, gen.LeaseDocument{Id: doc.ID, Kind: gen.LeaseDocumentKind(doc.Kind),
			Version: int(doc.Version), Filename: doc.Filename, Sha256: hex.EncodeToString(doc.Sha256),
			Url: u, CreatedAt: doc.CreatedAt})
		if l.ContractMediaID != nil && *l.ContractMediaID == doc.ID {
			out.ContractScanUrl = &u
		}
	}
	return out, nil
}

// ListOrgLeases implements GET /v1/orgs/{orgId}/leases.
func (s *Server) ListOrgLeases(ctx context.Context, r gen.ListOrgLeasesRequestObject) (gen.ListOrgLeasesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Leases.List(ctx, p, r.OrgId, r.Params.Before, limitOf(r.Params.Limit))
	if err != nil {
		return nil, err
	}
	out := gen.ListOrgLeases200JSONResponse{}
	for _, row := range rows {
		names := row.TenantNames
		out = append(out, leaseSummary(convert[db.Lease](row), &names, nil))
	}
	return out, nil
}

// CreateLease implements POST /v1/orgs/{orgId}/leases.
func (s *Server) CreateLease(ctx context.Context, r gen.CreateLeaseRequestObject) (gen.CreateLeaseResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	id, err := s.Leases.Create(ctx, p, r.OrgId, leaseInput(*r.Body))
	if err != nil {
		return nil, err
	}
	d, err := s.leaseDetail(ctx, p, id)
	if err != nil {
		return nil, err
	}
	return gen.CreateLease201JSONResponse(d), nil
}

// ImportLease implements POST /v1/orgs/{orgId}/leases/import.
func (s *Server) ImportLease(ctx context.Context, r gen.ImportLeaseRequestObject) (gen.ImportLeaseResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	id, err := s.Leases.Import(ctx, p, r.OrgId, importInput(*r.Body))
	if err != nil {
		return nil, err
	}
	d, err := s.leaseDetail(ctx, p, id)
	if err != nil {
		return nil, err
	}
	return gen.ImportLease201JSONResponse(d), nil
}

// InviteLeaseParty implements POST /v1/orgs/{orgId}/leases/{leaseId}/parties/{partyId}/invite.
func (s *Server) InviteLeaseParty(ctx context.Context, r gen.InviteLeasePartyRequestObject) (gen.InviteLeasePartyResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	email := ""
	if r.Body != nil && r.Body.Email != nil {
		email = string(*r.Body.Email)
	}
	if err := s.Leases.InviteParty(ctx, p, r.OrgId, r.LeaseId, r.PartyId, email); err != nil {
		return nil, err
	}
	d, err := s.leaseDetail(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	return gen.InviteLeaseParty200JSONResponse(d), nil
}

// CreateContractScanUpload implements POST /v1/orgs/{orgId}/leases/{leaseId}/contract-scan.
func (s *Server) CreateContractScanUpload(ctx context.Context, r gen.CreateContractScanUploadRequestObject) (gen.CreateContractScanUploadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	u, err := s.Leases.CreateScanUpload(ctx, p, r.OrgId, r.LeaseId, string(r.Body.ContentType), r.Body.SizeBytes)
	if err != nil {
		return nil, err
	}
	return gen.CreateContractScanUpload201JSONResponse{Key: u.Key, UploadUrl: u.UploadURL}, nil
}

// CompleteContractScanUpload implements POST /v1/orgs/{orgId}/leases/{leaseId}/contract-scan/complete.
func (s *Server) CompleteContractScanUpload(ctx context.Context, r gen.CompleteContractScanUploadRequestObject) (gen.CompleteContractScanUploadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Leases.CompleteScanUpload(ctx, p, r.OrgId, r.LeaseId, r.Body.Key, r.Body.Filename); err != nil {
		return nil, err
	}
	d, err := s.leaseDetail(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	return gen.CompleteContractScanUpload200JSONResponse(d), nil
}

// UpdateLease implements PUT /v1/orgs/{orgId}/leases/{leaseId}.
func (s *Server) UpdateLease(ctx context.Context, r gen.UpdateLeaseRequestObject) (gen.UpdateLeaseResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Leases.Update(ctx, p, r.OrgId, r.LeaseId, leaseInput(*r.Body)); err != nil {
		return nil, err
	}
	d, err := s.leaseDetail(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	return gen.UpdateLease200JSONResponse(d), nil
}

// ProposeLease implements POST /v1/orgs/{orgId}/leases/{leaseId}/propose.
func (s *Server) ProposeLease(ctx context.Context, r gen.ProposeLeaseRequestObject) (gen.ProposeLeaseResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Leases.Propose(ctx, p, r.OrgId, r.LeaseId); err != nil {
		return nil, err
	}
	d, err := s.leaseDetail(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	return gen.ProposeLease200JSONResponse(d), nil
}

// ListMyLeases implements GET /v1/me/leases.
func (s *Server) ListMyLeases(ctx context.Context, _ gen.ListMyLeasesRequestObject) (gen.ListMyLeasesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Leases.Mine(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListMyLeases200JSONResponse{}
	for _, row := range rows {
		name := row.OrgName
		out = append(out, leaseSummary(convert[db.Lease](row), nil, &name))
	}
	return out, nil
}

// GetLease implements GET /v1/leases/{leaseId}.
func (s *Server) GetLease(ctx context.Context, r gen.GetLeaseRequestObject) (gen.GetLeaseResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	d, err := s.leaseDetail(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	return gen.GetLease200JSONResponse(d), nil
}

// RequestLeaseChanges implements POST /v1/leases/{leaseId}/request-changes.
func (s *Server) RequestLeaseChanges(ctx context.Context, r gen.RequestLeaseChangesRequestObject) (gen.RequestLeaseChangesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Leases.RequestChanges(ctx, p, r.LeaseId, r.Body.Comment); err != nil {
		return nil, err
	}
	return gen.RequestLeaseChanges204Response{}, nil
}

// SignLease implements POST /v1/leases/{leaseId}/sign.
func (s *Server) SignLease(ctx context.Context, r gen.SignLeaseRequestObject) (gen.SignLeaseResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	meta := auth.Meta(ctx)
	res, err := s.Leases.Sign(ctx, p, r.LeaseId, string(r.Body.Provider), meta.IP, meta.UserAgent)
	if err != nil {
		return nil, err
	}
	out := gen.SignLease200JSONResponse{Signed: res.Signed}
	if res.RedirectURL != "" {
		out.RedirectUrl = &res.RedirectURL
	}
	return out, nil
}

// ListLeaseObligations implements GET /v1/leases/{leaseId}/obligations.
func (s *Server) ListLeaseObligations(ctx context.Context, r gen.ListLeaseObligationsRequestObject) (gen.ListLeaseObligationsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Leases.Obligations(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	out := gen.ListLeaseObligations200JSONResponse{}
	for _, o := range rows {
		item := gen.ObligationShare{Id: o.SplitID, ObligationId: o.ID, Kind: gen.ObligationShareKind(o.Kind), Period: o.Period,
			DueOn: *dateDTO(o.DueOn), Amount: o.SplitAmount, PaidAmount: o.PaidAmount, Currency: o.Currency,
			PartyId: o.PartyID, PartyName: o.PartyName, Mine: o.Mine, Status: gen.ObligationShareStatus(o.Status)}
		if o.SPAYD != "" {
			sp := o.SPAYD
			item.Spayd = &sp
		}
		out = append(out, item)
	}
	return out, nil
}

// GetShareQR implements GET /v1/obligation-shares/{shareId}/qr.
func (s *Server) GetShareQR(ctx context.Context, r gen.GetShareQRRequestObject) (gen.GetShareQRResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	payload, err := s.Leases.SplitPayment(ctx, p, r.ShareId)
	if err != nil {
		return nil, err
	}
	png, err := qrcode.Encode(payload, qrcode.Medium, 320)
	if err != nil {
		return nil, err
	}
	return gen.GetShareQR200ImagepngResponse{Body: bytes.NewReader(png), ContentLength: int64(len(png))}, nil
}

// MarkSharePaid implements POST /v1/orgs/{orgId}/obligation-shares/{shareId}/paid.
func (s *Server) MarkSharePaid(ctx context.Context, r gen.MarkSharePaidRequestObject) (gen.MarkSharePaidResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var amount int64
	day := time.Now()
	if r.Body != nil {
		if r.Body.Amount != nil {
			amount = *r.Body.Amount
		}
		if r.Body.PaidOn != nil {
			day = r.Body.PaidOn.Time
		}
	}
	if err := s.Leases.MarkPaid(ctx, p, r.OrgId, r.ShareId, amount, day); err != nil {
		return nil, err
	}
	return gen.MarkSharePaid204Response{}, nil
}

// GetLeaseLedger implements GET /v1/leases/{leaseId}/ledger.
func (s *Server) GetLeaseLedger(ctx context.Context, r gen.GetLeaseLedgerRequestObject) (gen.GetLeaseLedgerResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Leases.Ledger(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	if r.Params.Format != nil && *r.Params.Format == gen.GetLeaseLedgerParamsFormatCsv {
		csv := leasing.LedgerCSV(rows)
		return gen.GetLeaseLedger200TextcsvResponse{Body: bytes.NewReader(csv), ContentLength: int64(len(csv))}, nil
	}
	out := gen.GetLeaseLedger200JSONResponse{}
	for _, e := range rows {
		name := e.PartyName
		out = append(out, gen.LedgerEntry{PostingId: e.PostingID, Account: gen.LedgerEntryAccount(e.Account), PartyName: &name,
			Amount: e.Amount, Memo: e.Memo, BookedOn: *dateDTO(e.BookedOn)})
	}
	return out, nil
}

// GetLeaseEvents implements GET /v1/leases/{leaseId}/events.
func (s *Server) GetLeaseEvents(ctx context.Context, r gen.GetLeaseEventsRequestObject) (gen.GetLeaseEventsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	events, n, verr, err := s.Leases.Events(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	out := gen.GetLeaseEvents200JSONResponse{Events: []gen.LeaseEvent{}, Valid: verr == nil, Verified: n, Head: leasing.HeadHash(events)}
	if verr != nil {
		msg := verr.Error()
		out.Error = &msg
	}
	for _, e := range events {
		var payload map[string]any
		_ = json.Unmarshal(e.Payload, &payload)
		out.Events = append(out.Events, gen.LeaseEvent{Seq: int(e.Seq), Kind: e.Kind, Payload: payload,
			PrevHash: hex.EncodeToString(e.PrevHash), Hash: hex.EncodeToString(e.Hash), CreatedAt: e.CreatedAt})
	}
	return out, nil
}

// GiveLeaseNotice implements POST /v1/leases/{leaseId}/notice.
func (s *Server) GiveLeaseNotice(ctx context.Context, r gen.GiveLeaseNoticeRequestObject) (gen.GiveLeaseNoticeResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var reason, explanation string
	if r.Body.Reason != nil {
		reason = string(*r.Body.Reason)
	}
	if r.Body.Explanation != nil {
		explanation = *r.Body.Explanation
	}
	end, err := s.Leases.GiveNotice(ctx, p, r.LeaseId, leasing.NoticeInput{DeliveredOn: r.Body.DeliveredOn.Time,
		Reason: reason, Explanation: explanation})
	if err != nil {
		return nil, err
	}
	return gen.GiveLeaseNotice200JSONResponse{EndsOn: openapi_types.Date{Time: end}}, nil
}

// ConfirmLeaseSettlement implements POST /v1/leases/{leaseId}/settlement.
func (s *Server) ConfirmLeaseSettlement(ctx context.Context, r gen.ConfirmLeaseSettlementRequestObject) (gen.ConfirmLeaseSettlementResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	settled, err := s.Leases.ConfirmSettlement(ctx, p, r.LeaseId)
	if err != nil {
		return nil, err
	}
	return gen.ConfirmLeaseSettlement200JSONResponse{Settled: settled}, nil
}

func bankConnDTO(c db.BankConnection) gen.BankConnection {
	return gen.BankConnection{Id: c.ID, Provider: gen.BankConnectionProvider(c.Provider), Status: gen.BankConnectionStatus(c.Status),
		Iban: leasing.FormatIBAN(c.Iban), LastSyncedAt: c.LastSyncedAt, CreatedAt: c.CreatedAt}
}

// GetBankOverview implements GET /v1/orgs/{orgId}/bank.
func (s *Server) GetBankOverview(ctx context.Context, r gen.GetBankOverviewRequestObject) (gen.GetBankOverviewResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var status *string
	if r.Params.Status != nil {
		st := string(*r.Params.Status)
		status = &st
	}
	lim := limitOf(r.Params.Limit)
	conns, txns, err := s.Leases.BankOverview(ctx, p, r.OrgId, status, r.Params.Before, lim)
	if err != nil {
		return nil, err
	}
	out := gen.GetBankOverview200JSONResponse{Connections: []gen.BankConnection{}, Transactions: []gen.BankTransaction{}}
	for _, c := range conns {
		out.Connections = append(out.Connections, bankConnDTO(c))
	}
	for _, t := range txns {
		out.Transactions = append(out.Transactions, gen.BankTransaction{Id: t.ID, BookedOn: *dateDTO(t.BookedOn), Amount: t.Amount,
			Currency: t.Currency, VariableSymbol: t.VariableSymbol, SpecificSymbol: t.SpecificSymbol,
			CounterpartyName: t.CounterpartyName, Remittance: t.Remittance,
			MatchStatus: gen.BankTransactionMatchStatus(t.MatchStatus), ShareId: t.SplitID, MatchNote: t.MatchNote})
	}
	if int32(len(txns)) == lim {
		out.TransactionsNextBefore = &txns[len(txns)-1].ID
	}
	return out, nil
}

// ConnectBank implements POST /v1/orgs/{orgId}/bank/connections.
func (s *Server) ConnectBank(ctx context.Context, r gen.ConnectBankRequestObject) (gen.ConnectBankResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	inst := ""
	if r.Body.InstitutionId != nil {
		inst = *r.Body.InstitutionId
	}
	conn, link, err := s.Leases.ConnectBank(ctx, p, r.OrgId, inst, r.Body.RedirectUri)
	if err != nil {
		return nil, err
	}
	out := gen.ConnectBank201JSONResponse{Connection: bankConnDTO(conn)}
	if link != "" {
		out.Link = &link
	}
	return out, nil
}

// FinishBankConnection implements POST /v1/orgs/{orgId}/bank/connections/{connectionId}/finish.
func (s *Server) FinishBankConnection(ctx context.Context, r gen.FinishBankConnectionRequestObject) (gen.FinishBankConnectionResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	conn, err := s.Leases.FinishBank(ctx, p, r.OrgId, r.ConnectionId)
	if err != nil {
		return nil, err
	}
	return gen.FinishBankConnection200JSONResponse(bankConnDTO(conn)), nil
}

// SyncBank implements POST /v1/orgs/{orgId}/bank/sync.
func (s *Server) SyncBank(ctx context.Context, r gen.SyncBankRequestObject) (gen.SyncBankResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	res, err := s.Leases.SyncOrg(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	return gen.SyncBank200JSONResponse{New: res.New, Matched: res.Matched, Suggested: res.Suggested}, nil
}

// MatchBankTransaction implements POST /v1/orgs/{orgId}/bank/transactions/{transactionId}/match.
func (s *Server) MatchBankTransaction(ctx context.Context, r gen.MatchBankTransactionRequestObject) (gen.MatchBankTransactionResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	switch {
	case r.Body.Ignore != nil && *r.Body.Ignore:
		err = s.Leases.IgnoreTransaction(ctx, p, r.OrgId, r.TransactionId)
	case r.Body.ShareId != nil:
		err = s.Leases.ConfirmMatch(ctx, p, r.OrgId, r.TransactionId, *r.Body.ShareId)
	default:
		err = apperr.BadRequest("invalid_request", "share_id or ignore is required")
	}
	if err != nil {
		return nil, err
	}
	return gen.MatchBankTransaction204Response{}, nil
}
