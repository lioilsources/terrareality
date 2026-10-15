import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const { data, error } = await locals.api.GET('/v1/backoffice/feature-flags');
	return { flags: data?.items ?? [], error: error ? errorMessage(error) : null };
};

export const actions: Actions = {
	toggle: async ({ request, locals }) => {
		const f = await request.formData();
		const key = String(f.get('key') ?? '');
		// The api writes the audit entry for every change.
		const { error } = await locals.api.PUT('/v1/backoffice/feature-flags/{key}', {
			params: { path: { key } },
			body: { enabled: f.get('enabled') === 'true' }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
