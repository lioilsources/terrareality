import { describe, expect, it } from 'vitest';
import type { Cookies } from '@sveltejs/kit';
import {
	SESSION_COOKIE,
	STAFF_COOKIE,
	STAFF_STASH_SECONDS,
	parseStaffStash,
	restoreStaffSession,
	stashStaffSession
} from './session.js';

function jar() {
	const values = new Map<string, { value: string; opts: Record<string, unknown> }>();
	const cookies = {
		get: (name: string) => values.get(name)?.value,
		set: (name: string, value: string, opts: Record<string, unknown>) =>
			values.set(name, { value, opts }),
		delete: (name: string) => values.delete(name)
	} as unknown as Cookies;
	return { cookies, values };
}

describe('staff session stash', () => {
	const now = Date.parse('2026-10-15T10:00:00Z');

	it('restores with the stash expiry, never a fresh 30 days', () => {
		const { cookies, values } = jar();
		stashStaffSession(cookies, 'staff-token', now);
		expect(restoreStaffSession(cookies, now + 60_000)).toBe(true);
		const session = values.get(SESSION_COOKIE)!;
		expect(session.value).toBe('staff-token');
		expect((session.opts.expires as Date).getTime()).toBe(now + STAFF_STASH_SECONDS * 1000);
		expect(session.opts.maxAge).toBeUndefined();
		expect(values.has(STAFF_COOKIE)).toBe(false);
	});

	it('stashes with the staff session exact expiry when it ends sooner', () => {
		const { cookies, values } = jar();
		const ends = new Date(now + 20 * 60_000).toISOString();
		stashStaffSession(cookies, 'staff-token', now, ends);
		expect(restoreStaffSession(cookies, now + 60_000)).toBe(true);
		expect((values.get(SESSION_COOKIE)!.opts.expires as Date).toISOString()).toBe(ends);
	});

	it('never keeps the stash longer than the cap, nor an already expired session', () => {
		const { cookies, values } = jar();
		stashStaffSession(cookies, 'staff-token', now, new Date(now + 30 * 86_400_000).toISOString());
		expect(parseStaffStash(values.get(STAFF_COOKIE)!.value, now)!.expires.getTime()).toBe(
			now + STAFF_STASH_SECONDS * 1000
		);
		const other = jar();
		stashStaffSession(other.cookies, 'staff-token', now, new Date(now - 1000).toISOString());
		expect(other.values.has(STAFF_COOKIE)).toBe(false);
	});

	it('drops an expired or malformed stash and signs out', () => {
		const { cookies, values } = jar();
		stashStaffSession(cookies, 'staff-token', now);
		expect(restoreStaffSession(cookies, now + STAFF_STASH_SECONDS * 1000 + 1)).toBe(false);
		expect(values.has(SESSION_COOKIE)).toBe(false);
		expect(parseStaffStash('legacy-token-without-expiry', now)).toBeNull();
		expect(parseStaffStash(undefined, now)).toBeNull();
	});
});
