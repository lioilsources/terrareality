import { fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import { setCookie } from '#lib/server/session.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { data } = await locals.api.POST('/v1/invitations/lookup', {
		body: { token: params.token }
	});
	return { invitation: data ?? null, me: locals.me };
};

export const actions: Actions = {
	default: async ({ params, locals, cookies }) => {
		const { data, error } = await locals.api.POST('/v1/invitations/accept', {
			body: { token: params.token }
		});
		if (!data) return fail(400, { error: errorMessage(error) });
		setCookie(cookies, 'terra_org', data.organization.id, 60 * 60 * 24 * 365);
		redirect(303, localizeHref(`/admin/orgs/${data.organization.id}`));
	}
};
