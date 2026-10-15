import { fail, redirect } from '@sveltejs/kit';
import type { ApiClient } from '@terra/contracts';
import type { RevolutState } from '#lib/billing.js';

/** Revolut state of an organization: off when the flag is off, connect when no account. */
export async function revolutState(api: ApiClient, orgId: string): Promise<RevolutState> {
	const { data, response } = await api.GET('/v1/orgs/{orgId}/revolut', {
		params: { path: { orgId } }
	});
	if (!data || !response.ok) return 'off';
	return data.connected ? 'on' : 'connect';
}

/**
 * Form action body: reuses the latest valid Revolut payment link of a share or creates one and
 * redirects to it. The money goes straight to the landlord's own merchant account (ADR 0002).
 */
export async function payWithRevolut(api: ApiClient, shareId: string) {
	const path = { params: { path: { shareId } } };
	const existing = await api.GET('/v1/obligation-shares/{shareId}/payment-link', path);
	if (existing.data && existing.data.status === 'created')
		redirect(303, existing.data.url, { external: true });
	const { data, response } = await api.POST('/v1/obligation-shares/{shareId}/payment-link', path);
	if (data) redirect(303, data.url, { external: true });
	const status = response.status;
	if (status === 403 || status === 404) return fail(status, { revolut: 'off' as const, shareId });
	if (status === 409) return fail(409, { revolut: 'connect' as const, shareId });
	return fail(status || 400, { revolut: 'error' as const, shareId });
}

/** Remembers the order of the last checkout so the billing page can follow it after payment. */
export const LAST_ORDER_COOKIE = 'tr_last_order';
