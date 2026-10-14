import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ locals }) => {
	let unread = 0;
	if (locals.me) {
		const { data } = await locals.api.GET('/v1/me/notifications');
		unread = data?.unread ?? 0;
	}
	return { me: locals.me, unread };
};
