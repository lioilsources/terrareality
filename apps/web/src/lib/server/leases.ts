import QRCode from 'qrcode';
import { fail, redirect } from '@sveltejs/kit';
import type { ApiClient } from '@terra/contracts';
import { errorMessage } from '#lib/errors.js';
import { landlordNoticeFromForm, signProviderFromForm } from '#lib/leasing.js';
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
 * confirmation checkbox, signs with the chosen method (one of the lease detail's
 * sign_providers; the api answers invalid_provider otherwise) and follows the
 * provider's redirect when the signature continues off-site (Bank iD).
 */
export async function signLease(api: ApiClient, leaseId: string, form: FormData) {
	const provider = signProviderFromForm(form);
	if (!provider) return fail(400, { error: m.lease_sign_provider_required() });
	if (form.get('confirm') !== 'on') return fail(400, { error: m.lease_sign_confirm_required() });
	const { data, error } = await api.POST('/v1/leases/{leaseId}/sign', {
		params: { path: { leaseId } },
		body: { provider }
	});
	if (error) return fail(400, { error: errorMessage(error) });
	if (!data.signed && data.redirect_url) redirect(303, data.redirect_url, { external: true });
	return { signed: data.signed };
}

/** The landlord's ?/notice action: a statutory reason is required (§ 2288 OZ). */
export async function giveLandlordNotice(api: ApiClient, leaseId: string, form: FormData) {
	const parsed = landlordNoticeFromForm(form);
	if ('error' in parsed) return fail(400, { error: parsed.error, noticeError: true });
	const { data, error } = await api.POST('/v1/leases/{leaseId}/notice', {
		params: { path: { leaseId } },
		body: parsed.notice
	});
	if (error) return fail(400, { error: errorMessage(error), noticeError: true });
	return { endsOn: data.ends_on };
}

const scanTypes = ['application/pdf', 'image/jpeg', 'image/png'] as const;

/**
 * The ?/scan action of an imported lease: reserves an upload for the paper
 * contract's scan, PUTs the file to the presigned url and completes it (the
 * api checks type, size and viruses).
 */
export async function uploadContractScan(
	api: ApiClient,
	orgId: string,
	leaseId: string,
	form: FormData
) {
	const file = form.get('file');
	if (!(file instanceof File) || file.size === 0)
		return fail(400, { error: m.lease_scan_missing(), scanError: true });
	const type = scanTypes.find((t) => t === file.type);
	if (!type)
		return fail(400, {
			error: errorMessage({ status: 422, title: '', code: 'attachment_type' }),
			scanError: true
		});
	const path = { params: { path: { orgId, leaseId } } };
	const { data: slot, error } = await api.POST('/v1/orgs/{orgId}/leases/{leaseId}/contract-scan', {
		...path,
		body: { content_type: type, size_bytes: file.size }
	});
	if (!slot) return fail(400, { error: errorMessage(error), scanError: true });
	const put = await fetch(slot.upload_url, {
		method: 'PUT',
		headers: { 'Content-Type': type },
		body: Buffer.from(await file.arrayBuffer())
	});
	if (!put.ok) return fail(400, { error: errorMessage(null), scanError: true });
	const done = await api.POST('/v1/orgs/{orgId}/leases/{leaseId}/contract-scan/complete', {
		...path,
		body: { key: slot.key, filename: file.name || 'smlouva' }
	});
	if (done.error) return fail(400, { error: errorMessage(done.error), scanError: true });
	return { scanned: true };
}

/** The ?/invite action: invites a tenant of an imported lease to the portal (again, if asked). */
export async function inviteLeaseParty(
	api: ApiClient,
	orgId: string,
	leaseId: string,
	form: FormData
) {
	const partyId = String(form.get('party_id') ?? '');
	const email = String(form.get('email') ?? '').trim();
	const { error } = await api.POST('/v1/orgs/{orgId}/leases/{leaseId}/parties/{partyId}/invite', {
		params: { path: { orgId, leaseId, partyId } },
		body: email ? { email } : {}
	});
	if (error) return fail(400, { error: errorMessage(error), inviteError: partyId });
	return { invited: partyId };
}
