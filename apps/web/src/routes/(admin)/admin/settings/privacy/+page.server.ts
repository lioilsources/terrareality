import { fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const [requests, consents] = await Promise.all([
		locals.api.GET('/v1/me/gdpr-requests'),
		locals.api.GET('/v1/me/consents')
	]);
	const marketing = (consents.data ?? []).find((c) => c.kind === 'marketing');
	return { requests: requests.data ?? [], marketing: marketing?.granted ?? false };
};

export const actions: Actions = {
	export: async ({ locals }) => {
		const { error } = await locals.api.POST('/v1/me/data-exports');
		if (error) return fail(400, { error: errorMessage(error) });
	},
	download: async ({ request, locals }) => {
		const id = String((await request.formData()).get('id') ?? '');
		const { data, error } = await locals.api.GET('/v1/me/data-exports/{requestId}/download', {
			params: { path: { requestId: id } }
		});
		if (!data) return fail(400, { error: errorMessage(error) });
		redirect(303, data.url, { external: true });
	},
	erase: async ({ locals }) => {
		const { error } = await locals.api.POST('/v1/me/erasure');
		if (error) return fail(400, { error: errorMessage(error) });
	},
	cancelErase: async ({ locals }) => {
		const { error } = await locals.api.DELETE('/v1/me/erasure');
		if (error) return fail(400, { error: errorMessage(error) });
	},
	marketing: async ({ request, locals }) => {
		const granted = (await request.formData()).get('granted') === 'true';
		const { error } = await locals.api.POST('/v1/me/consents', {
			body: { kind: 'marketing', version: '2026-10', granted }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
