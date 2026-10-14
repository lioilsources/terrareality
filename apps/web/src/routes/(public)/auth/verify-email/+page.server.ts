import type { PageServerLoad } from './$types';

// Verifying on GET is fine here: the token only proves the e-mail arrived.
export const load: PageServerLoad = async ({ url, locals }) => {
	const token = url.searchParams.get('token') ?? '';
	if (token.length < 20) return { ok: false };
	const { response } = await locals.api.POST('/v1/auth/email/verify', { body: { token } });
	return { ok: response.status === 204, loggedIn: !!locals.me };
};
