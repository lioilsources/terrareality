import QRCode from 'qrcode';
import { fail, redirect } from '@sveltejs/kit';
import type { ApiClient } from '@terra/contracts';
import { errorMessage } from '#lib/errors.js';
import { SIGN_PROVIDER } from '#lib/leasing.js';
import { m } from '#lib/paraglide/messages.js';

/** Loads a lease with its schedule, QR images of payable shares, the chain status and its risk. */
export async function loadLease(api: ApiClient, leaseId: string) {
	const path = { params: { path: { leaseId } } };
	const [detail, shares, events, risk] = await Promise.all([
		api.GET('/v1/leases/{leaseId}', path),
		api.GET('/v1/leases/{leaseId}/obligations', path),
		api.GET('/v1/leases/{leaseId}/events', path),
		api.GET('/v1/leases/{leaseId}/risk', path)
	]);
	if (!detail.data) return null;
	const withQR = await Promise.all(
		(shares.data ?? []).map(async (s) => ({
			...s,
			qr: s.spayd && s.mine ? await QRCode.toDataURL(s.spayd, { margin: 1, width: 200 }) : ''
		}))
	);
	return {
		detail: detail.data,
		shares: withQR,
		risk: risk.data ?? null,
		chain: events.data
			? { valid: events.data.valid, count: events.data.events.length, head: events.data.head }
			: null
	};
}

/**
 * The ?/sign action of the tenant and landlord lease pages: requires the explicit
 * confirmation checkbox, signs with the offered method and follows the provider's
 * redirect when the signature continues off-site (BankID).
 */
export async function signLease(api: ApiClient, leaseId: string, form: FormData) {
	if (form.get('confirm') !== 'on') return fail(400, { error: m.lease_sign_confirm_required() });
	const { data, error } = await api.POST('/v1/leases/{leaseId}/sign', {
		params: { path: { leaseId } },
		body: { provider: SIGN_PROVIDER }
	});
	if (error) return fail(400, { error: errorMessage(error) });
	if (!data.signed && data.redirect_url) redirect(303, data.redirect_url, { external: true });
	return { signed: data.signed };
}
