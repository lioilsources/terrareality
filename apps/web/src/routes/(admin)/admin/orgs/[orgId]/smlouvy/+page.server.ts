import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { data } = await locals.api.GET('/v1/orgs/{orgId}/leases', {
		params: { path: { orgId: params.orgId } }
	});
	return { leases: data ?? [] };
};
