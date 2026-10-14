import { error as kitError, fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const [detail, schema] = await Promise.all([
		locals.api.GET('/v1/backoffice/reviews/{versionId}', {
			params: { path: { versionId: params.versionId } }
		}),
		locals.api.GET('/v1/attributes')
	]);
	if (!detail.data) kitError(404);
	return { detail: detail.data, schema: schema.data! };
};

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		const f = await request.formData();
		const approve = f.get('approve') === 'true';
		const note = String(f.get('note') ?? '').trim();
		const { error } = await locals.api.POST('/v1/backoffice/reviews/{versionId}/decision', {
			params: { path: { versionId: params.versionId } },
			body: { approve, note: note || undefined }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		redirect(303, localizeHref('/backoffice/reviews'));
	}
};
