import { readFileSync } from 'node:fs';
import { expect, type Browser } from '@playwright/test';
import { PASSWORD, uniqueEmail, waitForMail } from './helpers';

export const API = process.env.API_URL ?? 'http://localhost:8080';
export const STAFF = 'staff@terra.local';
export const STAFF_PASSWORD = 'terra-dev-password';

/** Minimal api client for test setup (the UI flows are covered elsewhere). */
export async function call<T>(
	token: string,
	method: string,
	path: string,
	body?: unknown
): Promise<T> {
	const res = await fetch(API + path, {
		method,
		headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
		body: body === undefined ? undefined : JSON.stringify(body)
	});
	if (!res.ok) throw new Error(`${method} ${path}: ${res.status} ${await res.text()}`);
	return (res.status === 204 ? undefined : await res.json()) as T;
}

export async function apiLogin(email: string, password: string): Promise<string> {
	const res = await fetch(`${API}/v1/auth/login`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ email, password })
	});
	const body = (await res.json()) as { session: { token: string } };
	return body.session.token;
}

/** Registers a user through the api and returns the session token. */
export async function apiRegister(email: string, name: string): Promise<string> {
	const res = await fetch(`${API}/v1/auth/register`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({
			email,
			password: PASSWORD,
			display_name: name,
			accept_terms_version: '2026-10',
			accept_privacy_version: '2026-10'
		})
	});
	return ((await res.json()) as { session: { token: string } }).session.token;
}

/** Registers a verified landlord and publishes a flat with a pre-screening question. */
export async function publishedListing(title: string) {
	const email = uniqueEmail('landlord');
	const reg = await fetch(`${API}/v1/auth/register`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({
			email,
			password: PASSWORD,
			display_name: 'Lucie Pronajímatelka',
			accept_terms_version: '2026-10',
			accept_privacy_version: '2026-10'
		})
	});
	const token = ((await reg.json()) as { session: { token: string } }).session.token;
	const verify = await waitForMail(email, 'Potvrďte');
	const verifyToken = new URL(verify.match(/https?:\/\/\S+/)![0]).searchParams.get('token');
	await call(token, 'POST', '/v1/auth/email/verify', { token: verifyToken });
	const me = await call<{ id: string; organizations: { organization: { id: string } }[] }>(
		token,
		'GET',
		'/v1/me'
	);
	const org = me.organizations[0].organization.id;
	const [addr] = await call<{ ruian_id: number }[]>(token, 'GET', '/v1/addresses/search?q=dejvick');
	const l = await call<{ id: string; attributes: Record<string, unknown> }>(
		token,
		'POST',
		`/v1/orgs/${org}/listings`,
		{ ruian_id: addr.ruian_id, unit_kind: 'apartment', layout: '2+kk', floor_area: 54 }
	);
	const path = `/v1/orgs/${org}/listings/${l.id}`;
	await call(token, 'PUT', path, {
		title: { cs: title, en: '' },
		description: {
			cs: 'Světlý byt 2+kk v cihlovém domě s výtahem, metro Dejvická pět minut pěšky.',
			en: ''
		},
		rent_amount: 2_200_000,
		deposit_amount: 4_400_000,
		attributes: l.attributes,
		location_precision: 'approximate'
	});
	const photo = readFileSync('e2e/fixtures/flat.jpg');
	const up = await call<{ media: { id: string }; upload_url: string }>(
		token,
		'POST',
		`${path}/media`,
		{ filename: 'flat.jpg', content_type: 'image/jpeg', size: photo.length }
	);
	await fetch(up.upload_url, {
		method: 'PUT',
		headers: { 'Content-Type': 'image/jpeg' },
		body: photo
	});
	await call(token, 'POST', `/v1/orgs/${org}/media/${up.media.id}/complete`);
	await expect
		.poll(
			async () =>
				(await call<{ media: { status: string }[] }>(token, 'GET', path)).media[0]?.status,
			{ timeout: 30_000 }
		)
		.toBe('ready');
	await call(token, 'PUT', `${path}/prescreen`, [
		{ text: { cs: 'Máte domácí zvíře?' }, kind: 'yes_no', required: true }
	]);
	await call(token, 'POST', `${path}/submit`);
	const staff = await apiLogin(STAFF, STAFF_PASSWORD);
	const queue = await call<{ version_id: string; listing_id: string }[]>(
		staff,
		'GET',
		'/v1/backoffice/reviews'
	);
	const v = queue.find((q) => q.listing_id === l.id)!;
	await call(staff, 'POST', `/v1/backoffice/reviews/${v.version_id}/decision`, { approve: true });
	return { email, token, userId: me.id, listingId: l.id, orgId: org };
}

export async function login(browser: Browser, email: string, password: string, next: string) {
	const ctx = await browser.newContext();
	const page = await ctx.newPage();
	await page.goto(`/login?next=${encodeURIComponent(next)}`);
	await page.getByLabel('E-mail').first().fill(email);
	await page.getByLabel('Heslo', { exact: true }).fill(password);
	await page.getByRole('button', { name: 'Přihlásit se', exact: true }).click();
	await page.waitForURL((u) => u.pathname === next);
	return page;
}
