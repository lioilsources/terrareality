import { fail, redirect } from '@sveltejs/kit';
import { completeAuth } from '#lib/server/auth.js';
import { MFA_COOKIE, safeNext } from '#lib/server/session.js';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = ({ cookies }) => {
	if (!cookies.get(MFA_COOKIE)) redirect(303, localizeHref('/login'));
};

export const actions: Actions = {
	default: async ({ request, locals, cookies, url }) => {
		const mfaToken = cookies.get(MFA_COOKIE);
		if (!mfaToken) redirect(303, localizeHref('/login'));
		const code = String((await request.formData()).get('code') ?? '').trim();
		const { data, error } = await locals.api.POST('/v1/auth/mfa', {
			body: { mfa_token: mfaToken, code }
		});
		if (!data) return fail(400, { error: errorMessage(error) });
		completeAuth(cookies, data, safeNext(url.searchParams.get('next')));
	}
};
