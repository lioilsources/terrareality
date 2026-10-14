import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { data } = await locals.api.GET('/v1/orgs/{orgId}/reply-templates', {
		params: { path: { orgId: params.orgId } }
	});
	return { templates: data ?? [] };
};

function input(f: FormData) {
	return { title: String(f.get('title') ?? '').trim(), body: String(f.get('body') ?? '').trim() };
}

export const actions: Actions = {
	create: async ({ request, params, locals }) => {
		const { error } = await locals.api.POST('/v1/orgs/{orgId}/reply-templates', {
			params: { path: { orgId: params.orgId } },
			body: input(await request.formData())
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	update: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.PUT('/v1/orgs/{orgId}/reply-templates/{templateId}', {
			params: { path: { orgId: params.orgId, templateId: String(f.get('id')) } },
			body: input(f)
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	delete: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.DELETE('/v1/orgs/{orgId}/reply-templates/{templateId}', {
			params: { path: { orgId: params.orgId, templateId: String(f.get('id')) } }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
