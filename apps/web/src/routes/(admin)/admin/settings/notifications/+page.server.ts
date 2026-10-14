import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const [prefs, push] = await Promise.all([
		locals.api.GET('/v1/me/notification-preferences'),
		locals.api.GET('/v1/push/config')
	]);
	return {
		prefs: prefs.data ?? { email_messages: 'instant' as const, push_messages: true },
		vapidKey: push.data?.vapid_public_key ?? ''
	};
};

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.PUT('/v1/me/notification-preferences', {
			body: {
				email_messages: String(f.get('email_messages')) as 'instant',
				push_messages: f.get('push_messages') === 'on'
			}
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { saved: true };
	}
};
