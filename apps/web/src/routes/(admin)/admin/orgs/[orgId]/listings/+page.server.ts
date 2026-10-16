import type { ListingStatus } from '@terra/contracts';
import { error as kitError } from '@sveltejs/kit';
import { PAGE_SIZE, cursorFrom, nextCursor, pageLinks } from '#lib/paging.js';
import type { PageServerLoad } from './$types';

const statuses = ['draft', 'review', 'published', 'paused', 'rented', 'archived'];

export const load: PageServerLoad = async ({ params, locals, url }) => {
	const s = url.searchParams.get('status');
	const status = s && statuses.includes(s) ? (s as ListingStatus) : undefined;
	const [org, list] = await Promise.all([
		locals.api.GET('/v1/orgs/{orgId}', { params: { path: { orgId: params.orgId } } }),
		locals.api.GET('/v1/orgs/{orgId}/listings', {
			params: {
				path: { orgId: params.orgId },
				query: { status, before: cursorFrom(url), limit: PAGE_SIZE }
			}
		})
	]);
	if (!org.data) kitError(404);
	const listings = list.data ?? [];
	return {
		org: org.data,
		listings,
		status: status ?? null,
		statuses,
		paging: pageLinks(url, 'before', nextCursor(listings))
	};
};
