import { error as kitError, fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const [listing, groups] = await Promise.all([
		locals.api.GET('/v1/listings/{listingId}', { params: { path: { listingId: params.id } } }),
		locals.api.GET('/v1/groups')
	]);
	if (!listing.data) kitError(404);
	return { listing: listing.data, groups: (groups.data ?? []).filter((g) => g.joined) };
};

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		const f = await request.formData();
		const answers: Record<string, string> = {};
		for (const [k, v] of f.entries()) {
			if (k.startsWith('q_') && String(v).trim()) answers[k.slice(2)] = String(v).trim();
		}
		const num = (k: string) => (f.get(k) ? Number(f.get(k)) : undefined);
		const group = String(f.get('group_id') ?? '');
		const { data, error } = await locals.api.POST('/v1/applications', {
			body: {
				listing_id: params.id,
				group_id: group || undefined,
				message: String(f.get('message') ?? ''),
				prescreen_answers: answers,
				preferred_from: String(f.get('preferred_from') ?? '') || undefined,
				duration_months: num('duration_months'),
				household_size: num('household_size')
			}
		});
		if (error) return fail(400, { error: errorMessage(error) });
		redirect(303, localizeHref(`/zadosti/${data.application.id}`));
	}
};
