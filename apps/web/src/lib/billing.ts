import type { components } from '@terra/contracts';
import { m } from '#lib/paraglide/messages.js';

export type PromoProduct = components['schemas']['PromoProduct'];
export type Promotion = components['schemas']['Promotion'];
export type Order = components['schemas']['Order'];
export type OrderStatus = components['schemas']['OrderStatus'];
export type Invoice = components['schemas']['Invoice'];
export type RevolutAccount = components['schemas']['RevolutAccount'];

/** Availability of the Revolut payment link next to a share. */
export type RevolutState = 'on' | 'connect' | 'off';

/** Exact amount with minor units (invoices and prices with VAT are not whole crowns). */
export function fmtAmount(minor: number, currency: string, locale: string): string {
	return new Intl.NumberFormat(locale === 'en' ? 'en-GB' : 'cs-CZ', {
		style: 'currency',
		currency: currency || 'CZK',
		minimumFractionDigits: 2
	}).format(minor / 100);
}

export const fmtVatRate = (bp: number) => `${bp / 100} %`;

export const orderStatusLabel: Record<OrderStatus, () => string> = {
	pending: m.billing_status_pending,
	paid: m.billing_status_paid,
	failed: m.billing_status_failed,
	canceled: m.billing_status_canceled
};

/** Badge classes (text always accompanies the color). */
export const orderStatusClass: Record<OrderStatus, string> = {
	pending: 'bg-amber-100 text-amber-900 dark:bg-amber-900/40 dark:text-amber-100',
	paid: 'bg-emerald-100 text-emerald-900 dark:bg-emerald-900/40 dark:text-emerald-100',
	failed: 'bg-red-100 text-red-900 dark:bg-red-900/40 dark:text-red-100',
	canceled: 'bg-[var(--border)]/60 text-[var(--text)]'
};

export const promoKindLabel: Record<string, () => string> = {
	top: m.billing_kind_top,
	highlight: m.billing_kind_highlight,
	bundle: m.billing_kind_bundle
};

export const isUuid = (s: string | null | undefined) =>
	!!s && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
