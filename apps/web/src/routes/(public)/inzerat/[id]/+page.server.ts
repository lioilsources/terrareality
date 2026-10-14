import { error as kitError, fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const path = { params: { path: { listingId: params.id } } };
	const [listing, similar, schema, mine] = await Promise.all([
		locals.api.GET('/v1/listings/{listingId}', path),
		locals.api.GET('/v1/listings/{listingId}/similar', path),
		locals.api.GET('/v1/attributes'),
		locals.me ? locals.api.GET('/v1/conversations', { params: { query: { as: 'seeker' } } }) : null
	]);
	if (!listing.data) kitError(404);
	const conversation = mine?.data?.find((c) => c.listing_id === params.id)?.id ?? null;
	return { listing: listing.data, similar: similar.data ?? [], schema: schema.data!, conversation };
};

export const actions: Actions = {
	contact: async ({ request, params, locals, url }) => {
		if (!locals.me) redirect(303, localizeHref(`/login?next=${encodeURIComponent(url.pathname)}`));
		const f = await request.formData();
		const body = String(f.get('body') ?? '').trim();
		const answers: Record<string, string> = {};
		for (const [k, v] of f.entries()) {
			if (k.startsWith('q_') && String(v).trim()) answers[k.slice(2)] = String(v).trim();
		}
		const { data, error } = await locals.api.POST('/v1/conversations', {
			body: { listing_id: params.id, body, prescreen_answers: answers }
		});
		if (error) return fail(400, { error: errorMessage(error), body, answers });
		redirect(303, localizeHref(`/zpravy/${data.conversation_id}`));
	}
};
