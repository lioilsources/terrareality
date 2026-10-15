package jobs

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/riverqueue/river"
)

// PromoRecomputeArgs refreshes the promotion windows on the search rows:
// scheduled promotions start and expired ones end without a request.
type PromoRecomputeArgs struct{}

// Kind implements river.JobArgs.
func (PromoRecomputeArgs) Kind() string { return "promo_recompute" }

// PromoRecomputer is implemented by billing.Service.
type PromoRecomputer interface {
	RecomputePromos(ctx context.Context) (int64, error)
}

// PromoRecomputeWorker runs PromoRecomputeArgs.
type PromoRecomputeWorker struct {
	river.WorkerDefaults[PromoRecomputeArgs]
	Runner PromoRecomputer
}

// Work implements river.Worker.
func (w *PromoRecomputeWorker) Work(ctx context.Context, _ *river.Job[PromoRecomputeArgs]) error {
	_, err := w.Runner.RecomputePromos(ctx)
	return err
}

// InvoiceDeliveryArgs renders, stores and e-mails one invoice.
type InvoiceDeliveryArgs struct {
	InvoiceID uuid.UUID `json:"invoice_id"`
}

// Kind implements river.JobArgs.
func (InvoiceDeliveryArgs) Kind() string { return "invoice_delivery" }

// InvoiceDeliverer is implemented by billing.Service.
type InvoiceDeliverer interface {
	DeliverInvoice(ctx context.Context, id uuid.UUID) error
}

// InvoiceDeliveryWorker runs InvoiceDeliveryArgs.
type InvoiceDeliveryWorker struct {
	river.WorkerDefaults[InvoiceDeliveryArgs]
	Runner InvoiceDeliverer
}

// Work implements river.Worker.
func (w *InvoiceDeliveryWorker) Work(ctx context.Context, j *river.Job[InvoiceDeliveryArgs]) error {
	return w.Runner.DeliverInvoice(ctx, j.Args.InvoiceID)
}

// Timeout covers a typst render.
func (w *InvoiceDeliveryWorker) Timeout(*river.Job[InvoiceDeliveryArgs]) time.Duration {
	return 2 * time.Minute
}

// BillingJobs implements billing.Jobs with River.
type BillingJobs struct{ Client *river.Client[pgx.Tx] }

// DeliverInvoice implements billing.Jobs.
func (b BillingJobs) DeliverInvoice(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
	_, err := b.Client.InsertTx(ctx, tx, InvoiceDeliveryArgs{InvoiceID: id}, nil)
	return err
}
