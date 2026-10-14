import { fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const { data } = await locals.api.GET('/v1/groups');
	return { groups: data ?? [] };
};

export const actions: Actions = {
	create: async ({ request, locals }) => {
		const f = await request.formData();
		const invite = String(f.get('invite') ?? '')
			.split(/[,;\s]+/)
			.map((e) => e.trim())
			.filter(Boolean);
		const { data, error } = await locals.api.POST('/v1/groups', {
			body: { name: String(f.get('name') ?? ''), invite }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		redirect(303, localizeHref(`/skupiny/${data.id}`));
	}
};
