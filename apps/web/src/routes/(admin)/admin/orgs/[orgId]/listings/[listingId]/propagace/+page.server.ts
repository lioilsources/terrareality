import { error as kitError, fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import { LAST_ORDER_COOKIE } from '#lib/server/billing.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals, url }) => {
	const path = { params: { path: { orgId: params.orgId, listingId: params.listingId } } };
	const [listing, products, promotions] = await Promise.all([
		locals.api.GET('/v1/orgs/{orgId}/listings/{listingId}', path),
		locals.api.GET('/v1/promo-products'),
		locals.api.GET('/v1/orgs/{orgId}/listings/{listingId}/promotions', path)
	]);
	if (!listing.data) kitError(404);
	return {
		listing: listing.data,
		products: (products.data?.items ?? []).filter((p) => p.active),
		promotions: promotions.data?.items ?? [],
		canceled: url.searchParams.has('canceled'),
		error: products.error ? errorMessage(products.error) : null
	};
};

export const actions: Actions = {
	checkout: async ({ request, params, locals, url, cookies }) => {
		const f = await request.formData();
		const product_code = String(f.get('product_code') ?? '');
		const later = f.get('start') === 'later';
		const startsOn = String(f.get('starts_on') ?? '');
		const values = { product_code, start: later ? 'later' : 'now', starts_on: startsOn };
		if (!product_code) return fail(400, { ...values, missing: 'product' as const });
		let starts_at: string | undefined;
		if (later) {
			const today = new Date().toISOString().slice(0, 10);
			if (!/^\d{4}-\d{2}-\d{2}$/.test(startsOn) || startsOn <= today)
				return fail(400, { ...values, missing: 'date' as const });
			starts_at = new Date(`${startsOn}T00:00:00`).toISOString();
		}
		const billing = `/admin/orgs/${params.orgId}/fakturace`;
		const back = `/admin/orgs/${params.orgId}/listings/${params.listingId}/propagace`;
		const { data, error } = await locals.api.POST(
			'/v1/orgs/{orgId}/listings/{listingId}/promotions/checkout',
			{
				params: { path: { orgId: params.orgId, listingId: params.listingId } },
				body: {
					product_code,
					starts_at,
					// The order id is not known before this call: the billing page falls back to the
					// cookie below when the provider does not fill it in.
					success_url: `${url.origin}${localizeHref(billing)}?paid=1`,
					cancel_url: `${url.origin}${localizeHref(back)}?canceled=1`
				}
			}
		);
		if (error) return fail(400, { ...values, error: errorMessage(error) });
		cookies.set(LAST_ORDER_COOKIE, data.order_id, {
			path: '/',
			httpOnly: true,
			sameSite: 'lax',
			maxAge: 60 * 60
		});
		redirect(303, data.checkout_url, { external: true });
	}
};
