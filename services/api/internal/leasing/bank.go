package leasing

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Transaction is a booked transaction on the landlord's account.
type Transaction struct {
	ExternalID          string
	BookedOn            time.Time
	Amount              int64 // minor units, incoming positive
	Currency            string
	VariableSymbol      string
	SpecificSymbol      string
	CounterpartyName    string
	CounterpartyAccount string
	Remittance          string
}

// Link is the start of an account connection.
type Link struct {
	RequisitionID string
	URL           string // where the landlord authorizes access at their bank
}

// BankProvider reads the landlord's own account (PSD2 AIS). The platform
// never initiates or holds payments (ADR 0002).
type BankProvider interface {
	Name() string
	// Link starts the consent flow with the institution and returns the URL.
	Link(ctx context.Context, institutionID, redirect, reference string) (Link, error)
	// Accounts lists accounts (id, IBAN) once the requisition is authorized.
	Accounts(ctx context.Context, requisitionID string) ([][2]string, error)
	// Transactions returns booked transactions since a date.
	Transactions(ctx context.Context, accountID string, since time.Time) ([]Transaction, error)
}

var (
	reVS = regexp.MustCompile(`(?i)\bVS[:/ ]*([0-9]{1,10})\b`)
	reSS = regexp.MustCompile(`(?i)\bSS[:/ ]*([0-9]{1,10})\b`)
)

// SymbolsFrom extracts variable and specific symbols from free text (Czech
// banks put "/VS/123/SS/2" or "VS:123" into remittance information).
func SymbolsFrom(texts ...string) (vs, ss string) {
	for _, t := range texts {
		if m := reVS.FindStringSubmatch(t); m != nil && vs == "" {
			vs = m[1]
		}
		if m := reSS.FindStringSubmatch(t); m != nil && ss == "" {
			ss = m[1]
		}
	}
	return vs, ss
}

// MockBank links immediately and serves injected transactions (dev/test).
type MockBank struct {
	mu   sync.Mutex
	txns map[string][]Transaction
}

// Name implements BankProvider.
func (*MockBank) Name() string { return "mock" }

// Link implements BankProvider.
func (*MockBank) Link(_ context.Context, _, redirect, reference string) (Link, error) {
	return Link{RequisitionID: "mock-" + reference, URL: redirect}, nil
}

// Accounts implements BankProvider.
func (*MockBank) Accounts(_ context.Context, requisitionID string) ([][2]string, error) {
	return [][2]string{{"acc-" + requisitionID, "CZ6508000000192000145399"}}, nil
}

// Transactions implements BankProvider.
func (m *MockBank) Transactions(_ context.Context, accountID string, _ time.Time) ([]Transaction, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]Transaction(nil), m.txns[accountID]...), nil
}

// Add injects a transaction (dev endpoint and tests).
func (m *MockBank) Add(accountID string, t Transaction) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.txns == nil {
		m.txns = map[string][]Transaction{}
	}
	m.txns[accountID] = append(m.txns[accountID], t)
}

// GoCardless is the GoCardless Bank Account Data API (formerly Nordigen).
type GoCardless struct {
	BaseURL   string // https://bankaccountdata.gocardless.com/api/v2
	SecretID  string
	SecretKey string
	HTTP      *http.Client

	mu      sync.Mutex
	token   string
	expires time.Time
}

// NewGoCardless creates the adapter.
func NewGoCardless(secretID, secretKey string) *GoCardless {
	return &GoCardless{BaseURL: "https://bankaccountdata.gocardless.com/api/v2", SecretID: secretID, SecretKey: secretKey,
		HTTP: &http.Client{Timeout: 30 * time.Second}}
}

// Name implements BankProvider.
func (*GoCardless) Name() string { return "gocardless" }

func (g *GoCardless) do(ctx context.Context, method, path string, body, out any) error {
	tok, err := g.accessToken(ctx)
	if err != nil {
		return err
	}
	return g.raw(ctx, method, path, tok, body, out)
}

func (g *GoCardless) raw(ctx context.Context, method, path, token string, body, out any) error {
	var r io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		r = bytes.NewReader(b)
	}
	req, err := http.NewRequestWithContext(ctx, method, g.BaseURL+path, r)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/json")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	res, err := g.HTTP.Do(req)
	if err != nil {
		return fmt.Errorf("gocardless: %w", err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 8<<20))
	if res.StatusCode >= 300 {
		return fmt.Errorf("gocardless %s %s: status %d: %.300s", method, path, res.StatusCode, raw)
	}
	if out != nil {
		return json.Unmarshal(raw, out)
	}
	return nil
}

func (g *GoCardless) accessToken(ctx context.Context) (string, error) {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.token != "" && time.Now().Before(g.expires) {
		return g.token, nil
	}
	var out struct {
		Access        string `json:"access"`
		AccessExpires int    `json:"access_expires"`
	}
	if err := g.raw(ctx, http.MethodPost, "/token/new/", "", map[string]string{"secret_id": g.SecretID, "secret_key": g.SecretKey}, &out); err != nil {
		return "", err
	}
	g.token, g.expires = out.Access, time.Now().Add(time.Duration(out.AccessExpires-60)*time.Second)
	return g.token, nil
}

// Link implements BankProvider.
func (g *GoCardless) Link(ctx context.Context, institutionID, redirect, reference string) (Link, error) {
	var out struct {
		ID   string `json:"id"`
		Link string `json:"link"`
	}
	err := g.do(ctx, http.MethodPost, "/requisitions/", map[string]any{"institution_id": institutionID,
		"redirect": redirect, "reference": reference, "user_language": "CS"}, &out)
	return Link{RequisitionID: out.ID, URL: out.Link}, err
}

// Accounts implements BankProvider.
func (g *GoCardless) Accounts(ctx context.Context, requisitionID string) ([][2]string, error) {
	var req struct {
		Status   string   `json:"status"`
		Accounts []string `json:"accounts"`
	}
	if err := g.do(ctx, http.MethodGet, "/requisitions/"+requisitionID+"/", nil, &req); err != nil {
		return nil, err
	}
	if req.Status != "LN" {
		return nil, ErrNotLinked
	}
	var out [][2]string
	for _, id := range req.Accounts {
		var acc struct {
			IBAN string `json:"iban"`
		}
		if err := g.do(ctx, http.MethodGet, "/accounts/"+id+"/", nil, &acc); err != nil {
			return nil, err
		}
		out = append(out, [2]string{id, acc.IBAN})
	}
	return out, nil
}

// ErrNotLinked means the landlord has not finished the bank consent yet.
var ErrNotLinked = errors.New("bank account not linked yet")

type gcTxn struct {
	TransactionID     string `json:"transactionId"`
	InternalID        string `json:"internalTransactionId"`
	BookingDate       string `json:"bookingDate"`
	TransactionAmount struct {
		Amount   string `json:"amount"`
		Currency string `json:"currency"`
	} `json:"transactionAmount"`
	DebtorName    string `json:"debtorName"`
	DebtorAccount struct {
		IBAN string `json:"iban"`
	} `json:"debtorAccount"`
	Unstructured  string   `json:"remittanceInformationUnstructured"`
	UnstructuredA []string `json:"remittanceInformationUnstructuredArray"`
	Structured    string   `json:"remittanceInformationStructured"`
	EndToEndID    string   `json:"endToEndId"`
	CreditorRef   string   `json:"creditorReference"`
}

// Transactions implements BankProvider.
func (g *GoCardless) Transactions(ctx context.Context, accountID string, since time.Time) ([]Transaction, error) {
	var out struct {
		Transactions struct {
			Booked []gcTxn `json:"booked"`
		} `json:"transactions"`
	}
	path := "/accounts/" + accountID + "/transactions/?date_from=" + since.Format("2006-01-02")
	if err := g.do(ctx, http.MethodGet, path, nil, &out); err != nil {
		return nil, err
	}
	res := gcTransactions(out.Transactions.Booked)
	for i := range res {
		if validCurrency(res[i].Currency) {
			continue
		}
		// Some banks omit the currency per transaction: the account's applies.
		cur, err := g.accountCurrency(ctx, accountID)
		if err != nil {
			return nil, err
		}
		for j := i; j < len(res); j++ {
			if !validCurrency(res[j].Currency) {
				res[j].Currency = cur
			}
		}
		break
	}
	return res, nil
}

// validCurrency reports an ISO 4217 code (bank_transactions.currency CHECK).
func validCurrency(c string) bool {
	if len(c) != 3 {
		return false
	}
	for _, r := range c {
		if r < 'A' || r > 'Z' {
			return false
		}
	}
	return true
}

// accountCurrency is the currency of the account (account details).
func (g *GoCardless) accountCurrency(ctx context.Context, accountID string) (string, error) {
	var d struct {
		Account struct {
			Currency string `json:"currency"`
		} `json:"account"`
	}
	if err := g.do(ctx, http.MethodGet, "/accounts/"+accountID+"/details/", nil, &d); err != nil {
		return "", err
	}
	cur := strings.ToUpper(strings.TrimSpace(d.Account.Currency))
	if !validCurrency(cur) {
		return "", fmt.Errorf("gocardless: account %s has no valid currency %q", accountID, d.Account.Currency)
	}
	return cur, nil
}

// gcFallbackID identifies a booked transaction without transactionId and
// internalTransactionId (some banks send neither) by its content, so it is
// neither dropped as a duplicate of every other id-less transaction nor
// imported twice by overlapping syncs.
func gcFallbackID(t gcTxn) string {
	sum := sha256.Sum256([]byte(strings.Join([]string{t.BookingDate, t.TransactionAmount.Amount, t.TransactionAmount.Currency,
		t.DebtorAccount.IBAN, t.DebtorName, t.Unstructured, strings.Join(t.UnstructuredA, " "), t.Structured, t.EndToEndID,
		t.CreditorRef}, "\x1f")))
	return "sha256:" + hex.EncodeToString(sum[:16])
}

func gcTransactions(booked []gcTxn) []Transaction {
	var res []Transaction
	seen := map[string]int{}
	for _, t := range booked {
		amount, err := parseMinor(t.TransactionAmount.Amount)
		if err != nil {
			continue
		}
		day, err := time.Parse("2006-01-02", t.BookingDate)
		if err != nil {
			continue
		}
		id := t.TransactionID
		if id == "" {
			id = t.InternalID
		}
		if id == "" {
			// Identical id-less transactions in one response are distinct
			// payments (same tenant paying twice the same day).
			id = gcFallbackID(t)
			if seen[id]++; seen[id] > 1 {
				id += "#" + strconv.Itoa(seen[id])
			}
		}
		remit := strings.TrimSpace(strings.Join(append([]string{t.Unstructured, t.Structured}, t.UnstructuredA...), " "))
		vs, ss := SymbolsFrom(remit, t.EndToEndID, t.CreditorRef)
		res = append(res, Transaction{ExternalID: id, BookedOn: day, Amount: amount,
			Currency:       strings.ToUpper(strings.TrimSpace(t.TransactionAmount.Currency)),
			VariableSymbol: vs, SpecificSymbol: ss, CounterpartyName: t.DebtorName, CounterpartyAccount: t.DebtorAccount.IBAN,
			Remittance: remit})
	}
	return res
}

func parseMinor(s string) (int64, error) {
	f, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0, err
	}
	return int64(math.Round(f * 100)), nil
}
