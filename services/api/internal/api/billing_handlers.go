package api

import (
	"bytes"
	"context"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/billing"
	dbq "github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

func (s *Server) billingSvc() (*billing.Service, error) {
	if s.Billing == nil {
		return nil, apperr.Unavailable("billing_unavailable", "billing is not configured")
	}
	return s.Billing, nil
}

func promoProductDTO(p billing.Product) gen.PromoProduct {
	return gen.PromoProduct{Id: p.ID, Code: p.Code, Kind: gen.PromoProductKind(p.Kind), DurationDays: int(p.DurationDays),
		NetAmount: p.NetAmount, VatRateBp: int(p.VatRateBp), VatAmount: p.VatAmount, GrossAmount: p.GrossAmount,
		Currency: p.Currency, Name: gen.I18nText{Cs: p.Title.CS, En: p.Title.EN}, Active: p.Active}
}

func orderDTO(o billing.Order) gen.Order {
	return gen.Order{Id: o.ID, ListingId: o.ListingID, ListingTitle: o.ListingTitle.Pick("cs"), ProductCode: o.ProductCode,
		Status: gen.OrderStatus(o.Status), NetAmount: o.NetAmount, VatAmount: o.VatAmount, GrossAmount: o.GrossAmount,
		Currency: o.Currency, StartsAt: o.StartsAt, CreatedAt: o.CreatedAt, PaidAt: o.PaidAt, InvoiceId: o.InvoiceID}
}

func invoiceDTO(i dbq.Invoice) gen.Invoice {
	return gen.Invoice{Id: i.ID, Number: i.Number, OrderId: i.OrderID, IssuedOn: *dayDTO(&i.IssuedOn.Time),
		TaxableSupplyOn: *dayDTO(&i.TaxableSupplyOn.Time), NetAmount: i.NetAmount, VatAmount: i.VatAmount,
		GrossAmount: i.GrossAmount, Currency: i.Currency, VatRateBp: int(i.VatRateBp), SentAt: i.SentAt}
}

func revolutDTO(a billing.RevolutAccount) gen.RevolutAccount {
	out := gen.RevolutAccount{Connected: a.Connected, ConnectedAt: a.ConnectedAt}
	if a.Mode != "" {
		m := gen.RevolutMode(a.Mode)
		out.Mode = &m
	}
	return out
}

func paymentLinkDTO(l dbq.PaymentLink) gen.PaymentLink {
	return gen.PaymentLink{Id: l.ID, ShareId: l.ShareID, Provider: gen.PaymentLinkProvider(l.Provider), Url: l.Url,
		Amount: l.Amount, Currency: l.Currency, Status: gen.PaymentLinkStatus(l.Status), ExpiresAt: l.ExpiresAt, CreatedAt: l.CreatedAt}
}

// ListPromoProducts implements GET /v1/promo-products.
func (s *Server) ListPromoProducts(ctx context.Context, _ gen.ListPromoProductsRequestObject) (gen.ListPromoProductsResponseObject, error) {
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	items, err := b.Products(ctx)
	if err != nil {
		return nil, err
	}
	out := gen.ListPromoProducts200JSONResponse{Items: []gen.PromoProduct{}}
	for _, p := range items {
		out.Items = append(out.Items, promoProductDTO(p))
	}
	return out, nil
}

// CreatePromoCheckout implements POST /v1/orgs/{orgId}/listings/{listingId}/promotions/checkout.
func (s *Server) CreatePromoCheckout(ctx context.Context, r gen.CreatePromoCheckoutRequestObject) (gen.CreatePromoCheckoutResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	if r.Body == nil {
		return nil, apperr.BadRequest("invalid_request", "body required")
	}
	res, err := b.Checkout(ctx, p, billing.CheckoutRequest{OrgID: r.OrgId, ListingID: r.ListingId, ProductCode: r.Body.ProductCode,
		StartsAt: r.Body.StartsAt, SuccessURL: r.Body.SuccessUrl, CancelURL: r.Body.CancelUrl})
	if err != nil {
		return nil, err
	}
	return gen.CreatePromoCheckout201JSONResponse{OrderId: res.OrderID, CheckoutUrl: res.CheckoutURL}, nil
}

// ListPromotions implements GET /v1/orgs/{orgId}/listings/{listingId}/promotions.
func (s *Server) ListPromotions(ctx context.Context, r gen.ListPromotionsRequestObject) (gen.ListPromotionsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	rows, err := b.Promotions(ctx, p, r.OrgId, r.ListingId)
	if err != nil {
		return nil, err
	}
	out := gen.ListPromotions200JSONResponse{Items: []gen.Promotion{}}
	for _, x := range rows {
		out.Items = append(out.Items, gen.Promotion{Id: x.ID, ListingId: x.ListingID, Kind: gen.PromotionKind(x.Kind),
			StartsAt: x.StartsAt, EndsAt: x.EndsAt, OrderId: x.OrderID, Active: x.Active})
	}
	return out, nil
}

// ListOrders implements GET /v1/orgs/{orgId}/orders.
func (s *Server) ListOrders(ctx context.Context, r gen.ListOrdersRequestObject) (gen.ListOrdersResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	lim := limitOf(r.Params.Limit)
	rows, err := b.Orders(ctx, p, r.OrgId, r.Params.Before, lim)
	if err != nil {
		return nil, err
	}
	out := gen.ListOrders200JSONResponse{Items: []gen.Order{}}
	for _, o := range rows {
		out.Items = append(out.Items, orderDTO(o))
	}
	if int32(len(rows)) == lim {
		out.NextBefore = &rows[len(rows)-1].ID
	}
	return out, nil
}

// GetOrder implements GET /v1/orgs/{orgId}/orders/{orderId}.
func (s *Server) GetOrder(ctx context.Context, r gen.GetOrderRequestObject) (gen.GetOrderResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	o, err := b.Order(ctx, p, r.OrgId, r.OrderId)
	if err != nil {
		return nil, err
	}
	return gen.GetOrder200JSONResponse(orderDTO(o)), nil
}

// ListInvoices implements GET /v1/orgs/{orgId}/invoices.
func (s *Server) ListInvoices(ctx context.Context, r gen.ListInvoicesRequestObject) (gen.ListInvoicesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	lim := limitOf(r.Params.Limit)
	rows, err := b.InvoiceList(ctx, p, r.OrgId, r.Params.Before, lim)
	if err != nil {
		return nil, err
	}
	out := gen.ListInvoices200JSONResponse{Items: []gen.Invoice{}}
	for _, i := range rows {
		out.Items = append(out.Items, invoiceDTO(i))
	}
	if int32(len(rows)) == lim {
		out.NextBefore = &rows[len(rows)-1].ID
	}
	return out, nil
}

// GetInvoicePdf implements GET /v1/orgs/{orgId}/invoices/{invoiceId}/pdf.
func (s *Server) GetInvoicePdf(ctx context.Context, r gen.GetInvoicePdfRequestObject) (gen.GetInvoicePdfResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	pdf, _, err := b.InvoicePDF(ctx, p, r.OrgId, r.InvoiceId)
	if err != nil {
		return nil, err
	}
	return gen.GetInvoicePdf200ApplicationpdfResponse{Body: bytes.NewReader(pdf), ContentLength: int64(len(pdf))}, nil
}

// StripeWebhook implements POST /v1/webhooks/stripe (no session; the
// Stripe-Signature header authenticates the raw body).
func (s *Server) StripeWebhook(ctx context.Context, r gen.StripeWebhookRequestObject) (gen.StripeWebhookResponseObject, error) {
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	sig := ""
	if r.Params.StripeSignature != nil {
		sig = *r.Params.StripeSignature
	}
	if err := b.HandleWebhookBody(ctx, r.Body, sig); err != nil {
		return nil, err
	}
	return gen.StripeWebhook204Response{}, nil
}

// GetRevolutAccount implements GET /v1/orgs/{orgId}/revolut.
func (s *Server) GetRevolutAccount(ctx context.Context, r gen.GetRevolutAccountRequestObject) (gen.GetRevolutAccountResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	a, err := b.RevolutAccount(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	return gen.GetRevolutAccount200JSONResponse(revolutDTO(a)), nil
}

// PutRevolutAccount implements PUT /v1/orgs/{orgId}/revolut.
func (s *Server) PutRevolutAccount(ctx context.Context, r gen.PutRevolutAccountRequestObject) (gen.PutRevolutAccountResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	if r.Body == nil {
		return nil, apperr.BadRequest("invalid_request", "body required")
	}
	a, err := b.ConnectRevolut(ctx, p, r.OrgId, r.Body.ApiKey, string(r.Body.Mode))
	if err != nil {
		return nil, err
	}
	return gen.PutRevolutAccount200JSONResponse(revolutDTO(a)), nil
}

// DeleteRevolutAccount implements DELETE /v1/orgs/{orgId}/revolut.
func (s *Server) DeleteRevolutAccount(ctx context.Context, r gen.DeleteRevolutAccountRequestObject) (gen.DeleteRevolutAccountResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	if err := b.DisconnectRevolut(ctx, p, r.OrgId); err != nil {
		return nil, err
	}
	return gen.DeleteRevolutAccount204Response{}, nil
}

// GetPaymentLink implements GET /v1/obligation-shares/{shareId}/payment-link.
func (s *Server) GetPaymentLink(ctx context.Context, r gen.GetPaymentLinkRequestObject) (gen.GetPaymentLinkResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	l, err := b.PaymentLink(ctx, p, r.ShareId)
	if err != nil {
		return nil, err
	}
	return gen.GetPaymentLink200JSONResponse(paymentLinkDTO(l)), nil
}

// CreatePaymentLink implements POST /v1/obligation-shares/{shareId}/payment-link.
func (s *Server) CreatePaymentLink(ctx context.Context, r gen.CreatePaymentLinkRequestObject) (gen.CreatePaymentLinkResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	b, err := s.billingSvc()
	if err != nil {
		return nil, err
	}
	l, err := b.CreatePaymentLink(ctx, p, r.ShareId)
	if err != nil {
		return nil, err
	}
	return gen.CreatePaymentLink201JSONResponse(paymentLinkDTO(l)), nil
}
