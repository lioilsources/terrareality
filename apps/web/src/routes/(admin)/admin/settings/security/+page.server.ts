import { fail } from '@sveltejs/kit';
import QRCode from 'qrcode';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const { data } = await locals.api.GET('/v1/me/sessions');
	return { sessions: data ?? [] };
};

export const actions: Actions = {
	setup: async ({ locals }) => {
		const { data, error } = await locals.api.POST('/v1/me/mfa/totp/setup');
		if (!data) return fail(400, { mfaError: errorMessage(error) });
		const qr = await QRCode.toString(data.otpauth_uri, { type: 'svg', margin: 1, width: 192 });
		return { setup: { secret: data.secret, qr } };
	},
	enable: async ({ request, locals }) => {
		const f = await request.formData();
		const { data, error } = await locals.api.POST('/v1/me/mfa/totp/enable', {
			body: { code: String(f.get('code') ?? '') }
		});
		if (!data) {
			const secret = String(f.get('secret') ?? '');
			return fail(400, {
				mfaError: errorMessage(error),
				setup: secret ? { secret, qr: '' } : undefined
			});
		}
		return { recoveryCodes: data.recovery_codes };
	},
	disable: async ({ request, locals }) => {
		const code = String((await request.formData()).get('code') ?? '');
		const { error } = await locals.api.POST('/v1/me/mfa/totp/disable', { body: { code } });
		if (error) return fail(400, { mfaError: errorMessage(error) });
		return { mfaDisabled: true };
	},
	password: async ({ request, locals }) => {
		const f = await request.formData();
		const current = String(f.get('current_password') ?? '');
		const { error } = await locals.api.POST('/v1/me/password', {
			body: {
				current_password: current || undefined,
				new_password: String(f.get('new_password') ?? '')
			}
		});
		if (error) return fail(400, { passwordError: errorMessage(error) });
		return { passwordChanged: true };
	},
	revoke: async ({ request, locals }) => {
		const id = String((await request.formData()).get('id') ?? '');
		await locals.api.DELETE('/v1/me/sessions/{sessionId}', { params: { path: { sessionId: id } } });
	}
};
