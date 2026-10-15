import { randomUUID } from 'node:crypto';
import { expect, test } from '@playwright/test';
import { login, publishedListing, STAFF, STAFF_PASSWORD } from './api';
import { uniqueEmail, waitForMail } from './helpers';

// Acceptance M8 (DSA notice-and-action, art. 16/17): an anonymous visitor
// reports a listing from its public page; the report lands in the backoffice
// moderation queue; a staff member (human decision, ADR 0003) unpublishes it
// with reasons. The reporter gets an acknowledgement and a statement of
// reasons, the owner learns about the unpublish.
test('anonymous visitor reports a listing, staff unpublish it with reasons', async ({
	browser
}) => {
	test.setTimeout(180_000);
	const tag = randomUUID().slice(0, 8);
	const title = `Byt DSA ${tag}`;
	const owner = await publishedListing(title);
	const reporter = uniqueEmail('dsa-reporter');
	const explanation = `Inzerát ${tag} chce zálohu předem na cizí účet bez prohlídky bytu.`;

	// Anonymous visitor: listing page -> report form (no sign-in needed).
	const ctx = await browser.newContext();
	const v = await ctx.newPage();
	await v.goto(`/inzerat/${owner.listingId}`);
	await v.getByTestId('report-listing-link').click();
	await v.waitForURL((u) => u.pathname === `/inzerat/${owner.listingId}/nahlasit`);
	const form = v.getByTestId('report-form');
	await form.getByLabel('Podvod').check();
	await form.getByLabel('Vysvětlení').fill(explanation);
	await form.getByLabel('Váš e-mail').fill(reporter);
	await form.getByLabel('Jméno (nepovinné)').fill('Jana Oznamovatelka');
	await v.getByTestId('report-submit').click();
	await expect(v.getByTestId('report-sent')).toBeVisible();
	await expect(v.getByTestId('report-sent')).toContainText('Číslo oznámení');

	// Acknowledgement e-mail (Mailpit).
	const ack = await waitForMail(reporter, 'Přijali jsme vaše oznámení');
	expect(ack).toContain(title);
	expect(ack).toContain(explanation);
	await ctx.close();

	// Staff see the listing report in the moderation queue and decide.
	const staff = await login(browser, STAFF, STAFF_PASSWORD, '/backoffice/moderation');
	const item = staff
		.getByTestId('moderation-queue')
		.getByRole('link')
		.filter({ hasText: title })
		.first();
	await expect(item.getByTestId('case-kind-listing')).toBeVisible();
	await item.click();
	await expect(staff.getByTestId('listing-report')).toContainText(explanation);
	await expect(staff.getByTestId('case-reporter')).toContainText(reporter);
	const reasons = `Záloha předem bez prohlídky odporuje podmínkám služby (${tag}).`;
	await staff.getByTestId('decision-unpublish').check();
	await staff.getByTestId('decision-note').fill(reasons);
	await staff.getByTestId('decision-submit').click();
	await staff.waitForURL((u) => u.pathname === '/backoffice/moderation');
	await expect(staff.getByText(title)).toHaveCount(0);
	await staff.context().close();

	// Statement of reasons to the reporter and the owner; the listing is offline.
	const decided = await waitForMail(reporter, 'Rozhodnutí o vašem oznámení');
	expect(decided).toContain(reasons);
	const ownerMail = await waitForMail(owner.email, 'stáhli z nabídky');
	expect(ownerMail).toContain(reasons);
	const p = await browser.newPage();
	const res = await p.goto(`/inzerat/${owner.listingId}`);
	expect(res?.status()).toBe(404);
	await p.context().close();
});
