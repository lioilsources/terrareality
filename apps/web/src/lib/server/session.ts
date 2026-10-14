import type { Cookies } from '@sveltejs/kit';

/** HttpOnly cookie holding the opaque api session token. */
export const SESSION_COOKIE = 'terra_session';
/** Staff session kept aside while impersonating a user. */
export const STAFF_COOKIE = 'terra_staff_session';
/** Pending second-factor challenge after a correct password. */
export const MFA_COOKIE = 'terra_mfa';
/** Organization selected in the admin. */
export const ORG_COOKIE = 'terra_org';

const base = { path: '/', httpOnly: true, sameSite: 'lax' } as const;

export function setSession(cookies: Cookies, token: string, expiresAt: string) {
	cookies.set(SESSION_COOKIE, token, { ...base, expires: new Date(expiresAt) });
	cookies.delete(MFA_COOKIE, base);
}

export function clearSession(cookies: Cookies) {
	cookies.delete(SESSION_COOKIE, base);
	cookies.delete(STAFF_COOKIE, base);
}

export function setMfaChallenge(cookies: Cookies, token: string) {
	cookies.set(MFA_COOKIE, token, { ...base, maxAge: 300 });
}

export function setCookie(cookies: Cookies, name: string, value: string, maxAge?: number) {
	cookies.set(name, value, { ...base, maxAge });
}

export function deleteCookie(cookies: Cookies, name: string) {
	cookies.delete(name, base);
}

/** Only same-site relative paths are accepted as post-login targets. */
export function safeNext(next: string | null | undefined, fallback = '/admin'): string {
	if (!next || !next.startsWith('/') || next.startsWith('//') || next.startsWith('/\\'))
		return fallback;
	return next;
}
