import { fail } from '@sveltejs/kit';
import { completeAuth } from '#lib/server/auth.js';
import { safeNext } from '#lib/server/session.js';
import { errorMessage } from '#lib/errors.js';
import { getLocale } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const { data } = await locals.api.GET('/v1/auth/providers');
	return { providers: data ?? [], next: safeNext(url.searchParams.get('next')) };
};

export const actions: Actions = {
	login: async ({ request, locals, cookies, url }) => {
		const f = await request.formData();
		const email = String(f.get('email') ?? '');
		const { data, error } = await locals.api.POST('/v1/auth/login', {
			body: { email, password: String(f.get('password') ?? ''), client: 'web' }
		});
		if (!data) return fail(400, { email, error: errorMessage(error) });
		completeAuth(cookies, data, safeNext(url.searchParams.get('next')));
	},
	magic: async ({ request, locals }) => {
		const email = String((await request.formData()).get('email') ?? '');
		const { error } = await locals.api.POST('/v1/auth/magic-link', {
			body: { email, locale: getLocale() }
		});
		if (error) return fail(400, { email, magicError: errorMessage(error) });
		return { email, magicSent: true };
	}
};
