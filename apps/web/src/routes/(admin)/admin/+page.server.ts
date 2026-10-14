import type { Actions } from './$types';

export const actions: Actions = {
	resend: async ({ locals }) => {
		await locals.api.POST('/v1/auth/email/resend');
		return { resent: true };
	}
};
