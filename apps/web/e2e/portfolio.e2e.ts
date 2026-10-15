import { expect, test } from '@playwright/test';
import { API, apiRegister, call, login } from './api';
import { PASSWORD, uniqueEmail, waitForMail } from './helpers';

type Share = { id: string; kind: string; due_on: string; amount: number; paid_amount: number };
type Risk = { score?: number; band?: string; factors: { key: string }[]; landlord: boolean };
type Ledger = { account: string; amount: number; booked_on: string }[];

const day = (d: Date) => d.toISOString().slice(0, 10);

/** Parses RFC 4180 CSV (quoted fields may contain commas). */
function parseCSV(text: string): string[][] {
	const rows: string[][] = [];
	let row: string[] = [];
	let cell = '';
	let quoted = false;
	for (let i = 0; i < text.length; i++) {
		const c = text[i];
		if (quoted) {
			if (c === '"' && text[i + 1] === '"') {
				cell += '"';
				i++;
			} else if (c === '"') quoted = false;
			else cell += c;
		} else if (c === '"') quoted = true;
		else if (c === ',') {
			row.push(cell);
			cell = '';
		} else if (c === '\n') {
			row.push(cell);
			rows.push(row);
			row = [];
			cell = '';
		} else cell += c;
	}
	if (cell || row.length) rows.push([...row, cell]);
	return rows;
}

// Acceptance M6b: an owner with leases in Praha, Brno and Ostrava with
// different payment histories sees different risks with explained factors,
// the weighted risk and concentration, income by municipality and actions;
// a D+7 escalation raises the score within minutes (the plan allows 1 h);
// an investor reads the portfolio but cannot change anything; the rent roll
// CSV matches the leases' ledgers.
test('portfolio across municipalities with lease risk', async ({ browser }) => {
	test.setTimeout(300_000);
	const owner = uniqueEmail('portfolio');
	const ownerToken = await apiRegister(owner, 'Rodina Investorů');
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
	const org = `/v1/orgs/${orgId}`;

	const today = new Date();
	const start = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth() - 3, 1));
	const brnoEnd = new Date(Date.UTC(start.getUTCFullYear() + 1, start.getUTCMonth(), 0));
	const ostravaEnd = new Date(today.getTime() + 40 * 86_400_000);
	const specs = [
		{ city: 'Praha', address: 'Dejvická 12, Praha 6', tpl: 'byt_doba_neurcita', rent: 2_500_000 },
		{
			city: 'Brno',
			address: 'Kounicova 20, Brno',
			tpl: 'byt_doba_urcita',
			rent: 1_800_000,
			end: brnoEnd
		},
		{
			city: 'Ostrava',
			address: 'Nádražní 20, Ostrava',
			tpl: 'byt_doba_urcita',
			rent: 1_400_000,
			end: ostravaEnd
		}
	];
	const leases: Record<string, string> = {};
	const tenants: Record<string, { email: string; token: string }> = {};
	for (const s of specs) {
		const email = uniqueEmail(`najemce-${s.city.toLowerCase()}`);
		const token = await apiRegister(email, `Nájemce ${s.city}`);
		tenants[s.city] = { email, token };
		const d = await call<{ lease: { id: string } }>(ownerToken, 'POST', `${org}/leases`, {
			template: s.tpl,
			starts_on: day(start),
			ends_on: s.end ? day(s.end) : undefined,
			rent_amount: s.rent,
			services_amount: 300_000,
			deposit_amount: 2 * s.rent,
			due_day: 15,
			payee_iban: 'CZ65 0800 0000 1920 0014 5399',
			payee_name: 'Rodina Investorů',
			property_address: s.address,
			unit_label: '2+kk',
			parties: [{ name: `Nájemce ${s.city}`, email, role: 'tenant' }]
		});
		leases[s.city] = d.lease.id;
		await call(ownerToken, 'POST', `${org}/leases/${d.lease.id}/propose`);
		await call(token, 'POST', `/v1/leases/${d.lease.id}/sign`, { provider: 'mock' });
		await call(ownerToken, 'POST', `/v1/leases/${d.lease.id}/sign`, { provider: 'mock' });
	}

	// Praha pays everything, Ostrava the rent only and gives notice, Brno nothing.
	async function pay(city: string, kinds: string[]) {
		const shares = await call<Share[]>(ownerToken, 'GET', `/v1/leases/${leases[city]}/obligations`);
		for (const s of shares) {
			if (s.due_on > day(today) || s.paid_amount >= s.amount || !kinds.includes(s.kind)) continue;
			await call(ownerToken, 'POST', `${org}/obligation-shares/${s.id}/paid`, {});
		}
	}
	await pay('Praha', ['deposit', 'rent', 'services']);
	await pay('Ostrava', ['rent', 'services']);
	await call(tenants.Ostrava.token, 'POST', `/v1/leases/${leases.Ostrava}/notice`, {
		delivered_on: day(today)
	});

	// The worker scores the leases (every minute).
	const risk = (city: string, token = ownerToken) =>
		call<Risk>(token, 'GET', `/v1/leases/${leases[city]}/risk`);
	const scoreOf = async (city: string) => {
		try {
			return (await risk(city)).score ?? -1;
		} catch {
			return -1;
		}
	};
	for (const city of ['Praha', 'Brno', 'Ostrava']) {
		await expect
			.poll(() => scoreOf(city), { timeout: 120_000, intervals: [2_000] })
			.toBeGreaterThanOrEqual(0);
	}
	const before = {
		praha: await scoreOf('Praha'),
		brno: await scoreOf('Brno'),
		ostrava: await scoreOf('Ostrava')
	};
	expect(before.praha).toBeLessThan(before.ostrava);
	expect(before.ostrava).toBeLessThan(before.brno);

	// Dashboard: three municipalities with different risk, concentration, actions.
	const o = await login(browser, owner, PASSWORD, `/admin/orgs/${orgId}/portfolio`);
	const cities = o.getByTestId('pf-city');
	await expect(cities).toHaveCount(3);
	await expect(o.locator('[data-city="Praha"] [data-testid="risk-badge"]')).toHaveAttribute(
		'data-band',
		'low'
	);
	await expect(o.locator('[data-city="Brno"] [data-testid="risk-badge"]')).not.toHaveAttribute(
		'data-band',
		'low'
	);
	await expect(o.getByTestId('pf-weighted').getByTestId('risk-badge')).toBeVisible();
	await expect(o.getByTestId('pf-concentration')).toContainText('Praha');
	await expect(o.getByTestId('pf-attention').locator('[data-kind="notice"]')).toContainText(
		'Nádražní 20'
	);
	await expect(o.getByTestId('pf-attention').locator('[data-kind="debt"]').first()).toBeVisible();

	// A D+7 escalation of the Brno lease (as the workflow timer fires it) raises its score.
	const esc = await fetch(`${API}/dev/leases/${leases.Brno}/escalate`, { method: 'POST' });
	expect(esc.status).toBe(200);
	await expect
		.poll(() => scoreOf('Brno'), { timeout: 150_000, intervals: [3_000] })
		.toBeGreaterThan(before.brno);
	await o.reload();
	await expect(o.getByTestId('pf-attention').locator('[data-kind="escalation"]')).toContainText(
		'Kounicova 20'
	);

	// The lease detail explains the factors; the tenant sees only the payment factors.
	await o.goto(`/admin/orgs/${orgId}/smlouvy/${leases.Brno}`);
	await expect(o.getByTestId('lease-risk-score').getByTestId('risk-badge')).toHaveAttribute(
		'data-band',
		'high'
	);
	await expect(o.getByTestId('risk-factors').locator('[data-factor="escalations"]')).toContainText(
		'1×'
	);
	const t = await login(browser, tenants.Brno.email, PASSWORD, `/smlouvy/${leases.Brno}`);
	await expect(t.getByTestId('lease-risk')).toContainText('Co ovlivňuje hodnocení vaší smlouvy');
	await expect(t.getByTestId('risk-factors').locator('li')).toHaveCount(4);
	await expect(t.getByTestId('lease-risk').getByTestId('risk-badge')).toHaveCount(0);
	await t.context().close();

	// Rent roll: the CSV export matches every lease's ledger.
	await o.goto(`/admin/orgs/${orgId}/portfolio/rent-roll`);
	await expect(o.getByTestId('rent-roll').locator('tbody tr')).toHaveCount(3);
	const csv = await (
		await o.request.get(`/admin/orgs/${orgId}/portfolio/rent-roll/export.csv`)
	).text();
	const [header, ...rows] = parseCSV(csv);
	const col = (name: string) => header.indexOf(name);
	expect(rows).toHaveLength(3);
	for (const city of ['Praha', 'Brno', 'Ostrava']) {
		const ledger = await call<Ledger>(ownerToken, 'GET', `/v1/leases/${leases[city]}/ledger`);
		const debt = ledger
			.filter((e) => e.account === 'receivable' && e.booked_on <= day(today))
			.reduce((sum, e) => sum + e.amount, 0);
		const row = rows.find((r) => r[col('municipality')] === city)!;
		expect(row[col('debt')], city).toBe((debt / 100).toFixed(2));
	}
	const xlsx = await o.request.get(`/admin/orgs/${orgId}/portfolio/rent-roll/export.xlsx`);
	expect(xlsx.headers()['content-type']).toContain('spreadsheetml');

	// AI summary: a suggestion the owner reads.
	await o.goto(`/admin/orgs/${orgId}/portfolio`);
	await o.getByRole('button', { name: 'Navrhnout shrnutí' }).click();
	await expect(o.getByTestId('pf-ai-summary')).toContainText('Běžící nájmy: 3, obce: 3');

	// The investor reads the portfolio (tenant initials only) and changes nothing.
	const investor = uniqueEmail('investor');
	const investorToken = await apiRegister(investor, 'Banka Investor');
	await call(ownerToken, 'POST', `${org}/invitations`, { email: investor, role: 'investor' });
	const invite = await waitForMail(investor, 'Pozvánka');
	const invToken = new URL(invite.match(/https?:\/\/\S+/)![0]).pathname.split('/').pop();
	await call(investorToken, 'POST', `/v1/invitations/${invToken}/accept`);
	const i = await login(browser, investor, PASSWORD, `/admin/orgs/${orgId}/portfolio`);
	await expect(i.getByText('Máte přístup jen pro čtení.')).toBeVisible();
	await expect(i.getByTestId('pf-city')).toHaveCount(3);
	await i.goto(`/admin/orgs/${orgId}/portfolio/rent-roll`);
	await expect(i.getByTestId('rent-roll')).not.toContainText('Nájemce Brno');
	await expect(i.getByTestId('rent-roll')).toContainText('N. B.');
	await i.goto(`/admin/orgs/${orgId}/portfolio/nastaveni`);
	await expect(i.getByRole('button', { name: 'Uložit váhy' })).toHaveCount(0);
	const denied = await fetch(`${API}${org}/portfolio/risk-weights`, {
		method: 'PUT',
		headers: { Authorization: `Bearer ${investorToken}`, 'Content-Type': 'application/json' },
		body: JSON.stringify({ weights: { debt: 1 } })
	});
	expect(denied.status).toBe(403);
	await i.context().close();
	await o.context().close();
});
