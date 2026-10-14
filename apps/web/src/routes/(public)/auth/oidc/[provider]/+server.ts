import { error, redirect } from '@sveltejs/kit';
import { safeNext, setCookie } from '#lib/server/session.js';
import type { RequestHandler } from './$types';

/** Starts a social login and sends the browser to the provider. */
export const GET: RequestHandler = async ({ params, url, locals, cookies }) => {
	const provider = params.provider;
	if (provider !== 'google' && provider !== 'apple') error(404);
	const redirectUri = `${url.origin}/auth/callback/${provider}`;
	const { data } = await locals.api.POST('/v1/auth/oidc/{provider}/start', {
		params: { path: { provider } },
		body: { redirect_uri: redirectUri }
	});
	if (!data) error(503);
	setCookie(cookies, 'terra_next', safeNext(url.searchParams.get('next')), 600);
	redirect(303, data.authorization_url, { external: true });
};
