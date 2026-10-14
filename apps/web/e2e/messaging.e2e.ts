import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { expect, test, type Browser, type Page } from '@playwright/test';
import { PASSWORD, register, uniqueEmail, waitForMail } from './helpers';

const API = process.env.API_URL ?? 'http://localhost:8080';
const STAFF = 'staff@terra.local';
const STAFF_PASSWORD = 'terra-dev-password';

/** Minimal api client for test setup (the UI flows are covered elsewhere). */
async function call<T>(token: string, method: string, path: string, body?: unknown): Promise<T> {
	const res = await fetch(API + path, {
		method,
		headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
		body: body === undefined ? undefined : JSON.stringify(body)
	});
	if (!res.ok) throw new Error(`${method} ${path}: ${res.status} ${await res.text()}`);
	return (res.status === 204 ? undefined : await res.json()) as T;
}

async function apiLogin(email: string, password: string): Promise<string> {
	const res = await fetch(`${API}/v1/auth/login`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ email, password })
	});
	const body = (await res.json()) as { session: { token: string } };
	return body.session.token;
}

/** Registers a verified landlord and publishes a flat with a pre-screening question. */
async function publishedListing(title: string) {
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
	return { email, token, userId: me.id, listingId: l.id };
}

async function login(browser: Browser, email: string, password: string, next: string) {
	const ctx = await browser.newContext();
	const page = await ctx.newPage();
	await page.goto(`/login?next=${encodeURIComponent(next)}`);
	await page.getByLabel('E-mail').first().fill(email);
	await page.getByLabel('Heslo', { exact: true }).fill(password);
	await page.getByRole('button', { name: 'Přihlásit se', exact: true }).click();
	await page.waitForURL((u) => u.pathname === next);
	return page;
}

async function send(page: Page, text: string) {
	await page.getByPlaceholder('Zpráva').fill(text);
	await page.getByRole('button', { name: 'Odeslat' }).click();
}

// Acceptance M4: a message reaches the other client within a second; an
// offline client gets a push; a reported conversation shows up in the
// backoffice with an AI suggestion.
test('seeker and landlord chat in realtime, report reaches moderation', async ({
	page,
	browser
}) => {
	test.setTimeout(180_000);
	const tag = randomUUID().slice(0, 6);
	const title = `Byt na chat ${tag}`;
	const owner = await publishedListing(title);

	// Seeker contacts the landlord from the listing, answering the question.
	await register(page, uniqueEmail('seeker'), 'Tomáš Hledající');
	await page.waitForURL((u) => u.pathname === '/admin');
	await page.goto(`/inzerat/${owner.listingId}`);
	const contact = page.getByTestId('contact');
	await contact.getByLabel('Ne').check();
	await contact.getByLabel('Zpráva').fill('Dobrý den, mám zájem o prohlídku. Volejte 777 123 456.');
	await contact.getByRole('button', { name: 'Odeslat' }).click();
	await page.waitForURL(/\/zpravy\/[0-9a-f-]{36}$/);
	const threadPath = new URL(page.url()).pathname;
	const first = page.getByTestId('message').first();
	await expect(first).toContainText('Volejte [•••]');
	await expect(first).toContainText('Kontaktní údaje jsme skryli');

	// Landlord opens the thread; both sides are live.
	const ownerPage = await login(browser, owner.email, PASSWORD, '/zpravy');
	await expect(ownerPage.getByTestId('inbox')).toContainText(title);
	await ownerPage.goto(threadPath);
	await expect(ownerPage.getByTestId('prescreen-answers')).toContainText('Ne');
	await expect(ownerPage.getByTestId('live')).toContainText('Živě');
	await expect(page.getByTestId('live')).toContainText('Živě');

	// Realtime: delivered to the other client in under a second.
	const text = `Mohl bych přijít ve čtvrtek? ${tag}`;
	const started = Date.now();
	await send(page, text);
	await expect(ownerPage.getByTestId('messages')).toContainText(text, { timeout: 5_000 });
	const elapsed = Date.now() - started;
	expect(elapsed, `delivery took ${elapsed} ms`).toBeLessThan(1_000);
	// The open thread sends a read receipt back.
	await expect(page.getByTestId('read-receipt')).toBeVisible();

	await send(ownerPage, `Ano, ve čtvrtek v 17:00 se hodí. ${tag}`);
	await expect(page.getByTestId('messages')).toContainText(`ve čtvrtek v 17:00 se hodí. ${tag}`);

	// Offline: the landlord's phone gets a push, the inbox gets an e-mail.
	await call(owner.token, 'POST', '/v1/me/push-devices', {
		platform: 'fcm',
		token: `e2e-${tag}`,
		label: 'E2E phone'
	});
	await ownerPage.context().close();
	await send(page, `Děkuji, budu tam. ${tag}`);
	const push = await waitForMail(`push+${owner.userId}@push.terra.local`);
	expect(push).toContain(`budu tam. ${tag}`);
	const mail = await waitForMail(owner.email, 'Nová zpráva');
	expect(mail).toContain(threadPath);

	// The seeker reports the conversation.
	await page.getByText('Nahlásit konverzaci').click();
	await page.getByLabel('Důvod').selectOption('advance_payment');
	await page.getByLabel('Poznámka (nepovinné)').fill(`E2E nahlášení ${tag}`);
	await page.getByRole('button', { name: 'Odeslat nahlášení' }).click();
	await expect(page.getByText('nahlášení prověří náš tým')).toBeVisible();

	// Staff see it with an AI suggestion and decide.
	const staff = await login(browser, STAFF, STAFF_PASSWORD, '/backoffice/moderation');
	const item = staff.getByTestId('moderation-queue').getByRole('link').filter({ hasText: title });
	await expect(item).toBeVisible();
	await item.click();
	await expect(staff.getByTestId('transcript')).toContainText(text);
	await expect
		.poll(
			async () => {
				await staff.reload();
				return staff.getByTestId('ai-verdict').isVisible();
			},
			{ timeout: 60_000, intervals: [1_000] }
		)
		.toBe(true);
	await staff.getByLabel('Bez porušení').check();
	await staff.getByRole('button', { name: 'Rozhodnout' }).click();
	await staff.waitForURL((u) => u.pathname === '/backoffice/moderation');
	await expect(staff.getByText(`E2E nahlášení ${tag}`)).toHaveCount(0);
	await staff.context().close();
});
