import { redirect } from '@sveltejs/kit';
import { clearSession } from '#lib/server/session.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ locals, cookies }) => {
	if (locals.token) await locals.api.POST('/v1/auth/logout');
	clearSession(cookies);
	redirect(303, localizeHref('/'));
};
