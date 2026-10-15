package billing

import (
	"context"
	"embed"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"time"
)

//go:embed templates/invoice.typ
var invoiceFS embed.FS

// ErrNoTypst means the typst binary is missing.
var ErrNoTypst = errors.New("typst binary not found")

// PaymentMethodCardPaid is the payment method printed on promo invoices.
const PaymentMethodCardPaid = "Platební karta – uhrazeno"

// Party identifies the supplier or the buyer on an invoice.
type Party struct {
	Name    string `json:"name"`
	ICO     string `json:"ico,omitempty"`
	DIC     string `json:"dic,omitempty"`
	Address string `json:"address,omitempty"`
	IBAN    string `json:"iban,omitempty"`
	Email   string `json:"email,omitempty"`
}

// InvoiceLine is one supplied service.
type InvoiceLine struct {
	Description string `json:"description"`
	Quantity    int64  `json:"quantity"`
	UnitNet     int64  `json:"unit_net"` // minor units without VAT
	VATRateBP   int    `json:"vat_rate_bp"`
	Net         int64  `json:"net"`
	VAT         int64  `json:"vat"`
	Gross       int64  `json:"gross"`
}

// NewInvoiceLine computes net, VAT and gross of a line.
func NewInvoiceLine(description string, quantity, unitNet int64, rateBP int) InvoiceLine {
	net := quantity * unitNet
	vat, gross := ComputeVAT(net, rateBP)
	return InvoiceLine{Description: description, Quantity: quantity, UnitNet: unitNet, VATRateBP: rateBP,
		Net: net, VAT: vat, Gross: gross}
}

// VATSummary is the tax base and VAT for one rate (§ 29 odst. 1 písm. i–k ZDPH).
type VATSummary struct {
	RateBP int   `json:"rate_bp"`
	Net    int64 `json:"net"`
	VAT    int64 `json:"vat"`
	Gross  int64 `json:"gross"`
}

// InvoiceData is a tax document (daňový doklad) for a paid platform service.
type InvoiceData struct {
	Number          string        `json:"number"` // FormatInvoiceNumber
	IssuedOn        time.Time     `json:"issued_on"`
	TaxableSupplyOn time.Time     `json:"taxable_supply_on"` // DUZP = payment date
	DueOn           time.Time     `json:"due_on"`            // = IssuedOn, paid by card
	Supplier        Party         `json:"supplier"`
	Buyer           Party         `json:"buyer"`
	Lines           []InvoiceLine `json:"lines"`
	Currency        string        `json:"currency"`
	PaymentMethod   string        `json:"payment_method"` // default PaymentMethodCardPaid
	OrderRef        string        `json:"order_ref,omitempty"`
	Note            string        `json:"note,omitempty"`
}

// Totals sums the lines.
func (d InvoiceData) Totals() (net, vat, gross int64) {
	for _, l := range d.Lines {
		net, vat, gross = net+l.Net, vat+l.VAT, gross+l.Gross
	}
	return net, vat, gross
}

// VATSummaries groups the lines by VAT rate, highest rate first.
func (d InvoiceData) VATSummaries() []VATSummary {
	by := map[int]*VATSummary{}
	for _, l := range d.Lines {
		s := by[l.VATRateBP]
		if s == nil {
			s = &VATSummary{RateBP: l.VATRateBP}
			by[l.VATRateBP] = s
		}
		s.Net, s.VAT, s.Gross = s.Net+l.Net, s.VAT+l.VAT, s.Gross+l.Gross
	}
	out := make([]VATSummary, 0, len(by))
	for _, s := range by {
		out = append(out, *s)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].RateBP > out[j].RateBP })
	return out
}

// view is what the Typst template reads: amounts and dates already formatted.
func (d InvoiceData) view() map[string]any {
	cur := d.Currency
	f := func(v int64) string { return FormatAmount(v, cur) }
	lines := make([]map[string]any, 0, len(d.Lines))
	for _, l := range d.Lines {
		lines = append(lines, map[string]any{"description": l.Description, "quantity": l.Quantity,
			"unit_net": f(l.UnitNet), "rate": FormatRate(l.VATRateBP), "net": f(l.Net), "vat": f(l.VAT), "gross": f(l.Gross)})
	}
	var recap []map[string]string
	for _, s := range d.VATSummaries() {
		recap = append(recap, map[string]string{"rate": FormatRate(s.RateBP), "net": f(s.Net), "vat": f(s.VAT), "gross": f(s.Gross)})
	}
	net, vat, gross := d.Totals()
	pm := d.PaymentMethod
	if pm == "" {
		pm = PaymentMethodCardPaid
	}
	due := d.DueOn
	if due.IsZero() {
		due = d.IssuedOn
	}
	return map[string]any{"number": d.Number, "issued_on": FormatDate(d.IssuedOn),
		"taxable_supply_on": FormatDate(d.TaxableSupplyOn), "due_on": FormatDate(due),
		"supplier": d.Supplier, "buyer": d.Buyer, "lines": lines, "recap": recap,
		"total_net": f(net), "total_vat": f(vat), "total_gross": f(gross), "paid": f(gross), "to_pay": f(0),
		"currency": cur, "payment_method": pm, "order_ref": d.OrderRef, "note": d.Note}
}

// InvoiceRenderer renders invoices to PDF with the typst CLI (embedded fonts
// only, so output does not depend on the machine).
type InvoiceRenderer struct {
	Bin string // path or name of the typst binary; default "typst"
}

// Render returns the invoice PDF.
func (t InvoiceRenderer) Render(ctx context.Context, d InvoiceData) ([]byte, error) {
	bin := t.Bin
	if bin == "" {
		bin = "typst"
	}
	if _, err := exec.LookPath(bin); err != nil {
		return nil, ErrNoTypst
	}
	dir, err := os.MkdirTemp("", "terra-invoice-")
	if err != nil {
		return nil, err
	}
	defer os.RemoveAll(dir)
	tpl, err := invoiceFS.ReadFile("templates/invoice.typ")
	if err != nil {
		return nil, err
	}
	src := filepath.Join(dir, "invoice.typ")
	if err := os.WriteFile(src, tpl, 0o600); err != nil {
		return nil, err
	}
	raw, err := json.Marshal(d.view())
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	out := filepath.Join(dir, "out.pdf")
	cmd := exec.CommandContext(ctx, bin, "compile", "--ignore-system-fonts", "--root", dir,
		"--input", "data="+string(raw), src, out)
	if msg, err := cmd.CombinedOutput(); err != nil {
		return nil, fmt.Errorf("typst: %v: %.500s", err, msg)
	}
	return os.ReadFile(out)
}
