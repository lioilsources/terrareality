import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const { data } = await locals.api.GET('/v1/backoffice/moderation');
	return { cases: data ?? [] };
};
