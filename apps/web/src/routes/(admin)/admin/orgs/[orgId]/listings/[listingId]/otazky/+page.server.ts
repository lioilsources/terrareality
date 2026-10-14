import { error as kitError, fail } from '@sveltejs/kit';
import type { PrescreenQuestion } from '@terra/contracts';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { data } = await locals.api.GET('/v1/orgs/{orgId}/listings/{listingId}', {
		params: { path: { orgId: params.orgId, listingId: params.listingId } }
	});
	if (!data) kitError(404);
	return { listing: data };
};

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		const f = await request.formData();
		let questions: PrescreenQuestion[];
		try {
			questions = JSON.parse(String(f.get('questions') ?? '[]'));
		} catch {
			return fail(400, { error: 'invalid' });
		}
		const { error } = await locals.api.PUT('/v1/orgs/{orgId}/listings/{listingId}/prescreen', {
			params: { path: { orgId: params.orgId, listingId: params.listingId } },
			body: questions
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { saved: true };
	}
};
