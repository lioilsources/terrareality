import { redirect } from '@sveltejs/kit';
import { restoreStaffSession } from '#lib/server/session.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { RequestHandler } from './$types';

/** Ends a support session and restores the staff session (with its stash expiry, never longer). */
export const POST: RequestHandler = async ({ locals, cookies }) => {
	if (locals.me?.impersonator) await locals.api.POST('/v1/auth/logout');
	const restored = restoreStaffSession(cookies);
	redirect(303, localizeHref(restored ? '/backoffice' : '/login'));
};
