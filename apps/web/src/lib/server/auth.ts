import type { AuthResult } from '@terra/contracts';
import { redirect, type Cookies } from '@sveltejs/kit';
import { localizeHref } from '#lib/paraglide/runtime.js';
import { setMfaChallenge, setSession } from './session.js';

/**
 * Applies an AuthResult: stores the session and redirects to `next`, or
 * stores the MFA challenge and redirects to the second-factor page.
 */
export function completeAuth(cookies: Cookies, result: AuthResult, next: string): never {
	if (result.status === 'mfa_required' && result.mfa_token) {
		setMfaChallenge(cookies, result.mfa_token);
		redirect(303, localizeHref(`/login/mfa?next=${encodeURIComponent(next)}`));
	}
	if (result.session) {
		setSession(cookies, result.session.token, result.session.expires_at);
		redirect(303, localizeHref(next));
	}
	throw new Error('unexpected auth result');
}
