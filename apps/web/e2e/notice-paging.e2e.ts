import { expect, test } from '@playwright/test';
import { apiRegisterVerified, call, login } from './api';
import { PASSWORD, uniqueEmail } from './helpers';

const day = (d: Date) => d.toISOString().slice(0, 10);

async function verifiedOwner() {
	const email = uniqueEmail('notice-owner');
	const token = await apiRegisterVerified(email, 'Lucie Pronajímatelka');
	const me = await call<{ organizations: { organization: { id: string } }[] }>(
		token,
		'GET',
		'/v1/me'
	);
	return { email, token, orgId: me.organizations[0].organization.id };
}

// A landlord's notice needs a statutory reason (§ 2288 OZ); the platform only
// records it, shows the statutory hints and maps the api errors.
test('landlord notice: reason, explanation, delivery date', async ({ browser }) => {
	test.setTimeout(120_000);
	const owner = await verifiedOwner();
	const tenant = uniqueEmail('notice-tenant');
	const tenantToken = await apiRegisterVerified(tenant, 'Tomáš Nájemník');
	const start = new Date();
	start.setMonth(start.getMonth() - 2);
	const d = await call<{ lease: { id: string } }>(
		owner.token,
		'POST',
		`/v1/orgs/${owner.orgId}/leases`,
		{
			template: 'byt_doba_neurcita',
			starts_on: day(start),
			rent_amount: 1_800_000,
			deposit_amount: 3_600_000,
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

	// The landlord signs in the admin: one enabled provider, named by its level, no choice.
	const o = await login(
		browser,
		owner.email,
		PASSWORD,
		`/admin/orgs/${owner.orgId}/smlouvy/${leaseId}`
	);
	const sign = o.getByTestId('lease-sign');
	await expect(sign.getByTestId('sign-method')).toHaveText('prostý elektronický podpis');
	await expect(sign.getByRole('radio')).toHaveCount(0);
	await sign.getByRole('checkbox').check();
	await o.getByRole('button', { name: 'Podepsat smlouvu' }).click();
	await expect(o.getByTestId('lease-state')).not.toHaveText('Čeká na podpisy');

	// The notice form with the statutory hints replaces the old "not available" text.
	const notice = o.getByTestId('landlord-notice');
	await expect(notice.getByTestId('landlord-notice-info')).toContainText('nejméně 3 měsíce');
	await expect(notice.getByTestId('landlord-notice-info')).toContainText('písemnou formu');
	await expect(notice.getByTestId('landlord-notice-info')).toContainText('soudu');
	const reason = notice.getByLabel('Výpovědní důvod');
	// Indefinite term: the own-use reason (§ 2288 odst. 2) is offered.
	await expect(reason.locator('option[value="flat_needed_for_landlord_or_relative"]')).toHaveCount(
		1
	);

	// Another serious reason without the facts is refused before it reaches the api.
	await reason.selectOption('other_serious_reason');
	await notice.getByLabel('Datum doručení výpovědi').fill(day(new Date()));
	await notice.getByRole('checkbox').check();
	await notice.getByRole('button', { name: 'Zaznamenat výpověď' }).click();
	await expect(notice).toContainText('popište skutečnosti');

	await notice
		.getByLabel('Popis skutečností')
		.fill('Nájemce opakovaně ruší noční klid a ohrožuje ostatní nájemníky.');
	await notice.getByRole('checkbox').check();
	await notice.getByRole('button', { name: 'Zaznamenat výpověď' }).click();
	await expect(o.getByTestId('notice-done')).toContainText('Nájem skončí');
	await expect(o.getByTestId('lease-state')).toHaveText('Ve výpovědi');
	await expect(o.getByTestId('landlord-notice')).toHaveCount(0);
	await o.context().close();
});

// Lists are paged by 50; "Načíst další" is a plain link with the cursor in the URL.
test('org listings: load more with a cursor link', async ({ browser }) => {
	test.setTimeout(180_000);
	const owner = await verifiedOwner();
	const [addr] = await call<{ ruian_id: number }[]>(
		owner.token,
		'GET',
		'/v1/addresses/search?q=dejvick'
	);
	for (let i = 0; i < 51; i++) {
		await call(owner.token, 'POST', `/v1/orgs/${owner.orgId}/listings`, {
			ruian_id: addr.ruian_id,
			unit_kind: 'apartment',
			layout: '1+kk',
			floor_area: 20 + i
		});
	}
	const path = `/admin/orgs/${owner.orgId}/listings`;
	const o = await login(browser, owner.email, PASSWORD, path);
	const list = o.getByTestId('listing-list').getByRole('listitem');
	await expect(list).toHaveCount(50);
	await expect(o.getByTestId('listings-more-first')).toHaveCount(0);
	await o.getByRole('link', { name: 'Načíst další' }).click();
	await expect(o).toHaveURL(/[?&]before=[0-9a-f-]{36}/);
	await expect(list).toHaveCount(1);
	await expect(o.getByTestId('listings-more-next')).toHaveCount(0);
	await o.getByRole('link', { name: 'Zpět na nejnovější' }).click();
	await expect(list).toHaveCount(50);

	// Without JavaScript the same link works (server-rendered paging).
	const ctx = await browser.newContext({
		javaScriptEnabled: false,
		storageState: await o.context().storageState()
	});
	const nojs = await ctx.newPage();
	await nojs.goto(path);
	await nojs.getByRole('link', { name: 'Načíst další' }).click();
	await expect(nojs.getByTestId('listing-list').getByRole('listitem')).toHaveCount(1);
	await ctx.close();
	await o.context().close();
});
