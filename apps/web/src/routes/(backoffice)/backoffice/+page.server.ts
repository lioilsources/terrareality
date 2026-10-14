import { errorMessage } from '#lib/errors.js';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const q = url.searchParams.get('q') ?? undefined;
	const before = url.searchParams.get('before') ?? undefined;
	const { data, error } = await locals.api.GET('/v1/backoffice/users', {
		params: { query: { q, before, limit: 50 } }
	});
	return { q: q ?? '', page: data ?? { items: [] }, error: error ? errorMessage(error) : null };
};
