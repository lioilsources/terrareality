import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/** Address autocomplete for the listing wizard (proxied to the api). */
export const GET: RequestHandler = async ({ url, locals }) => {
	const q = url.searchParams.get('q') ?? '';
	if (q.trim().length < 3) return json([]);
	const { data } = await locals.api.GET('/v1/addresses/search', {
		params: { query: { q, limit: 8 } }
	});
	return json(data ?? []);
};
