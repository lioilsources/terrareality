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

/**
 * Set-Cookie values that clear the session, for responses built outside
 * SvelteKit's resolve path (which is where `cookies.delete` is applied).
 */
export function clearSessionHeaders(cookies: Cookies): string[] {
	return [SESSION_COOKIE, STAFF_COOKIE].map((name) =>
		cookies.serialize(name, '', { ...base, maxAge: 0 })
	);
}

/** How long a staff session is kept aside during impersonation. */
export const STAFF_STASH_SECONDS = 60 * 60 * 2;

/**
 * Keeps the staff session aside while impersonating. The value carries its own
 * expiry, so restoring it never outlives the stash (the api does not expose the
 * staff session's own expiry; the cookie expiry is not sent back by browsers).
 */
export function stashStaffSession(cookies: Cookies, token: string, now = Date.now()) {
	const expires = new Date(now + STAFF_STASH_SECONDS * 1000);
	cookies.set(STAFF_COOKIE, `${token}|${expires.toISOString()}`, { ...base, expires });
}

/** Parses a stashed staff session; null when missing, malformed or expired. */
export function parseStaffStash(
	value: string | undefined,
	now = Date.now()
): { token: string; expires: Date } | null {
	if (!value) return null;
	const i = value.lastIndexOf('|');
	if (i <= 0) return null;
	const expires = new Date(value.slice(i + 1));
	if (Number.isNaN(expires.getTime()) || expires.getTime() <= now) return null;
	return { token: value.slice(0, i), expires };
}

/** Restores the staff session stashed by stashStaffSession; false when there is none. */
export function restoreStaffSession(cookies: Cookies, now = Date.now()): boolean {
	const stash = parseStaffStash(cookies.get(STAFF_COOKIE), now);
	cookies.delete(STAFF_COOKIE, base);
	if (!stash) {
		cookies.delete(SESSION_COOKIE, base);
		return false;
	}
	cookies.set(SESSION_COOKIE, stash.token, { ...base, expires: stash.expires });
	return true;
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
