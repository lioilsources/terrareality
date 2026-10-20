import { expect, test } from '@playwright/test';
import { apiRegister, apiRegisterVerified, call, login } from './api';
import { PASSWORD, uniqueEmail, waitForMail } from './helpers';

type Share = { kind: string; due_on: string; amount: number };
type Detail = {
	lease: { origin: string; state: string; cutover_on: string; variable_symbol?: string };
	deposit_held: boolean;
	parties: { role: string; has_account: boolean; invited_at?: string }[];
};

const day = (d: Date) => d.toISOString().slice(0, 10);

// Acceptance M9: a landlord joining the beta imports a flat rented on paper
// two years ago. The lease is active right away, marked as signed outside
// the platform, its payments are tracked from the cutover (no past months
// turn into debt), the deposit is already held and the tenants' own
// variable symbol is kept. The tenant hears nothing until invited; after the
// invitation they sign in and see the lease.
test('import an existing lease, no past debt, invite the tenant', async ({ browser }) => {
	test.setTimeout(180_000);
	const owner = uniqueEmail('paper-lessor');
	const tenant = uniqueEmail('paper-tenant');
	const ownerToken = await apiRegister(owner, 'Lucie Pronajímatelka');
	const verify = await waitForMail(owner, 'Potvrďte');
	await call(ownerToken, 'POST', '/v1/auth/email/verify', {
		token: new URL(verify.match(/https?:\/\/\S+/)![0]).searchParams.get('token')
	});
	const me = await call<{ organizations: { organization: { id: string } }[] }>(
		ownerToken,
		'GET',
		'/v1/me'
	);
	const orgId = me.organizations[0].organization.id;

	// The entry sits next to the new-lease action.
	const o = await login(browser, owner, PASSWORD, `/admin/orgs/${orgId}/smlouvy`);
	await o.getByRole('link', { name: 'Přidat existující nájem' }).click();
	await o.waitForURL(/\/smlouvy\/existujici$/);

	const now = new Date();
	const start = new Date(Date.UTC(now.getUTCFullYear() - 2, now.getUTCMonth(), 1));
	const nextMonth = day(new Date(Date.UTC(now.getFullYear(), now.getMonth() + 1, 1)));

	await o.getByLabel('Adresa bytu').fill('dejvick');
	await o.getByRole('listbox').getByRole('button').first().click();
	await o.getByLabel('Označení bytu/pokoje').fill('2+kk, 3. NP');
	await o.getByLabel('Typ smlouvy').selectOption('byt_doba_neurcita');
	await o.getByLabel('Začátek nájmu').fill(day(start));
	await o.getByLabel('Nájemné (Kč/měs.)').fill('18500');
	await o.getByLabel('Zálohy na služby (Kč/měs.)').fill('3500');
	await o.getByLabel('Kauce (Kč)').fill('37000');
	await expect(o.getByLabel('Kauci už držím')).toBeChecked();
	await o.getByLabel('IBAN účtu pronajímatele').fill('CZ65 0800 0000 1920 0014 5399');
	await o.getByLabel('Variabilní symbol').fill('0042 1337');
	// Default cutover: the first day of next month.
	await expect(o.getByLabel('Sledovat platby od')).toHaveValue(nextMonth);
	const parties = o.getByTestId('lease-parties');
	await parties.getByLabel('Jméno').fill('Jana Nová');
	await parties.getByLabel('E-mail (nepovinný)').fill(tenant);

	// A symbol with letters is rejected on its field before the api.
	await o.getByLabel('Variabilní symbol').fill('42a');
	await o.getByRole('button', { name: 'Přidat nájem', exact: true }).click();
	await expect(o.getByTestId('error-variable_symbol')).toContainText('1 až 10 číslic');
	await o.getByLabel('Variabilní symbol').fill('0042 1337');

	await o.getByRole('button', { name: 'Přidat nájem', exact: true }).click();
	await o.waitForURL(/\/smlouvy\/[0-9a-f-]{36}$/);
	const leaseId = o.url().split('/').pop()!;

	await expect(o.getByTestId('lease-imported')).toHaveText('Převzatá smlouva');
	await expect(o.getByTestId('lease-state')).toHaveText('Platná');
	await expect(o.getByTestId('lease-vs')).toHaveText('421337');
	await expect(o.getByTestId('lease-deposit')).toContainText('kauci už drží pronajímatel');
	await expect(o.getByTestId('lease-parties')).toContainText('podepsáno mimo platformu');
	// Two years of rent before the cutover are not debt.
	await expect(o.getByTestId('lease-debt')).toContainText('0 Kč');
	// No proposal or signing for a paper contract.
	await expect(o.getByRole('button', { name: 'Odeslat k podpisu' })).toHaveCount(0);
	await expect(o.getByRole('button', { name: 'Podepsat smlouvu' })).toHaveCount(0);

	const detail = await call<Detail>(ownerToken, 'GET', `/v1/leases/${leaseId}`);
	expect(detail.lease.origin).toBe('imported');
	expect(detail.lease.cutover_on).toBe(nextMonth);
	expect(detail.deposit_held).toBe(true);
	const shares = await call<Share[]>(ownerToken, 'GET', `/v1/leases/${leaseId}/obligations`);
	expect(shares.every((s) => s.due_on >= nextMonth)).toBe(true);
	expect(shares.some((s) => s.kind === 'deposit')).toBe(false);

	// The list marks the lease as imported.
	await o.goto(`/admin/orgs/${orgId}/smlouvy`);
	await expect(o.getByTestId('leases').getByTestId('lease-imported')).toHaveText(
		'Převzatá smlouva'
	);

	// The tenant is invited to the portal from the detail.
	await o.goto(`/admin/orgs/${orgId}/smlouvy/${leaseId}`);
	const invite = o.getByTestId('lease-invite');
	await expect(o.getByText(/nedostanou žádný e-mail/)).toBeVisible();
	await expect(invite.getByLabel('E-mail')).toHaveValue(tenant);
	await invite.getByRole('button', { name: 'Pozvat do nájemního portálu' }).click();
	await expect(invite.getByTestId('invite-state')).toContainText('Pozváno');
	await expect(invite.getByRole('button', { name: 'Poslat pozvánku znovu' })).toBeVisible();
	const mail = await waitForMail(tenant, 'Pozvánka do portálu nájemníka');
	expect(mail).toContain(`/smlouvy/${leaseId}`);

	// The tenant signs up with the invited address and sees the lease.
	await apiRegisterVerified(tenant, 'Jana Nová');
	const t = await login(browser, tenant, PASSWORD, `/smlouvy/${leaseId}`);
	await expect(t.getByTestId('lease-imported')).toBeVisible();
	await expect(t.getByTestId('lease-debt')).toContainText('0 Kč');
	await o.reload();
	await expect(o.getByTestId('lease-invite').getByTestId('invite-state')).toContainText(
		'používá nájemní portál'
	);
	await o.context().close();
	await t.context().close();
});
