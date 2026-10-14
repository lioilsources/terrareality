import { randomUUID } from 'node:crypto';
import { expect, test, type Page } from '@playwright/test';
import { call, login, publishedListing, STAFF, STAFF_PASSWORD } from './api';
import { PASSWORD, register, uniqueEmail, waitForMail } from './helpers';

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
