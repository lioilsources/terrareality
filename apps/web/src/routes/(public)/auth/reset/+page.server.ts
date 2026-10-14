import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = ({ url }) => ({ token: url.searchParams.get('token') ?? '' });

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.POST('/v1/auth/password/reset', {
			body: { token: String(f.get('token') ?? ''), password: String(f.get('password') ?? '') }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { done: true };
	}
};
