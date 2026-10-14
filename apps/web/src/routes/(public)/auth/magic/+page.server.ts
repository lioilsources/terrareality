import { fail } from '@sveltejs/kit';
import { completeAuth } from '#lib/server/auth.js';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

// The link opens a page with a button instead of signing in on GET, so mail
// scanners that prefetch links cannot burn the one-time token.
export const load: PageServerLoad = ({ url }) => ({ token: url.searchParams.get('token') ?? '' });

export const actions: Actions = {
	default: async ({ request, locals, cookies }) => {
		const token = String((await request.formData()).get('token') ?? '');
		const { data, error } = await locals.api.POST('/v1/auth/magic-link/verify', {
			body: { token, client: 'web' }
		});
		if (!data) return fail(400, { error: errorMessage(error) });
		completeAuth(cookies, data, '/admin');
	}
};
