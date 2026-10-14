import { redirect } from '@sveltejs/kit';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { RequestHandler } from './$types';

/** Return URL of BankID (or the mock IdP) after identity verification. */
export const GET: RequestHandler = async ({ url, locals }) => {
	if (!locals.me) redirect(303, localizeHref('/login'));
	const { error } = await locals.api.POST('/v1/me/identity/callback', {
		body: {
			code: url.searchParams.get('code') ?? '',
			state: url.searchParams.get('state') ?? '',
			redirect_uri: `${url.origin}/auth/identity`
		}
	});
	const result = error ? `error=${encodeURIComponent(error.code ?? 'failed')}` : 'verified=1';
	redirect(303, localizeHref(`/admin/settings/profile?${result}`));
};
