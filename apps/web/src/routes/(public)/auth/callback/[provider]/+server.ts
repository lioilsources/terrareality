import { error, redirect, type RequestEvent } from '@sveltejs/kit';
import { completeAuth } from '#lib/server/auth.js';
import { deleteCookie, safeNext } from '#lib/server/session.js';
import { localizeHref } from '#lib/paraglide/runtime.js';

async function finish(event: RequestEvent, code: string, state: string): Promise<never> {
	const provider = event.params.provider;
	if (provider !== 'google' && provider !== 'apple') error(404);
	const { data } = await event.locals.api.POST('/v1/auth/oidc/{provider}/callback', {
		params: { path: { provider } },
		body: {
			code,
			state,
			redirect_uri: `${event.url.origin}/auth/callback/${provider}`,
			client: 'web'
		}
	});
	if (!data) redirect(303, localizeHref('/login?error=social'));
	const next = safeNext(event.cookies.get('terra_next'));
	deleteCookie(event.cookies, 'terra_next');
	completeAuth(event.cookies, data, next);
}

export const GET = (event: RequestEvent) =>
	finish(
		event,
		event.url.searchParams.get('code') ?? '',
		event.url.searchParams.get('state') ?? ''
	);

/** Apple posts the code back (response_mode=form_post). */
export const POST = async (event: RequestEvent) => {
	const f = await event.request.formData();
	return finish(event, String(f.get('code') ?? ''), String(f.get('state') ?? ''));
};
