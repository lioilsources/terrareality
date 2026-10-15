import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals, url }) => {
	const municipality = url.searchParams.get('municipality') || undefined;
	const group_id = url.searchParams.get('group_id') || undefined;
	const path = { orgId: params.orgId };
	const filtered = Boolean(municipality || group_id);
	const [dash, all, groups, summary] = await Promise.all([
		locals.api.GET('/v1/orgs/{orgId}/portfolio', {
			params: { path, query: { municipality, group_id } }
		}),
		filtered
			? locals.api.GET('/v1/orgs/{orgId}/portfolio', { params: { path } })
			: Promise.resolve(null),
		locals.api.GET('/v1/orgs/{orgId}/portfolio/groups', { params: { path } }),
		locals.api.GET('/v1/orgs/{orgId}/portfolio/summary', { params: { path } })
	]);
	const filter = { municipality: municipality ?? '', group_id: group_id ?? '' };
	if (!dash.data)
		return {
			dashboard: null,
			error: errorMessage(dash.error),
			cities: [],
			groups: [],
			summary: null,
			filter
		};
	const cities = (all?.data ?? dash.data).cities.filter((c) => c.path);
	return {
		dashboard: dash.data,
		cities,
		groups: groups.data?.groups ?? [],
		summary: summary.data?.summary ?? null,
		error: null,
		filter
	};
};

export const actions: Actions = {
	summarize: async ({ params, locals }) => {
		const { error } = await locals.api.POST('/v1/orgs/{orgId}/portfolio/summary', {
			params: { path: { orgId: params.orgId } }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
