package billing

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

// FlagRevolut gates Revolut payment links.
const FlagRevolut = "payments.revolut"

// MaxWebhookBody caps the Stripe webhook payload.
const MaxWebhookBody = 1 << 20

// Flags reports feature flags (flags.Store or a config-backed func).
type Flags interface {
	Enabled(ctx context.Context, key string) bool
}

// FlagFunc adapts a function to Flags.
type FlagFunc func(key string) bool

// Enabled implements Flags.
func (f FlagFunc) Enabled(_ context.Context, key string) bool { return f(key) }

// Jobs enqueues background work in the transaction of the change.
type Jobs interface {
	// DeliverInvoice renders and stores the invoice PDF and e-mails the buyer.
	DeliverInvoice(ctx context.Context, tx pgx.Tx, invoiceID uuid.UUID) error
}

// Service is the database-backed billing: promo checkout and Stripe webhook
// (platform services, ADR 0002), invoices, and the landlord's own Revolut
// payment links (money goes landlord-direct; the platform only creates the
// link). Owner-facing reads and writes run as the user (row-level security);
// the webhook, invoicing and the Revolut key read run in system context.
type Service struct {
	Pool       *pgxpool.Pool
	Stripe     StripeClient
	Revolut    RevolutMerchant
	Box        *secretbox.Box
	Blob       storage.Blob
	Outbox     notify.Outbox
	Mail       *notify.Renderer
	Jobs       Jobs // nil: deliver invoices inline after commit (tests)
	Invoices   InvoiceRenderer
	Supplier   Party
	WebBaseURL string
	// RedirectAllow lists further allowed redirect URLs (the OIDC allowlist);
	// their http(s) origins may also receive success/cancel redirects.
	RedirectAllow []string
	Flags         Flags
	Log           *slog.Logger
	Now           func() time.Time // tests
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func (s *Service) log() *slog.Logger {
	if s.Log != nil {
		return s.Log
	}
	return slog.Default()
}

func (s *Service) asUser(ctx context.Context, p *auth.Principal, fn func(q *db.Queries) error) error {
	return platformdb.AsUser(ctx, s.Pool, p.UserID, func(tx pgx.Tx) error { return fn(db.New(tx)) })
}

func (s *Service) system(ctx context.Context, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return platformdb.InTx(ctx, s.Pool, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

var prague = func() *time.Location {
	l, err := time.LoadLocation("Europe/Prague")
	if err != nil {
		return time.UTC
	}
	return l
}()

// I18n is a localized text.
type I18n struct {
	CS string `json:"cs"`
	EN string `json:"en"`
}

func i18n(b []byte) I18n {
	var t I18n
	_ = json.Unmarshal(b, &t)
	return t
}

// Pick returns the text in locale, falling back to the other language.
func (t I18n) Pick(locale string) string {
	if locale == "en" && t.EN != "" {
		return t.EN
	}
	if t.CS != "" {
		return t.CS
	}
	return t.EN
}

// ---------------------------------------------------------------------------
// Catalog.

// Product is a promo product with computed VAT.
type Product struct {
	db.PromoProduct
	VatAmount   int64
	GrossAmount int64
	Title       I18n
}

func product(p db.PromoProduct) Product {
	vat, gross := ComputeVAT(p.NetAmount, int(p.VatRateBp))
	return Product{PromoProduct: p, VatAmount: vat, GrossAmount: gross, Title: i18n(p.Name)}
}

// Products lists the active promo products (public catalog).
func (s *Service) Products(ctx context.Context) ([]Product, error) {
	rows, err := db.New(s.Pool).ListPromoProducts(ctx, false)
	if err != nil {
		return nil, err
	}
	out := make([]Product, 0, len(rows))
	for _, r := range rows {
		out = append(out, product(r))
	}
	return out, nil
}

// ---------------------------------------------------------------------------
// Checkout.

// CheckoutRequest starts a promo purchase.
type CheckoutRequest struct {
	OrgID       uuid.UUID
	ListingID   uuid.UUID
	ProductCode string
	StartsAt    *time.Time
	SuccessURL  string
	CancelURL   string
}

// CheckoutResult is the created order and where to pay it.
type CheckoutResult struct {
	OrderID     uuid.UUID
	CheckoutURL string
}

// sameOrigin reports whether raw is an absolute http(s) URL on a web origin
// (WebBaseURL or an origin from RedirectAllow), so Stripe's success/cancel
// URLs cannot be used as an open redirect.
func (s *Service) sameOrigin(raw string) bool {
	u, err := url.Parse(raw)
	if err != nil || u.User != nil || u.Host == "" {
		return false
	}
	for _, allowed := range append([]string{s.WebBaseURL}, s.RedirectAllow...) {
		base, err := url.Parse(allowed)
		if err != nil || base.Host == "" || (base.Scheme != "http" && base.Scheme != "https") {
			continue
		}
		if strings.EqualFold(u.Scheme, base.Scheme) && strings.EqualFold(u.Host, base.Host) {
			return true
		}
	}
	return false
}

// Checkout creates a pending order for a published listing and a Stripe
// Checkout session for it. The order turns paid only by the signed webhook.
func (s *Service) Checkout(ctx context.Context, p *auth.Principal, in CheckoutRequest) (CheckoutResult, error) {
	if !s.sameOrigin(in.SuccessURL) || !s.sameOrigin(in.CancelURL) {
		return CheckoutResult{}, apperr.Unprocessable("invalid_redirect", "success_url and cancel_url must point to the web application")
	}
	now := s.now()
	starts := now
	if in.StartsAt != nil {
		if in.StartsAt.Before(now.Add(-5 * time.Minute)) {
			return CheckoutResult{}, apperr.Unprocessable("invalid_starts_at", "the start cannot be in the past")
		}
		if in.StartsAt.After(now.AddDate(1, 0, 0)) {
			return CheckoutResult{}, apperr.Unprocessable("invalid_starts_at", "the start can be at most one year ahead")
		}
		if in.StartsAt.After(now) {
			starts = *in.StartsAt
		}
	}
	var order db.Order
	var prod Product
	var title I18n
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, in.OrgID, org.PermCatalogWrite); err != nil {
			return err
		}
		l, err := q.GetListing(ctx, db.GetListingParams{ID: in.ListingID, OrgID: in.OrgID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("listing_not_found", "listing not found")
		}
		if err != nil {
			return err
		}
		if l.Status != "published" {
			return apperr.Conflict("listing_not_published", "only a published listing can be promoted")
		}
		title = i18n(l.Title)
		pp, err := q.GetActivePromoProductByCode(ctx, in.ProductCode)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.Unprocessable("unknown_product", "unknown or inactive promo product")
		}
		if err != nil {
			return err
		}
		prod = product(pp)
		uid := p.UserID
		order, err = q.CreateOrder(ctx, db.CreateOrderParams{OrgID: in.OrgID, ListingID: in.ListingID, ProductID: pp.ID,
			Kind: pp.Kind, DurationDays: pp.DurationDays, CreatedBy: &uid, NetAmount: pp.NetAmount, VatAmount: prod.VatAmount,
			GrossAmount: prod.GrossAmount, Currency: pp.Currency, VatRateBp: pp.VatRateBp, StartsAt: starts})
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &in.OrgID, Entity: "order", EntityID: &order.ID, Action: "billing.order_created",
			Diff: map[string]any{"listing_id": in.ListingID, "product": pp.Code, "gross_amount": prod.GrossAmount,
				"currency": pp.Currency, "starts_at": starts}})
	})
	if err != nil {
		return CheckoutResult{}, err
	}
	var email string
	_ = s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		uid := p.UserID
		b, err := q.InvoiceBuyer(ctx, db.InvoiceBuyerParams{UserID: &uid, OrgID: in.OrgID})
		email = b.Email
		return err
	})
	sess, err := s.Stripe.CreateCheckout(ctx, CheckoutInput{OrderID: order.ID.String(),
		Description: prod.Title.Pick("cs") + " – " + title.Pick("cs"), AmountGross: order.GrossAmount, Currency: order.Currency,
		CustomerEmail: email, SuccessURL: in.SuccessURL, CancelURL: in.CancelURL,
		Metadata: map[string]string{"org_id": in.OrgID.String(), "listing_id": in.ListingID.String(), "product": prod.Code}})
	if err != nil {
		s.log().Error("stripe checkout failed", "order_id", order.ID, "err", err)
		return CheckoutResult{}, apperr.Unavailable("payment_provider_unavailable", "the payment provider is not available, try again later")
	}
	err = s.asUser(ctx, p, func(q *db.Queries) error {
		sid := sess.ID
		return q.SetOrderSession(ctx, db.SetOrderSessionParams{ID: order.ID, StripeSessionID: &sid})
	})
	if err != nil {
		return CheckoutResult{}, err
	}
	return CheckoutResult{OrderID: order.ID, CheckoutURL: sess.URL}, nil
}

// ---------------------------------------------------------------------------
// Stripe webhook.

// ErrBadWebhook is returned for payloads that fail signature verification.
var ErrBadWebhook = apperr.BadRequest("invalid_signature", "invalid Stripe webhook signature")

// HandleWebhookBody reads a raw webhook body and processes it.
func (s *Service) HandleWebhookBody(ctx context.Context, body io.Reader, sig string) error {
	payload, err := io.ReadAll(io.LimitReader(body, MaxWebhookBody+1))
	if err != nil {
		return apperr.BadRequest("invalid_body", "cannot read body")
	}
	if len(payload) > MaxWebhookBody {
		return apperr.BadRequest("invalid_body", "body too large")
	}
	return s.HandleWebhook(ctx, payload, sig)
}

// HandleWebhook verifies and processes one Stripe event exactly once. A paid
// checkout marks the order paid, creates the promotions, updates the search
// row and issues the invoice in one transaction; a failure rolls everything
// back (including the idempotency record), so Stripe's retry processes it.
func (s *Service) HandleWebhook(ctx context.Context, payload []byte, sig string) error {
	ev, err := s.Stripe.ParseWebhook(payload, sig)
	if err != nil {
		if errors.Is(err, ErrInvalidSignature) || errors.Is(err, ErrExpiredSignature) {
			return ErrBadWebhook
		}
		return apperr.BadRequest("invalid_event", "cannot decode the event")
	}
	if ev.ID == "" {
		return apperr.BadRequest("invalid_event", "event without id")
	}
	var invoiceID *uuid.UUID
	err = s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		n, err := q.InsertStripeEvent(ctx, db.InsertStripeEventParams{ID: ev.ID, Type: ev.Type})
		if err != nil {
			return err
		}
		if n == 0 {
			return nil // already processed
		}
		switch ev.Type {
		case EventCheckoutCompleted, EventCheckoutAsyncSucceeded:
			// A delayed payment method completes the session unpaid and
			// reports the money later (async_payment_succeeded).
			if ev.PaymentStatus != "paid" {
				return nil
			}
			id, err := s.orderPaid(ctx, q, tx, ev)
			invoiceID = id
			return err
		case EventCheckoutExpired, EventCheckoutAsyncFailed:
			sid := ev.SessionID
			o, err := q.SystemGetOrderBySession(ctx, &sid)
			if errors.Is(err, pgx.ErrNoRows) {
				return nil
			}
			if err != nil {
				return err
			}
			n, err := q.SetOrderStatusBySession(ctx, db.SetOrderStatusBySessionParams{Status: "canceled", StripeSessionID: &sid})
			if err != nil || n == 0 {
				return err
			}
			return audit.Record(ctx, q, audit.Event{OrgID: &o.OrgID, Entity: "order", EntityID: &o.ID, Action: "billing.order_canceled",
				Diff: map[string]any{"stripe_event": ev.ID}})
		}
		return nil
	})
	if err != nil {
		return err
	}
	if invoiceID != nil && s.Jobs == nil {
		if err := s.DeliverInvoice(ctx, *invoiceID); err != nil {
			s.log().Error("invoice delivery failed", "invoice_id", *invoiceID, "err", err)
		}
	}
	return nil
}

func promotionKinds(kind string) []string {
	switch kind {
	case "bundle":
		return []string{"top", "highlight"}
	case "top", "highlight":
		return []string{kind}
	}
	return nil
}

// orderPaid runs inside the webhook transaction. An event whose order does
// not match the session's order is checked before anything is written: it
// is logged and audited and acknowledged (2xx), because Stripe's retries
// would only repeat the mismatch for three days.
func (s *Service) orderPaid(ctx context.Context, q *db.Queries, tx pgx.Tx, ev Event) (*uuid.UUID, error) {
	sid := ev.SessionID
	cur, err := q.SystemGetOrderBySession(ctx, &sid)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil // unknown session
	}
	if err != nil {
		return nil, err
	}
	if ev.OrderID != "" && ev.OrderID != cur.ID.String() {
		s.log().Error("stripe event order does not match the session's order", "event_id", ev.ID,
			"event_order", ev.OrderID, "session_order", cur.ID)
		return nil, audit.Record(ctx, q, audit.Event{OrgID: &cur.OrgID, Entity: "order", EntityID: &cur.ID,
			Action: "billing.webhook_mismatch", Diff: map[string]any{"stripe_event": ev.ID, "event_order": ev.OrderID}})
	}
	o, err := q.MarkOrderPaidBySession(ctx, &sid)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil // already paid (or canceled)
	}
	if err != nil {
		return nil, err
	}
	now := s.now()
	paidAt := now
	if o.PaidAt != nil {
		paidAt = *o.PaidAt
	}
	start := o.StartsAt
	if start.Before(now) {
		start = now
	}
	// Serializes promotion windows of the listing (PromotionEndOf + CreatePromotion).
	if _, err := q.LockListing(ctx, o.ListingID); err != nil {
		return nil, err
	}
	var windows []map[string]any
	for _, kind := range promotionKinds(o.Kind) {
		from, err := q.PromotionEndOf(ctx, db.PromotionEndOfParams{StartsAt: start, ListingID: o.ListingID, Kind: kind})
		if err != nil {
			return nil, err
		}
		to := from.AddDate(0, 0, int(o.DurationDays))
		if err := q.CreatePromotion(ctx, db.CreatePromotionParams{OrgID: o.OrgID, ListingID: o.ListingID, OrderID: o.ID,
			Kind: kind, StartsAt: from, EndsAt: to}); err != nil {
			return nil, err
		}
		windows = append(windows, map[string]any{"kind": kind, "starts_at": from, "ends_at": to})
	}
	if err := q.RecomputeListingPromo(ctx, db.RecomputeListingPromoParams{At: now, ListingID: o.ListingID}); err != nil {
		return nil, err
	}
	if err := audit.Record(ctx, q, audit.Event{OrgID: &o.OrgID, Entity: "order", EntityID: &o.ID, Action: "billing.order_paid",
		ActorID: o.CreatedBy, Diff: map[string]any{"stripe_event": ev.ID, "promotions": windows}}); err != nil {
		return nil, err
	}

	// Invoice (daňový doklad): DUZP = payment date, gapless yearly number.
	day := paidAt.In(prague)
	seq, err := q.NextInvoiceNumber(ctx, int32(day.Year()))
	if err != nil {
		return nil, err
	}
	b, err := q.InvoiceBuyer(ctx, db.InvoiceBuyerParams{UserID: o.CreatedBy, OrgID: o.OrgID})
	if err != nil {
		return nil, err
	}
	buyer := buyerOf(b)
	buyerJSON, _ := json.Marshal(buyer)
	supplierJSON, _ := json.Marshal(s.Supplier)
	date := pgtype.Date{Time: time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, time.UTC), Valid: true}
	inv, err := q.CreateInvoice(ctx, db.CreateInvoiceParams{OrgID: o.OrgID, OrderID: o.ID,
		Number: FormatInvoiceNumber(day.Year(), int(seq)), IssuedOn: date, TaxableSupplyOn: date, NetAmount: o.NetAmount,
		VatAmount: o.VatAmount, GrossAmount: o.GrossAmount, Currency: o.Currency, VatRateBp: o.VatRateBp,
		Buyer: buyerJSON, Supplier: supplierJSON})
	if err != nil {
		return nil, err
	}
	if err := audit.Record(ctx, q, audit.Event{OrgID: &o.OrgID, Entity: "invoice", EntityID: &inv.ID, Action: "billing.invoice_issued",
		ActorID: o.CreatedBy, Diff: map[string]any{"number": inv.Number, "order_id": o.ID, "gross_amount": inv.GrossAmount}}); err != nil {
		return nil, err
	}
	if s.Jobs != nil {
		if err := s.Jobs.DeliverInvoice(ctx, tx, inv.ID); err != nil {
			return nil, err
		}
	}
	return &inv.ID, nil
}

// invoiceBuyer is the stored buyer: the invoice party plus delivery data.
type invoiceBuyer struct {
	Party
	Locale string `json:"locale,omitempty"`
}

func buyerOf(b db.InvoiceBuyerRow) invoiceBuyer {
	name := b.Name
	if b.Kind == "personal" && b.DisplayName != "" {
		name = b.DisplayName
	}
	out := invoiceBuyer{Party: Party{Name: name, Email: b.Email}, Locale: b.Locale}
	if b.RegistrationNo != nil {
		out.ICO = *b.RegistrationNo
	}
	if b.VatNo != nil {
		out.DIC = *b.VatNo
	}
	return out
}

// ---------------------------------------------------------------------------
// Invoices.

// invoiceData rebuilds the tax document from the stored invoice and order.
func (s *Service) invoiceData(ctx context.Context, q *db.Queries, inv db.Invoice) (InvoiceData, invoiceBuyer, db.GetOrderRow, error) {
	o, err := q.GetOrder(ctx, db.GetOrderParams{ID: inv.OrderID, OrgID: inv.OrgID})
	if err != nil {
		return InvoiceData{}, invoiceBuyer{}, o, err
	}
	pp, err := q.GetPromoProduct(ctx, o.ProductID)
	if err != nil {
		return InvoiceData{}, invoiceBuyer{}, o, err
	}
	var buyer invoiceBuyer
	_ = json.Unmarshal(inv.Buyer, &buyer)
	var supplier Party
	_ = json.Unmarshal(inv.Supplier, &supplier)
	desc := fmt.Sprintf("%s – %s", i18n(pp.Name).Pick("cs"), i18n(o.ListingTitle).Pick("cs"))
	d := InvoiceData{Number: inv.Number, IssuedOn: inv.IssuedOn.Time, TaxableSupplyOn: inv.TaxableSupplyOn.Time,
		DueOn: inv.IssuedOn.Time, Supplier: supplier, Buyer: buyer.Party, Currency: inv.Currency,
		Lines:    []InvoiceLine{NewInvoiceLine(desc, 1, inv.NetAmount, int(inv.VatRateBp))},
		OrderRef: o.ID.String(), PaymentMethod: PaymentMethodCardPaid,
		Simplified: Simplified(inv.Currency, inv.GrossAmount, buyer.DIC)}
	return d, buyer, o, nil
}

func invoiceKey(inv db.Invoice) string {
	return fmt.Sprintf("invoices/%s/%s.pdf", inv.OrgID, inv.ID)
}

// renderAndStore renders the PDF and stores it; ErrNoTypst is returned as is.
func (s *Service) renderAndStore(ctx context.Context, inv db.Invoice, d InvoiceData) ([]byte, error) {
	pdf, err := s.Invoices.Render(ctx, d)
	if err != nil {
		return nil, err
	}
	key := invoiceKey(inv)
	if err := s.Blob.Put(ctx, key, "application/pdf", pdf); err != nil {
		return nil, err
	}
	err = s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		return q.SetInvoicePdfKey(ctx, db.SetInvoicePdfKeyParams{ID: inv.ID, PdfKey: &key})
	})
	return pdf, err
}

// DeliverInvoice (background job) renders and stores the PDF and e-mails the
// buyer a link to the invoices page. Without typst (dev) the e-mail still
// goes out and the PDF is rendered on first download. Repeated runs are
// harmless: a stored PDF is kept and the e-mail is sent once.
func (s *Service) DeliverInvoice(ctx context.Context, id uuid.UUID) error {
	var inv db.Invoice
	var d InvoiceData
	var buyer invoiceBuyer
	var o db.GetOrderRow
	err := s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		if inv, err = q.SystemGetInvoice(ctx, id); err != nil {
			return err
		}
		d, buyer, o, err = s.invoiceData(ctx, q, inv)
		return err
	})
	if err != nil {
		return err
	}
	if inv.PdfKey == nil {
		if _, err := s.renderAndStore(ctx, inv, d); errors.Is(err, ErrNoTypst) {
			s.log().Warn("typst not installed, invoice PDF rendered on demand later", "invoice_id", inv.ID)
		} else if err != nil {
			return err
		}
	}
	if inv.SentAt != nil || buyer.Email == "" || s.Outbox == nil || s.Mail == nil {
		return nil
	}
	locale := buyer.Locale
	if locale == "" {
		locale = "cs"
	}
	pp, _ := s.productByID(ctx, o.ProductID)
	return s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		m, err := s.Mail.Render(notify.Email, buyer.Email, locale, "invoice_issued", map[string]any{
			"Number": inv.Number, "Amount": FormatAmount(inv.GrossAmount, inv.Currency), "Product": pp.Pick(locale),
			"Listing": i18n(o.ListingTitle).Pick(locale),
			"Link":    strings.TrimRight(s.WebBaseURL, "/") + "/admin/orgs/" + inv.OrgID.String() + "/fakturace"})
		if err != nil {
			return err
		}
		if err := s.Outbox.Enqueue(ctx, tx, m); err != nil {
			return err
		}
		if err := q.MarkInvoiceSent(ctx, inv.ID); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &inv.OrgID, Entity: "invoice", EntityID: &inv.ID, Action: "billing.invoice_sent",
			ActorID: o.CreatedBy, Diff: map[string]any{"number": inv.Number}})
	})
}

func (s *Service) productByID(ctx context.Context, id uuid.UUID) (I18n, error) {
	pp, err := db.New(s.Pool).GetPromoProduct(ctx, id)
	if err != nil {
		return I18n{}, err
	}
	return i18n(pp.Name), nil
}

// Order is an order with its product code and listing title.
type Order struct {
	db.Order
	ProductCode  string
	ListingTitle I18n
	InvoiceID    *uuid.UUID
}

func orderOf(o db.Order, code string, title []byte, inv *uuid.UUID) Order {
	return Order{Order: o, ProductCode: code, ListingTitle: i18n(title), InvoiceID: inv}
}

// Orders lists the organization's orders.
func (s *Service) Orders(ctx context.Context, p *auth.Principal, orgID uuid.UUID) ([]Order, error) {
	var out []Order
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermFinanceRead); err != nil {
			return err
		}
		rows, err := q.ListOrders(ctx, orgID)
		for _, r := range rows {
			out = append(out, orderOf(db.Order{ID: r.ID, OrgID: r.OrgID, ListingID: r.ListingID, ProductID: r.ProductID, Kind: r.Kind,
				DurationDays: r.DurationDays, CreatedBy: r.CreatedBy, Status: r.Status, NetAmount: r.NetAmount, VatAmount: r.VatAmount,
				GrossAmount: r.GrossAmount, Currency: r.Currency, VatRateBp: r.VatRateBp, StartsAt: r.StartsAt,
				StripeSessionID: r.StripeSessionID, CreatedAt: r.CreatedAt, PaidAt: r.PaidAt}, r.ProductCode, r.ListingTitle, r.InvoiceID))
		}
		return err
	})
	return out, err
}

// Order returns one order of the organization.
func (s *Service) Order(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) (Order, error) {
	var out Order
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermFinanceRead); err != nil {
			return err
		}
		r, err := q.GetOrder(ctx, db.GetOrderParams{ID: id, OrgID: orgID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("order_not_found", "order not found")
		}
		if err != nil {
			return err
		}
		out = orderOf(db.Order{ID: r.ID, OrgID: r.OrgID, ListingID: r.ListingID, ProductID: r.ProductID, Kind: r.Kind,
			DurationDays: r.DurationDays, CreatedBy: r.CreatedBy, Status: r.Status, NetAmount: r.NetAmount, VatAmount: r.VatAmount,
			GrossAmount: r.GrossAmount, Currency: r.Currency, VatRateBp: r.VatRateBp, StartsAt: r.StartsAt,
			StripeSessionID: r.StripeSessionID, CreatedAt: r.CreatedAt, PaidAt: r.PaidAt}, r.ProductCode, r.ListingTitle, r.InvoiceID)
		return nil
	})
	return out, err
}

// Promotions lists the promotions of a listing.
func (s *Service) Promotions(ctx context.Context, p *auth.Principal, orgID, listingID uuid.UUID) ([]db.ListListingPromotionsRow, error) {
	var out []db.ListListingPromotionsRow
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogRead); err != nil {
			return err
		}
		if _, err := q.GetListing(ctx, db.GetListingParams{ID: listingID, OrgID: orgID}); errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("listing_not_found", "listing not found")
		} else if err != nil {
			return err
		}
		var err error
		out, err = q.ListListingPromotions(ctx, db.ListListingPromotionsParams{ListingID: listingID, OrgID: orgID})
		return err
	})
	return out, err
}

// InvoiceList lists the organization's invoices.
func (s *Service) InvoiceList(ctx context.Context, p *auth.Principal, orgID uuid.UUID) ([]db.Invoice, error) {
	var out []db.Invoice
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermFinanceRead); err != nil {
			return err
		}
		var err error
		out, err = q.ListInvoices(ctx, orgID)
		return err
	})
	return out, err
}

// InvoicePDF returns the invoice PDF, rendering it on demand when it was not
// stored yet (typst was missing when the invoice was issued).
func (s *Service) InvoicePDF(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) ([]byte, string, error) {
	var inv db.Invoice
	var d InvoiceData
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermFinanceRead); err != nil {
			return err
		}
		var err error
		inv, err = q.GetInvoice(ctx, db.GetInvoiceParams{ID: id, OrgID: orgID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("invoice_not_found", "invoice not found")
		}
		if err != nil {
			return err
		}
		if inv.PdfKey == nil {
			d, _, _, err = s.invoiceData(ctx, q, inv)
		}
		return err
	})
	if err != nil {
		return nil, "", err
	}
	name := "faktura-" + inv.Number + ".pdf"
	if inv.PdfKey != nil {
		b, err := s.Blob.Get(ctx, *inv.PdfKey)
		if err == nil {
			return b, name, nil
		}
		if !errors.Is(err, storage.ErrNotFound) {
			return nil, "", err
		}
		if err := s.asUser(ctx, p, func(q *db.Queries) error {
			var err error
			d, _, _, err = s.invoiceData(ctx, q, inv)
			return err
		}); err != nil {
			return nil, "", err
		}
	}
	pdf, err := s.renderAndStore(ctx, inv, d)
	if errors.Is(err, ErrNoTypst) {
		return nil, "", apperr.Unavailable("pdf_unavailable", "the PDF renderer is not installed")
	}
	return pdf, name, err
}

// RecomputePromos (periodic job) starts scheduled promotions and clears
// expired ones on the search rows.
func (s *Service) RecomputePromos(ctx context.Context) (int64, error) {
	var n int64
	err := s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		n, err = q.RecomputeAllListingPromos(ctx)
		return err
	})
	return n, err
}

// ---------------------------------------------------------------------------
// Revolut Business (landlord-direct).

// RevolutAccount is the connection state (never the key).
type RevolutAccount struct {
	Connected   bool
	Mode        string
	ConnectedAt *time.Time
}

// RevolutAccount returns the organization's Revolut connection.
func (s *Service) RevolutAccount(ctx context.Context, p *auth.Principal, orgID uuid.UUID) (RevolutAccount, error) {
	if err := s.revolutEnabled(ctx); err != nil {
		return RevolutAccount{}, err
	}
	var out RevolutAccount
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermFinanceRead); err != nil {
			return err
		}
		a, err := q.GetRevolutAccount(ctx, orgID)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil
		}
		if err != nil {
			return err
		}
		at := a.ConnectedAt
		out = RevolutAccount{Connected: true, Mode: a.Mode, ConnectedAt: &at}
		return nil
	})
	return out, err
}

// ConnectRevolut stores the landlord's merchant API key (sealed).
func (s *Service) ConnectRevolut(ctx context.Context, p *auth.Principal, orgID uuid.UUID, apiKey, mode string) (RevolutAccount, error) {
	if err := s.revolutEnabled(ctx); err != nil {
		return RevolutAccount{}, err
	}
	apiKey = strings.TrimSpace(apiKey)
	if len(apiKey) < 8 || len(apiKey) > 500 {
		return RevolutAccount{}, apperr.Unprocessable("invalid_api_key", "the API key has 8 to 500 characters")
	}
	if mode != "sandbox" && mode != "live" {
		return RevolutAccount{}, apperr.Unprocessable("invalid_mode", "mode is sandbox or live")
	}
	sealed, err := s.Box.Seal([]byte(apiKey))
	if err != nil {
		return RevolutAccount{}, err
	}
	var out RevolutAccount
	err = s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermOrgManage); err != nil {
			return err
		}
		uid := p.UserID
		a, err := q.UpsertRevolutAccount(ctx, db.UpsertRevolutAccountParams{OrgID: orgID, ApiKeyEnc: sealed, Mode: mode, ConnectedBy: &uid})
		if err != nil {
			return err
		}
		at := a.ConnectedAt
		out = RevolutAccount{Connected: true, Mode: a.Mode, ConnectedAt: &at}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "org_revolut_account", EntityID: &orgID,
			Action: "billing.revolut_connected", Diff: map[string]any{"mode": mode}})
	})
	return out, err
}

// DisconnectRevolut removes the merchant API key.
func (s *Service) DisconnectRevolut(ctx context.Context, p *auth.Principal, orgID uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermOrgManage); err != nil {
			return err
		}
		n, err := q.DeleteRevolutAccount(ctx, orgID)
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.NotFound("revolut_not_connected", "no Revolut account is connected")
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "org_revolut_account", EntityID: &orgID,
			Action: "billing.revolut_disconnected"})
	})
}

func (s *Service) revolutEnabled(ctx context.Context) error {
	if s.Flags == nil || !s.Flags.Enabled(ctx, FlagRevolut) {
		return apperr.NotFound("feature_disabled", "Revolut payment links are not enabled")
	}
	return nil
}

// share loads an obligation share as the caller and checks that the caller
// is its party or a member of the owning organization.
func (s *Service) share(ctx context.Context, p *auth.Principal) func(q *db.Queries, id uuid.UUID) (db.GetShareForPaymentLinkRow, error) {
	return func(q *db.Queries, id uuid.UUID) (db.GetShareForPaymentLinkRow, error) {
		sh, err := q.GetShareForPaymentLink(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			return sh, apperr.NotFound("share_not_found", "payment share not found")
		}
		if err != nil {
			return sh, err
		}
		if sh.PartyUserID != nil && *sh.PartyUserID == p.UserID {
			return sh, nil
		}
		if _, err := org.Access(ctx, q, p.UserID, sh.OrgID, org.PermFinanceRead); err != nil {
			var ae *apperr.Error
			if errors.As(err, &ae) && ae.Status == 403 {
				return sh, err
			}
			return sh, apperr.NotFound("share_not_found", "payment share not found")
		}
		return sh, nil
	}
}

// PaymentLink returns the latest usable payment link of a share.
func (s *Service) PaymentLink(ctx context.Context, p *auth.Principal, shareID uuid.UUID) (db.PaymentLink, error) {
	if err := s.revolutEnabled(ctx); err != nil {
		return db.PaymentLink{}, err
	}
	var out db.PaymentLink
	load := s.share(ctx, p)
	err := s.asUser(ctx, p, func(q *db.Queries) error {
		if _, err := load(q, shareID); err != nil {
			return err
		}
		var err error
		out, err = q.GetLatestPaymentLink(ctx, shareID)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("payment_link_not_found", "no payment link yet")
		}
		return err
	})
	return out, err
}

// PaymentLinkTTL is how long a created link can be paid.
const PaymentLinkTTL = 7 * 24 * time.Hour

// CreatePaymentLink creates a Revolut order in the landlord's own merchant
// account for the unpaid rest of a share. The money goes landlord-direct
// (ADR 0002); the platform stores only the link.
func (s *Service) CreatePaymentLink(ctx context.Context, p *auth.Principal, shareID uuid.UUID) (db.PaymentLink, error) {
	if err := s.revolutEnabled(ctx); err != nil {
		return db.PaymentLink{}, err
	}
	var sh db.GetShareForPaymentLinkRow
	load := s.share(ctx, p)
	if err := s.asUser(ctx, p, func(q *db.Queries) error {
		var err error
		sh, err = load(q, shareID)
		return err
	}); err != nil {
		return db.PaymentLink{}, err
	}
	amount := sh.Amount - sh.PaidAmount
	if amount <= 0 {
		return db.PaymentLink{}, apperr.Conflict("share_paid", "this share is already paid")
	}
	// System context only to read the sealed key of the landlord.
	var sealed []byte
	err := s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		a, err := q.GetRevolutAccount(ctx, sh.OrgID)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.Conflict("revolut_not_connected", "the landlord has not connected a Revolut Business account")
		}
		sealed = a.ApiKeyEnc
		return err
	})
	if err != nil {
		return db.PaymentLink{}, err
	}
	key, err := s.Box.Open(sealed)
	if err != nil {
		return db.PaymentLink{}, fmt.Errorf("open revolut key: %w", err)
	}
	exp := s.now().Add(PaymentLinkTTL)
	desc := fmt.Sprintf("%s %s", sh.Kind, sh.Period)
	if sh.DueOn.Valid {
		desc += ", splatnost " + FormatDate(sh.DueOn.Time)
	}
	ro, err := s.Revolut.CreateOrder(ctx, string(key), RevolutOrderInput{Amount: amount, Currency: sh.Currency,
		Description: desc, MerchantOrderRef: "share-" + sh.ID.String(), ExpiresAt: &exp})
	if err != nil {
		s.log().Error("revolut create order failed", "share_id", sh.ID, "err", err)
		return db.PaymentLink{}, apperr.Unavailable("payment_provider_unavailable", "Revolut is not available, try again later")
	}
	var out db.PaymentLink
	err = s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		uid := p.UserID
		var err error
		out, err = q.CreatePaymentLink(ctx, db.CreatePaymentLinkParams{OrgID: sh.OrgID, LeaseID: sh.LeaseID, ShareID: sh.ID,
			Provider: "revolut", ExternalID: ro.ID, Url: ro.CheckoutURL, Amount: amount, Currency: sh.Currency, ExpiresAt: &exp,
			CreatedBy: &uid})
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &sh.OrgID, Entity: "payment_link", EntityID: &out.ID,
			Action: "billing.payment_link_created", Diff: map[string]any{"share_id": sh.ID, "lease_id": sh.LeaseID,
				"amount": amount, "currency": sh.Currency, "provider": "revolut"}})
	})
	return out, err
}
