import { redirect } from '@sveltejs/kit';
import { SESSION_COOKIE, STAFF_COOKIE, deleteCookie, setCookie } from '#lib/server/session.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { RequestHandler } from './$types';

/** Ends a support session and restores the staff session. */
export const POST: RequestHandler = async ({ locals, cookies }) => {
	if (locals.me?.impersonator) await locals.api.POST('/v1/auth/logout');
	const staff = cookies.get(STAFF_COOKIE);
	deleteCookie(cookies, STAFF_COOKIE);
	if (staff) setCookie(cookies, SESSION_COOKIE, staff, 60 * 60 * 24 * 30);
	else deleteCookie(cookies, SESSION_COOKIE);
	redirect(303, localizeHref('/backoffice'));
};
