import QRCode from 'qrcode';
import type { ApiClient } from '@terra/contracts';

/** Loads a lease with its schedule, QR images of payable shares and the chain status. */
export async function loadLease(api: ApiClient, leaseId: string) {
	const path = { params: { path: { leaseId } } };
	const [detail, shares, events] = await Promise.all([
		api.GET('/v1/leases/{leaseId}', path),
		api.GET('/v1/leases/{leaseId}/obligations', path),
		api.GET('/v1/leases/{leaseId}/events', path)
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
		chain: events.data
			? { valid: events.data.valid, count: events.data.events.length, head: events.data.head }
			: null
	};
}
