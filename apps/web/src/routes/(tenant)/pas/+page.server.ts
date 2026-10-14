import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const { data } = await locals.api.GET('/v1/me/passport');
	return { passport: data! };
};

const types = ['application/pdf', 'image/jpeg', 'image/png'] as const;

export const actions: Actions = {
	upload: async ({ request, locals }) => {
		const file = (await request.formData()).get('file');
		if (!(file instanceof File) || file.size === 0) return fail(400, { error: '' });
		const type = types.find((t) => t === file.type);
		if (!type)
			return fail(400, {
				error: errorMessage({ status: 422, title: '', code: 'attachment_type' })
			});
		const { data: slot, error } = await locals.api.POST('/v1/me/passport/income', {
			body: { content_type: type, size_bytes: file.size }
		});
		if (!slot) return fail(400, { error: errorMessage(error) });
		const put = await fetch(slot.upload_url, {
			method: 'PUT',
			headers: { 'Content-Type': type },
			body: Buffer.from(await file.arrayBuffer())
		});
		if (!put.ok) return fail(400, { error: errorMessage(null) });
		const done = await locals.api.POST('/v1/me/passport/income/complete', {
			body: { key: slot.key, filename: file.name }
		});
		if (done.error) return fail(400, { error: errorMessage(done.error) });
	},
	remove: async ({ locals }) => {
		const { error } = await locals.api.DELETE('/v1/me/passport/income');
		if (error) return fail(400, { error: errorMessage(error) });
	},
	isir: async ({ locals }) => {
		const { error } = await locals.api.POST('/v1/me/passport/insolvency-check');
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
