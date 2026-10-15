import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const [apps, viewings, leases] = await Promise.all([
		locals.api.GET('/v1/applications'),
		locals.api.GET('/v1/me/viewings'),
		locals.api.GET('/v1/me/leases')
	]);
	return {
		applications: apps.data ?? [],
		viewings: viewings.data ?? [],
		leases: leases.data ?? []
	};
};

export const actions: Actions = {
	resend: async ({ locals }) => {
		await locals.api.POST('/v1/auth/email/resend');
		return { resent: true };
	}
};
