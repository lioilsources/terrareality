import { expect, test } from '@playwright/test';
import { API, apiRegister, apiRegisterVerified, call, login } from './api';
import { PASSWORD, uniqueEmail, waitForMail } from './helpers';

type Share = { id: string; due_on: string; amount: number; paid_amount: number; party_id: string };
type Party = { id: string; role: string; position: number };

// Acceptance M6: landlord + two flatmates: joint tenancy -> both sign (mock)
// -> schedule split 50/50 -> QR -> a simulated bank transaction is matched ->
// debt 0; the hash chain verifies. (Escalation after 7 days without payment:
// services/api/internal/workflows/lease_test.go with Temporal time skipping.)
test('joint tenancy: sign, pay by QR, bank match, debt zero', async ({ browser }) => {
	test.setTimeout(180_000);
	const owner = uniqueEmail('lessor');
	const anna = uniqueEmail('anna');
	const ben = uniqueEmail('ben');
	const ownerToken = await apiRegister(owner, 'Lucie Pronajímatelka');
	const verify = await waitForMail(owner, 'Potvrďte');
	await call(ownerToken, 'POST', '/v1/auth/email/verify', {
		token: new URL(verify.match(/https?:\/\/\S+/)![0]).searchParams.get('token')
	});
	await apiRegisterVerified(anna, 'Anna Nováková');
	await apiRegisterVerified(ben, 'Ben Dvořák');
	const me = await call<{ organizations: { organization: { id: string } }[] }>(
		ownerToken,
		'GET',
		'/v1/me'
	);
	const orgId = me.organizations[0].organization.id;

	// The landlord drafts the joint tenancy in the admin.
	const o = await login(browser, owner, PASSWORD, `/admin/orgs/${orgId}/smlouvy/nova`);
	const start = new Date().toISOString().slice(0, 10);
	const endDate = new Date();
	endDate.setFullYear(endDate.getFullYear() + 1);
	endDate.setDate(endDate.getDate() - 1);
	await o.getByLabel('Typ smlouvy').selectOption('spolecny_najem');
	await o.getByLabel('Začátek nájmu').fill(start);
	await o.getByLabel('Konec nájmu').fill(endDate.toISOString().slice(0, 10));
	await o.getByLabel('Nájemné (Kč/měs.)').fill('20000');
	await o.getByLabel('Zálohy na služby (Kč/měs.)').fill('4000');
	await o.getByLabel('Kauce (Kč)').fill('40000');
	await o.getByLabel('IBAN účtu pronajímatele').fill('CZ65 0800 0000 1920 0014 5399');
	await o.getByLabel('Adresa bytu').fill('Dejvická 12, Praha 6');
	await o.getByLabel('Označení bytu/pokoje').fill('3+kk, 2. NP');
	await o.getByLabel('Zákaz kouření').check();
	const parties = o.getByTestId('lease-parties');
	for (const [name, email] of [
		['Anna Nováková', anna],
		['Ben Dvořák', ben]
	]) {
		await o.getByRole('button', { name: 'Přidat nájemce' }).click();
		await parties.getByLabel('Jméno').last().fill(name);
		await parties.getByLabel('E-mail').last().fill(email);
	}
	await o.getByRole('button', { name: 'Vytvořit návrh' }).click();
	await o.waitForURL(/\/smlouvy\/[0-9a-f-]{36}$/);
	const leaseId = o.url().split('/').pop()!;
	await expect(o.getByTestId('lease-state')).toHaveText('Rozpracováno');
	await o.getByRole('button', { name: 'Odeslat k podpisu' }).click();
	await expect(o.getByTestId('lease-state')).toHaveText('Čeká na podpisy');
	expect(await waitForMail(anna, 'Návrh nájemní smlouvy')).toContain(`/smlouvy/${leaseId}`);

	// Both flatmates sign in the tenant portal, then the landlord.
	for (const email of [anna, ben]) {
		const t = await login(browser, email, PASSWORD, `/smlouvy/${leaseId}`);
		await expect(t.getByTestId('sign-method')).toHaveText('prostý elektronický podpis');
		await t.getByTestId('lease-sign').getByRole('checkbox').check();
		await t.getByRole('button', { name: 'Podepsat smlouvu' }).click();
		await expect(t.getByTestId('lease-parties')).toContainText('✓ podepsáno');
		if (email === anna) {
			await t.close();
		} else {
			await t.context().close();
		}
	}
	await o.reload();
	await o.getByTestId('lease-sign').getByRole('checkbox').check();
	await o.getByRole('button', { name: 'Podepsat smlouvu' }).click();
	await expect(o.getByTestId('lease-state')).toHaveText('Podepsáno');

	// Schedule 50/50 with a QR payment for each tenant.
	const a = await login(browser, anna, PASSWORD, `/smlouvy/${leaseId}`);
	const mine = a.getByTestId('my-payments').getByTestId('share');
	await expect(mine.first()).toContainText('20 000');
	await a.getByTestId('my-payments').getByText('Zaplatit QR kódem').first().click();
	await expect(a.getByTestId('qr').first()).toBeVisible();

	// The landlord links the (mock) bank; the tenants pay what is due today.
	await o.goto(`/admin/orgs/${orgId}/banka`);
	await o.getByRole('button', { name: 'Propojit účet' }).click();
	await expect(o.getByTestId('bank-connections')).toContainText('linked');
	const bank = await call<{ connections: { id: string }[] }>(
		ownerToken,
		'GET',
		`/v1/orgs/${orgId}/bank`
	);
	const lease = await call<{ lease: { code: number }; parties: Party[] }>(
		ownerToken,
		'GET',
		`/v1/leases/${leaseId}`
	);
	const shares = await call<Share[]>(ownerToken, 'GET', `/v1/leases/${leaseId}/obligations`);
	const due = shares.filter((s) => s.due_on <= start);
	// The deposit (and the first month when it is due already) for both tenants.
	expect(due.length).toBeGreaterThanOrEqual(2);
	for (const s of due) {
		const position = lease.parties.find((p) => p.id === s.party_id)!.position;
		const res = await fetch(`${API}/dev/bank/transactions`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				connection_id: bank.connections[0].id,
				amount: s.amount,
				variable_symbol: String(lease.lease.code),
				specific_symbol: String(position),
				counterparty: 'Nájemce'
			})
		});
		expect(((await res.json()) as { matched: number }).matched).toBe(1);
	}

	await o.goto(`/admin/orgs/${orgId}/smlouvy/${leaseId}`);
	await expect(o.getByTestId('lease-debt')).toContainText('0 Kč');
	await expect(o.getByTestId('chain')).toContainText('neporušený');
	await a.reload();
	await expect(a.getByTestId('lease-debt')).toContainText('0 Kč');
	await o.context().close();
	await a.context().close();
});
