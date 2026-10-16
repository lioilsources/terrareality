import { fail } from '@sveltejs/kit';
import { isUuid } from '#lib/billing.js';
import { errorMessage } from '#lib/errors.js';
import { LAST_ORDER_COOKIE } from '#lib/server/billing.js';
import { PAGE_SIZE, cursorFrom, pageLinks } from '#lib/paging.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals, url, cookies }) => {
	const path = { params: { path: { orgId: params.orgId } } };
	// Back from checkout: ?paid=<order id>, or the order remembered by the checkout action.
	const paidParam = url.searchParams.get('paid');
	const paidId = paidParam
		? isUuid(paidParam)
			? paidParam
			: cookies.get(LAST_ORDER_COOKIE)
		: undefined;
	const [org, orders, invoices, revolut, paid] = await Promise.all([
		locals.api.GET('/v1/orgs/{orgId}', path),
		locals.api.GET('/v1/orgs/{orgId}/orders', {
			params: {
				path: { orgId: params.orgId },
				query: { before: cursorFrom(url, 'orders_before'), limit: PAGE_SIZE }
			}
		}),
		locals.api.GET('/v1/orgs/{orgId}/invoices', {
			params: {
				path: { orgId: params.orgId },
				query: { before: cursorFrom(url, 'invoices_before'), limit: PAGE_SIZE }
			}
		}),
		locals.api.GET('/v1/orgs/{orgId}/revolut', path),
		isUuid(paidId)
			? locals.api.GET('/v1/orgs/{orgId}/orders/{orderId}', {
					params: { path: { orgId: params.orgId, orderId: paidId! } }
				})
			: Promise.resolve(null)
	]);
	const manage = org.data?.role === 'owner' || org.data?.role === 'admin';
	return {
		orgName: org.data?.organization.name ?? '',
		manage,
		orders: orders.data?.items ?? [],
		invoices: invoices.data?.items ?? [],
		// Two lists on one page, each with its own cursor parameter.
		ordersPaging: pageLinks(url, 'orders_before', orders.data?.next_before, ['paid']),
		invoicesPaging: pageLinks(url, 'invoices_before', invoices.data?.next_before, ['paid']),
		// 403/404: payments.revolut flag off → the section is hidden.
		revolut: revolut.response.ok ? (revolut.data ?? null) : null,
		paidOrder: paid?.data ?? null,
		returned: paidParam !== null,
		error: orders.error ? errorMessage(orders.error) : null
	};
};

const path = (orgId: string) => ({ params: { path: { orgId } } });

export const actions: Actions = {
	revolutConnect: async ({ request, params, locals }) => {
		const f = await request.formData();
		const api_key = String(f.get('api_key') ?? '').trim();
		const mode = f.get('mode') === 'live' ? 'live' : 'sandbox';
		if (!api_key) return fail(400, { revolutError: true, mode });
		const { error } = await locals.api.PUT('/v1/orgs/{orgId}/revolut', {
			...path(params.orgId),
			body: { api_key, mode }
		});
		if (error) return fail(400, { revolutError: true, mode, error: errorMessage(error) });
		return { revolutSaved: true };
	},
	revolutDisconnect: async ({ params, locals }) => {
		const { error } = await locals.api.DELETE('/v1/orgs/{orgId}/revolut', path(params.orgId));
		if (error) return fail(400, { error: errorMessage(error) });
		return { revolutRemoved: true };
	}
};
