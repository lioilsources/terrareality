import { error as kitError, fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import {
	SESSION_COOKIE,
	STAFF_COOKIE,
	parseStaffStash,
	setSession,
	stashStaffSession
} from '#lib/server/session.js';
import { m } from '#lib/paraglide/messages.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { data } = await locals.api.GET('/v1/backoffice/users/{userId}', {
		params: { path: { userId: params.userId } }
	});
	if (!data) kitError(404);
	return { detail: data };
};

export const actions: Actions = {
	impersonate: async ({ request, params, locals, cookies }) => {
		const reason = String((await request.formData()).get('reason') ?? '');
		// Nested impersonation would overwrite the stashed staff session.
		if (locals.me?.impersonator || parseStaffStash(cookies.get(STAFF_COOKIE)))
			return fail(409, { error: m.err_impersonation_nested() });
		const { data, error } = await locals.api.POST('/v1/backoffice/users/{userId}/impersonate', {
			params: { path: { userId: params.userId } },
			body: { reason }
		});
		if (!data?.session) return fail(400, { error: errorMessage(error) });
		const staff = cookies.get(SESSION_COOKIE);
		if (staff) stashStaffSession(cookies, staff);
		setSession(cookies, data.session.token, data.session.expires_at);
		redirect(303, localizeHref('/admin'));
	}
};
