import { error as kitError, fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { payWithRevolut } from '#lib/server/billing.js';
import { loadLease, signLease } from '#lib/server/leases.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const lease = await loadLease(locals.api, params.id);
	if (!lease) kitError(404);
	return lease;
};

const path = (id: string) => ({ params: { path: { leaseId: id } } });

export const actions: Actions = {
	sign: async ({ request, params, locals }) =>
		signLease(locals.api, params.id, await request.formData()),
	changes: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.POST('/v1/leases/{leaseId}/request-changes', {
			...path(params.id),
			body: { comment: String(f.get('comment') ?? '') }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	revolut: async ({ request, locals }) => {
		const f = await request.formData();
		return payWithRevolut(locals.api, String(f.get('share_id') ?? ''));
	},
	notice: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { data, error } = await locals.api.POST('/v1/leases/{leaseId}/notice', {
			...path(params.id),
			body: { delivered_on: String(f.get('delivered_on')) }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { endsOn: data.ends_on };
	},
	settle: async ({ params, locals }) => {
		const { error } = await locals.api.POST('/v1/leases/{leaseId}/settlement', path(params.id));
		if (error) return fail(400, { error: errorMessage(error) });
		return { settled: true };
	}
};
