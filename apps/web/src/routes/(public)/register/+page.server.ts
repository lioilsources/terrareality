import { fail } from '@sveltejs/kit';
import { completeAuth } from '#lib/server/auth.js';
import { safeNext } from '#lib/server/session.js';
import { errorMessage } from '#lib/errors.js';
import { getLocale } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

/** Current legal document versions; the api records them in the consent log. */
const TERMS_VERSION = '2026-10';
const PRIVACY_VERSION = '2026-10';

export const load: PageServerLoad = ({ url }) => ({ next: safeNext(url.searchParams.get('next')) });

export const actions: Actions = {
	default: async ({ request, locals, cookies, url }) => {
		const f = await request.formData();
		const email = String(f.get('email') ?? '');
		const displayName = String(f.get('display_name') ?? '');
		const locale = getLocale() === 'en' ? 'en' : 'cs';
		const { data, error } = await locals.api.POST('/v1/auth/register', {
			body: {
				email,
				password: String(f.get('password') ?? ''),
				display_name: displayName,
				locale,
				accept_terms_version: f.get('terms') ? TERMS_VERSION : '',
				accept_privacy_version: f.get('privacy') ? PRIVACY_VERSION : '',
				marketing: f.get('marketing') === 'on',
				client: 'web'
			}
		});
		if (!data) return fail(400, { email, displayName, error: errorMessage(error) });
		completeAuth(cookies, data, safeNext(url.searchParams.get('next')));
	}
};
