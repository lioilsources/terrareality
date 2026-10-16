import { PAGE_SIZE, cursorFrom, nextCursor, pageLinks } from '#lib/paging.js';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const { data } = await locals.api.GET('/v1/conversations', {
		params: { query: { before: cursorFrom(url), limit: PAGE_SIZE } }
	});
	const conversations = data ?? [];
	return { conversations, paging: pageLinks(url, 'before', nextCursor(conversations)) };
};
