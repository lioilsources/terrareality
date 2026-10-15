import { randomUUID } from 'node:crypto';
import { expect, test } from '@playwright/test';
import { apiRegister, apiRegisterVerified, call, login, publishedListing } from './api';
import { PASSWORD, uniqueEmail, waitForMail } from './helpers';

const day = (d: Date) => d.toISOString().slice(0, 10);

/** Registers an owner with a verified e-mail and returns the token and the org id. */
async function verifiedOwner(name: string) {
	const email = uniqueEmail('billing-owner');
	const token = await apiRegister(email, name);
	const verify = await waitForMail(email, 'Potvrďte');
	await call(token, 'POST', '/v1/auth/email/verify', {
		token: new URL(verify.match(/https?:\/\/\S+/)![0]).searchParams.get('token')
	});
	const me = await call<{ organizations: { organization: { id: string } }[] }>(
		token,
		'GET',
		'/v1/me'
	);
	return { email, token, orgId: me.organizations[0].organization.id };
}

// Acceptance M7: the owner buys a 7-day top placement by card (mock Stripe
// Checkout), the signed webhook marks the order paid, an invoice with a gapless
// number and a PDF is issued and e-mailed, and the listing is shown first in
// search with a transparent „Topováno“ label.
test('promotion: pay by card, invoice, promoted in search', async ({ browser }) => {
	test.setTimeout(240_000);
	const token = `topbyt${randomUUID().replace(/-/g, '').slice(0, 10)}`;
	const owner = await publishedListing(`Byt ${token} u metra Dejvická`);
	const listingPath = `/admin/orgs/${owner.orgId}/listings/${owner.listingId}`;
	const billing = `/admin/orgs/${owner.orgId}/fakturace`;

	const o = await login(browser, owner.email, PASSWORD, listingPath);
	await o.getByTestId('listing-promo-link').click();
	await o.waitForURL((u) => u.pathname === `${listingPath}/propagace`);
	await o.getByTestId('promo-product-top_7d').click();
	await expect(o.getByTestId('promo-product-top_7d').getByRole('radio')).toBeChecked();
	await o.getByTestId('promo-pay').click();

	// The mock Stripe Checkout page is served by the api.
	await o.waitForURL((u) => u.pathname.startsWith('/mock/stripe/checkout/'));
	await o.getByRole('button', { name: 'Zaplatit' }).click();
	await o.waitForURL((u) => u.pathname === billing);

	// The page polls every 2 s while the webhook is being processed.
	await expect(o.getByTestId('billing-pending').or(o.getByTestId('billing-paid'))).toBeVisible();
	await expect(o.getByTestId('billing-paid')).toBeVisible({ timeout: 60_000 });
	await expect(o.getByTestId('order-row').first()).toHaveAttribute('data-status', 'paid');

	// The invoice is issued right after the payment (reload until it is listed).
	await expect(async () => {
		await o.reload();
		await expect(o.getByTestId('invoice-row')).toHaveCount(1, { timeout: 2_000 });
	}).toPass({ timeout: 60_000, intervals: [2_000] });
	const number = (await o.getByTestId('invoice-number').first().textContent())!.trim();
	expect(number).toMatch(/^TR-\d{4}-\d{6}$/);
	const href = await o.getByTestId('invoice-pdf').first().getAttribute('href');
	const pdf = await o.request.get(href!);
	expect(pdf.status()).toBe(200);
	expect(pdf.headers()['content-type']).toContain('application/pdf');
	expect((await pdf.body()).subarray(0, 4).toString()).toBe('%PDF');

	// The buyer gets the invoice e-mail with its number.
	const mail = await waitForMail(owner.email, 'Faktura');
	expect(mail).toContain(number);

	// Public search: the promoted listing comes first with the disclosure label.
	const p = await browser.newPage();
	await p.goto(`/hledat?text=${token}`);
	const first = p.getByTestId('results').getByTestId('listing-card').first();
	await expect(first).toHaveAttribute('href', new RegExp(`/inzerat/${owner.listingId}$`));
	await expect(first).toHaveAttribute('data-promoted', 'true');
	await expect(first.getByTestId('promoted-label')).toHaveText('Topováno');
	await p.context().close();
	await o.context().close();
});

// Acceptance M7: the landlord connects their own Revolut Business merchant
// account; an obligation share then gets a Revolut payment link (money goes
// landlord-direct, ADR 0002). Without a connected account the owner sees a hint.
test('revolut: connect merchant account and pay a share', async ({ browser }) => {
	test.setTimeout(180_000);
	const owner = await verifiedOwner('Lucie Pronajímatelka');
	const tenant = uniqueEmail('revolut-tenant');
	const tenantToken = await apiRegisterVerified(tenant, 'Tomáš Nájemník');
	const d = await call<{ lease: { id: string } }>(
		owner.token,
		'POST',
		`/v1/orgs/${owner.orgId}/leases`,
		{
			template: 'byt_doba_neurcita',
			starts_on: day(new Date()),
			rent_amount: 2_000_000,
			services_amount: 300_000,
			deposit_amount: 4_000_000,
			due_day: 15,
			payee_iban: 'CZ65 0800 0000 1920 0014 5399',
			payee_name: 'Lucie Pronajímatelka',
			property_address: 'Dejvická 12, Praha 6',
			unit_label: '2+kk',
			parties: [{ name: 'Tomáš Nájemník', email: tenant, role: 'tenant' }]
		}
	);
	const leaseId = d.lease.id;
	await call(owner.token, 'POST', `/v1/orgs/${owner.orgId}/leases/${leaseId}/propose`);
	await call(tenantToken, 'POST', `/v1/leases/${leaseId}/sign`, { provider: 'mock' });
	await call(owner.token, 'POST', `/v1/leases/${leaseId}/sign`, { provider: 'mock' });
	const leasePath = `/admin/orgs/${owner.orgId}/smlouvy/${leaseId}`;

	// Not connected yet: a hint instead of the Revolut button.
	const o = await login(browser, owner.email, PASSWORD, leasePath);
	await expect(o.getByTestId('share').first()).toBeVisible();
	await expect(o.getByTestId('revolut-connect-hint')).toBeVisible();
	await expect(o.getByTestId('revolut-pay')).toHaveCount(0);

	// Connect the merchant account (sandbox).
	await o.goto(`/admin/orgs/${owner.orgId}/fakturace#revolut`);
	await expect(o.getByTestId('revolut-status')).not.toContainText('Připojeno');
	const form = o.getByTestId('revolut-form');
	await form.getByLabel('API klíč').fill(`sk_sandbox_e2e_${randomUUID().slice(0, 8)}`);
	await form.getByLabel('Režim').selectOption('sandbox');
	await form.getByRole('button', { name: 'Připojit Revolut' }).click();
	await expect(o.getByTestId('revolut-status')).toContainText('Připojeno');

	// The owner opens a Revolut payment link for an open share.
	await o.goto(leasePath);
	await expect(o.getByTestId('revolut-connect-hint')).toHaveCount(0);
	await o.getByTestId('revolut-pay').first().click();
	await o.waitForURL((u) => u.pathname.startsWith('/mock/revolut/pay/'));
	await expect(o.getByRole('heading', { name: 'Sandbox platba' })).toBeVisible();
	await o.context().close();
});
