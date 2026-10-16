import { PAGE_SIZE, cursorFrom, nextCursor, pageLinks } from '#lib/paging.js';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals, url }) => {
	const { data } = await locals.api.GET('/v1/orgs/{orgId}/leases', {
		params: { path: { orgId: params.orgId }, query: { before: cursorFrom(url), limit: PAGE_SIZE } }
	});
	const leases = data ?? [];
	return { leases, paging: pageLinks(url, 'before', nextCursor(leases)) };
};
