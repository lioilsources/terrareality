import { errorMessage } from '#lib/errors.js';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const q = url.searchParams.get('q') ?? undefined;
	const before = url.searchParams.get('before') ?? undefined;
	const [users, metrics] = await Promise.all([
		locals.api.GET('/v1/backoffice/users', { params: { query: { q, before, limit: 50 } } }),
		locals.api.GET('/v1/backoffice/metrics')
	]);
	return {
		q: q ?? '',
		page: users.data ?? { items: [] },
		error: users.error ? errorMessage(users.error) : null,
		metrics: metrics.data ?? null
	};
};
