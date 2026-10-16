import { PAGE_SIZE, cursorFrom, nextCursor, pageLinks } from '#lib/paging.js';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	// Oldest first: the next page starts after the last case.
	const { data } = await locals.api.GET('/v1/backoffice/moderation', {
		params: { query: { after: cursorFrom(url, 'after'), limit: PAGE_SIZE } }
	});
	const cases = data ?? [];
	return { cases, paging: pageLinks(url, 'after', nextCursor(cases)) };
};
