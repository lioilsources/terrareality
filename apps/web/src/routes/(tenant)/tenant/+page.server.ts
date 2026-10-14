import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const [apps, viewings] = await Promise.all([
		locals.api.GET('/v1/applications'),
		locals.api.GET('/v1/me/viewings')
	]);
	return { applications: apps.data ?? [], viewings: viewings.data ?? [] };
};
