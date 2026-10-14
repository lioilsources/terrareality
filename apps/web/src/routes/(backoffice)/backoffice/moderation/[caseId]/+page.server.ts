import { error as kitError, fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { data } = await locals.api.GET('/v1/backoffice/moderation/{caseId}', {
		params: { path: { caseId: params.caseId } }
	});
	if (!data) kitError(404);
	return { detail: data };
};

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		const f = await request.formData();
		const note = String(f.get('note') ?? '').trim();
		const { error } = await locals.api.POST('/v1/backoffice/moderation/{caseId}/decision', {
			params: { path: { caseId: params.caseId } },
			body: { decision: String(f.get('decision')) as 'dismiss', note: note || undefined }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		redirect(303, localizeHref('/backoffice/moderation'));
	}
};
