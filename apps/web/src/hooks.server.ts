import { redirect } from '@sveltejs/kit';
import type { Handle } from '@sveltejs/kit/hooks';
import { sequence } from '@sveltejs/kit/hooks';
import { getTextDirection, localizeHref } from '#lib/paraglide/runtime.js';
import { paraglideMiddleware } from '#lib/paraglide/server.js';
import { api } from '#lib/server/api.js';
import { SESSION_COOKIE, clearSession } from '#lib/server/session.js';

const handleParaglide: Handle = ({ event, resolve }) =>
	paraglideMiddleware(event.request, ({ request, locale }) => {
		return resolve(
			{ ...event, request },
			{
				transformPageChunk: ({ html }) =>
					html
						.replace('%paraglide.lang%', locale)
						.replace('%paraglide.dir%', getTextDirection(locale))
			}
		);
	});

/** Resolves the session cookie into locals.me and guards private route groups. */
const handleAuth: Handle = async ({ event, resolve }) => {
	const token = event.cookies.get(SESSION_COOKIE) ?? null;
	let clientIp: string | undefined;
	try {
		clientIp = event.getClientAddress();
	} catch {
		clientIp = undefined;
	}
	const opts = { clientIp, userAgent: event.request.headers.get('user-agent') };
	event.locals.token = token;
	event.locals.me = null;
	event.locals.api = api(event.fetch, { ...opts, token });
	if (token) {
		try {
			const { data, response } = await event.locals.api.GET('/v1/me');
			if (data) event.locals.me = data;
			else if (response.status === 401) {
				clearSession(event.cookies);
				event.locals.token = null;
				event.locals.api = api(event.fetch, opts);
			}
		} catch {
			// api unreachable: treat as anonymous, pages show their own errors
		}
	}

	const id = event.route.id ?? '';
	const isPrivate =
		id.startsWith('/(admin)') ||
		id.startsWith('/(tenant)') ||
		id.startsWith('/(backoffice)') ||
		id.startsWith('/(messages)');
	if (isPrivate && !event.locals.me) {
		const next = event.url.pathname + event.url.search;
		redirect(303, localizeHref(`/login?next=${encodeURIComponent(next)}`));
	}
	if (id.startsWith('/(backoffice)') && !event.locals.me?.is_staff) {
		redirect(303, localizeHref('/admin'));
	}
	return resolve(event);
};

export const handle: Handle = sequence(handleParaglide, handleAuth);
