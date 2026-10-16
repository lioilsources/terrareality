import { fail } from '@sveltejs/kit';
import { errorMessage, serviceUnavailable } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const [proposals, schema] = await Promise.all([
		locals.api.GET('/v1/backoffice/filter-proposals', { params: { query: { status: 'pending' } } }),
		locals.api.GET('/v1/attributes')
	]);
	if (!schema.data) serviceUnavailable();
	return { proposals: proposals.data ?? [], schema: schema.data };
};

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const f = await request.formData();
		const cs = String(f.get('label_cs') ?? '').trim();
		const en = String(f.get('label_en') ?? '').trim();
		const { error } = await locals.api.POST(
			'/v1/backoffice/filter-proposals/{proposalId}/decision',
			{
				params: { path: { proposalId: String(f.get('id')) } },
				body: { approve: f.get('approve') === 'true', label: cs && en ? { cs, en } : undefined }
			}
		);
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
