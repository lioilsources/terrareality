import { error as kitError, fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { data } = await locals.api.GET('/v1/groups/{groupId}', {
		params: { path: { groupId: params.id } }
	});
	if (!data) kitError(404);
	return { group: data, meId: locals.me!.id };
};

const path = (id: string) => ({ params: { path: { groupId: id } } });

export const actions: Actions = {
	join: async ({ params, locals }) => {
		const { error } = await locals.api.POST('/v1/groups/{groupId}/join', path(params.id));
		if (error) return fail(400, { error: errorMessage(error) });
	},
	leave: async ({ params, locals }) => {
		const { error } = await locals.api.POST('/v1/groups/{groupId}/leave', path(params.id));
		if (error) return fail(400, { error: errorMessage(error) });
		redirect(303, localizeHref('/skupiny'));
	},
	invite: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.POST('/v1/groups/{groupId}/invitations', {
			...path(params.id),
			body: { email: String(f.get('email') ?? '').trim() }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	send: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { data, error } = await locals.api.POST('/v1/groups/{groupId}/messages', {
			...path(params.id),
			body: { body: String(f.get('body') ?? '') }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { sent: data };
	}
};
