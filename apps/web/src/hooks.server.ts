import { isRedirect, redirect } from '@sveltejs/kit';
import type { Handle, HandleServerError } from '@sveltejs/kit/hooks';
import { building, version } from '$app/env';
import { SENTRY_DSN } from '$app/env/private';
import { PUBLIC_SENTRY_ENVIRONMENT, PUBLIC_SENTRY_RELEASE } from '$app/env/public';
import { sequence } from '@sveltejs/kit/hooks';
import { getTextDirection, localizeHref } from '#lib/paraglide/runtime.js';
import { paraglideMiddleware } from '#lib/paraglide/server.js';
import { api } from '#lib/server/api.js';
import { SESSION_COOKIE, clearSession, clearSessionHeaders } from '#lib/server/session.js';
import { createReporter } from '#lib/sentry.js';
import { cspExtras, extendCsp } from '#lib/server/csp.js';
import { assertProductionEnv } from '#lib/env-defaults.js';
import {
	API_PUBLIC_URL,
	CSP_FORM_ACTION_ORIGINS,
	CSP_MAP_ORIGINS,
	CSP_MEDIA_ORIGINS,
	CSP_REALTIME_ORIGIN
} from '$app/env/private';
import { MAP_STYLE, PUBLIC_SENTRY_DSN } from '$app/env/public';

// Production must not run on localhost fallbacks (CSP would block photos, websocket, redirects).
if (!building) assertProductionEnv();

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
				event.locals.sessionCleared = true;
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

const csp = cspExtras({
	apiPublicUrl: API_PUBLIC_URL,
	mapStyle: MAP_STYLE,
	mapOrigins: CSP_MAP_ORIGINS,
	mediaOrigins: CSP_MEDIA_ORIGINS,
	realtimeOrigin: CSP_REALTIME_ORIGIN,
	sentryDsn: PUBLIC_SENTRY_DSN,
	formActionOrigins: CSP_FORM_ACTION_ORIGINS
});

function setSecurityHeaders(h: Headers) {
	h.set('x-content-type-options', 'nosniff');
	h.set('referrer-policy', 'strict-origin-when-cross-origin');
	h.set('permissions-policy', 'camera=(), microphone=(), geolocation=(self), payment=(), usb=()');
	h.set('x-frame-options', 'DENY');
}

/**
 * Adds runtime origins to SvelteKit's CSP (vite.config.ts) and other security headers.
 * Redirects thrown by later hooks (handleAuth's login guard) bypass `resolve`, so plain
 * page navigations (GET) get their redirect built here with the same headers. Data,
 * form action and remote requests keep SvelteKit's own JSON redirect handling.
 */
const handleSecurityHeaders: Handle = async ({ event, resolve }) => {
	let response: Response;
	try {
		response = await resolve(event);
	} catch (e) {
		const plainNavigation =
			(event.request.method === 'GET' || event.request.method === 'HEAD') &&
			!event.isDataRequest &&
			!event.isRemoteRequest;
		if (!isRedirect(e) || !plainNavigation) throw e;
		const headers = new Headers({ location: e.location });
		if (event.locals.sessionCleared) {
			for (const c of clearSessionHeaders(event.cookies)) headers.append('set-cookie', c);
		}
		setSecurityHeaders(headers);
		return new Response(null, { status: e.status, headers });
	}
	try {
		const h = response.headers;
		const policy = h.get('content-security-policy');
		if (policy) h.set('content-security-policy', extendCsp(policy, csp));
		setSecurityHeaders(h);
	} catch {
		// immutable headers (e.g. proxied fetch responses): leave them as they are
	}
	return response;
};

export const handle: Handle = sequence(handleSecurityHeaders, handleParaglide, handleAuth);

const sentry = createReporter({
	dsn: SENTRY_DSN,
	release: PUBLIC_SENTRY_RELEASE || version,
	environment: PUBLIC_SENTRY_ENVIRONMENT,
	platform: 'node'
});

/** Reports unexpected server errors (not 4xx/framework errors) to Sentry, without PII. */
export const handleError: HandleServerError = ({ error, event, kind }) => {
	if (sentry && kind === 'unknown') {
		void sentry.capture(error, { route: event.route.id, kind, tags: { runtime: 'server' } });
	}
};
