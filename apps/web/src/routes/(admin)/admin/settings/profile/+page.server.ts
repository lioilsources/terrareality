import { fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = ({ url }) => ({
	verified: url.searchParams.get('verified') === '1',
	identityError: url.searchParams.get('error')
});

export const actions: Actions = {
	profile: async ({ request, locals }) => {
		const f = await request.formData();
		const locale = f.get('locale') === 'en' ? 'en' : 'cs';
		const { error } = await locals.api.PATCH('/v1/me', {
			body: { display_name: String(f.get('display_name') ?? ''), locale }
		});
		if (error) return fail(400, { profileError: errorMessage(error) });
		return { profileSaved: true };
	},
	phone: async ({ request, locals }) => {
		const phone = String((await request.formData()).get('phone') ?? '').replace(/\s/g, '');
		const { error } = await locals.api.POST('/v1/me/phone', { body: { phone } });
		if (error) return fail(400, { phone, phoneError: errorMessage(error) });
		return { phone, phoneSent: true };
	},
	phoneVerify: async ({ request, locals }) => {
		const code = String((await request.formData()).get('code') ?? '');
		const { error } = await locals.api.POST('/v1/me/phone/verify', { body: { code } });
		if (error) return fail(400, { phoneSent: true, phoneError: errorMessage(error) });
		return { phoneVerified: true };
	},
	identity: async ({ locals, url }) => {
		const { data, error } = await locals.api.POST('/v1/me/identity/start', {
			body: { redirect_uri: `${url.origin}/auth/identity` }
		});
		if (!data) return fail(400, { identityError: errorMessage(error) });
		redirect(303, data.authorization_url, { external: true });
	}
};
