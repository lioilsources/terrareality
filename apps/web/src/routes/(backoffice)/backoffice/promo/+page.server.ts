import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { toMinor } from '#lib/catalog.js';
import type { components } from '@terra/contracts';
import type { Actions, PageServerLoad } from './$types';

type Kind = components['schemas']['PromoProductKind'];
const kinds: Kind[] = ['top', 'highlight', 'bundle'];

export const load: PageServerLoad = async ({ locals }) => {
	const { data, error } = await locals.api.GET('/v1/backoffice/promo-products');
	return { products: data?.items ?? [], error: error ? errorMessage(error) : null };
};

function int(v: FormDataEntryValue | null): number | undefined {
	const n = Number(String(v ?? '').trim());
	return Number.isInteger(n) && n > 0 ? n : undefined;
}

function name(f: FormData) {
	const cs = String(f.get('name_cs') ?? '').trim();
	const en = String(f.get('name_en') ?? '').trim();
	return cs && en ? { cs, en } : undefined;
}

export const actions: Actions = {
	create: async ({ request, locals }) => {
		const f = await request.formData();
		const code = String(f.get('code') ?? '').trim();
		const kind = String(f.get('kind') ?? '') as Kind;
		const duration_days = int(f.get('duration_days'));
		const net_amount = toMinor(f.get('net'));
		const vatPct = Number(String(f.get('vat') ?? '21').replace(',', '.'));
		const n = name(f);
		if (!code || !kinds.includes(kind) || !duration_days || net_amount === undefined || !n)
			return fail(400, { error: null, invalid: true, op: 'create' });
		const { error } = await locals.api.POST('/v1/backoffice/promo-products', {
			body: {
				code,
				kind,
				duration_days,
				net_amount,
				currency: 'CZK',
				vat_rate_bp: Number.isFinite(vatPct) ? Math.round(vatPct * 100) : 2100,
				name: n,
				active: f.get('active') === 'on'
			}
		});
		if (error) return fail(400, { error: errorMessage(error), invalid: false, op: 'create' });
		return { saved: true, op: 'create' };
	},
	update: async ({ request, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.PATCH('/v1/backoffice/promo-products/{productId}', {
			params: { path: { productId: String(f.get('id')) } },
			body: {
				net_amount: toMinor(f.get('net')),
				duration_days: int(f.get('duration_days')),
				name: name(f),
				active: f.get('active') === 'on'
			}
		});
		if (error) return fail(400, { error: errorMessage(error), invalid: false, op: 'update' });
		return { saved: true, op: 'update' };
	}
};
