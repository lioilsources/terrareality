import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { getLocale } from '#lib/paraglide/runtime.js';
import type { Actions } from './$types';

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const email = String((await request.formData()).get('email') ?? '');
		const { error } = await locals.api.POST('/v1/auth/password/forgot', {
			body: { email, locale: getLocale() }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { sent: true };
	}
};
