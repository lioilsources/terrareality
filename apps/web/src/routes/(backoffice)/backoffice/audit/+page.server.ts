import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const before = url.searchParams.get('before') ?? undefined;
	const entity = url.searchParams.get('entity') ?? undefined;
	const { data } = await locals.api.GET('/v1/backoffice/audit', {
		params: { query: { before, entity, limit: 100 } }
	});
	return { page: data ?? { items: [] } };
};
