import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const { data } = await locals.api.GET('/v1/me/saved-searches');
	return { searches: data ?? [] };
};

export const actions: Actions = {
	delete: async ({ request, locals }) => {
		const id = String((await request.formData()).get('id'));
		await locals.api.DELETE('/v1/me/saved-searches/{savedSearchId}', {
			params: { path: { savedSearchId: id } }
		});
	}
};
