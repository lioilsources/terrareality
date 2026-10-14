import { randomUUID } from 'node:crypto';
import { expect, test } from '@playwright/test';
import { apiRegister, call, login, publishedListing } from './api';
import { PASSWORD, uniqueEmail, waitForMail } from './helpers';

// Acceptance M5: a group of three files one application with everyone's
// consent; the landlord picks it and the other applicants get an automatic
// answer. (Booking a viewing from Flutter: apps/mobile/test/live_booking_test.dart.)
test('group of three applies, landlord chooses, others are answered', async ({ browser }) => {
	test.setTimeout(180_000);
	const tag = randomUUID().slice(0, 6);
	const title = `Byt pro skupinu ${tag}`;
	const owner = await publishedListing(title);

	const anna = uniqueEmail('anna');
	const ben = uniqueEmail('ben');
	const cyril = uniqueEmail('cyril');
	await apiRegister(anna, 'Anna Nováková');
	await apiRegister(ben, 'Ben Dvořák');
	await apiRegister(cyril, 'Cyril Malý');

	// Anna creates the group and invites Ben and Cyril.
	const a = await login(browser, anna, PASSWORD, '/skupiny');
	await a.getByLabel('Název skupiny').fill(`Trio ${tag}`);
	await a.getByLabel('Pozvat e-mailem (oddělte čárkou)').fill(`${ben}, ${cyril}`);
	await a.getByRole('button', { name: 'Založit skupinu' }).click();
	await a.waitForURL(/\/skupiny\/[0-9a-f-]{36}$/);
	const groupPath = new URL(a.url()).pathname;
	await expect(a.getByTestId('members')).toContainText(ben);
	expect(await waitForMail(ben, 'zve do skupiny')).toContain(groupPath);

	// Ben and Cyril accept; Ben says hello in the group chat (realtime to Anna).
	const b = await login(browser, ben, PASSWORD, groupPath);
	await b.getByRole('button', { name: 'Přijmout pozvánku' }).click();
	await expect(b.getByPlaceholder('Napište skupině')).toBeVisible();
	const c = await login(browser, cyril, PASSWORD, groupPath);
	await c.getByRole('button', { name: 'Přijmout pozvánku' }).click();
	await expect(c.getByPlaceholder('Napište skupině')).toBeVisible();
	await a.reload();
	await b.getByPlaceholder('Napište skupině').fill(`Ten byt ${tag} beru!`);
	await b.getByRole('button', { name: 'Odeslat' }).click();
	await expect(a.getByTestId('group-chat')).toContainText(`Ten byt ${tag} beru!`);

	// Anna applies for the group.
	await a.goto(`/inzerat/${owner.listingId}`);
	await a.getByTestId('apply').click();
	await a.getByLabel(`Za skupinu „Trio ${tag}“`).check();
	await a.getByLabel('Ne').check();
	await a.getByLabel('Délka nájmu (měsíce)').fill('24');
	await a
		.getByLabel('Zpráva pronajímateli')
		.fill('Jsme tři kamarádi, pracujeme nedaleko a hledáme byt na dlouho.');
	await a.getByRole('button', { name: 'Odeslat žádost' }).click();
	await a.waitForURL(/\/zadosti\/[0-9a-f-]{36}$/);
	const appPath = new URL(a.url()).pathname;
	await expect(a.getByTestId('app-status')).toHaveText('Čeká na souhlas skupiny');

	// A competing applicant applies on their own.
	const soloEmail = uniqueEmail('solo');
	const solo = await apiRegister(soloEmail, 'Sára Samostatná');
	const listing = await call<{ prescreen: { id: string }[] }>(
		solo,
		'GET',
		`/v1/listings/${owner.listingId}`
	);
	await call(solo, 'POST', '/v1/applications', {
		listing_id: owner.listingId,
		message: 'Dobrý den, mám zájem.',
		prescreen_answers: { [listing.prescreen[0].id]: 'no' }
	});

	// Ben and Cyril consent; the last consent submits the application.
	for (const page of [b, c]) {
		await page.goto(appPath);
		const consent = page.getByRole('button', { name: 'Souhlasím s podáním žádosti' });
		await consent.click();
		await expect(consent).toHaveCount(0);
	}
	await a.reload();
	await expect(a.getByTestId('app-status')).toHaveText('Odesláno');
	await waitForMail(owner.email, 'Nová žádost');

	// The landlord sees both applicants and chooses the group.
	const o = await login(
		browser,
		owner.email,
		PASSWORD,
		`/admin/orgs/${owner.orgId}/listings/${owner.listingId}/zajemci`
	);
	const applicants = o.getByTestId('applicant');
	await expect(applicants).toHaveCount(2);
	const group = applicants.filter({ hasText: `Trio ${tag}` });
	await expect(group).toContainText('domácnost 3 os.');
	await expect(group.getByTestId('ai-summary')).toContainText('Skupina 3', { timeout: 30_000 });
	await group.getByRole('button', { name: 'Vybrat tohoto zájemce' }).click();
	await expect(group.getByTestId('app-status')).toHaveText('Vybráno');
	await expect(applicants.filter({ hasText: 'Sára' }).getByTestId('app-status')).toContainText(
		'Nepřijato'
	);

	// Automatic answers.
	expect(await waitForMail(soloEmail, 'Odpověď na vaši žádost')).toContain('vybral jiného zájemce');
	await waitForMail(cyril, 'vybral vaši žádost');
	await a.reload();
	await expect(a.getByTestId('app-status')).toHaveText('Vybráno');
});
