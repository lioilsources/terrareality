import { describe, expect, it } from 'vitest';
import { render } from 'svelte/server';
import LeaseSignForm from './LeaseSignForm.svelte';
import LandlordNoticeForm from './LandlordNoticeForm.svelte';
import LoadMore from './LoadMore.svelte';
import ImportedLeasePanel from './ImportedLeasePanel.svelte';
import LeaseImportForm from './LeaseImportForm.svelte';
import LeaseSummary from './LeaseSummary.svelte';

describe('LeaseSignForm', () => {
	it('names a single provider by its level and offers no choice', () => {
		const { body } = render(LeaseSignForm, {
			props: { providers: [{ id: 'mock', level: 'simple' }] }
		});
		expect(body).toContain('prostý elektronický podpis');
		expect(body).toContain('type="hidden" name="provider" value="mock"');
		expect(body).not.toContain('type="radio"');
		expect(body).not.toContain('mock<');
		expect(body).toContain('name="confirm"');
	});

	it('lets the user choose among several providers, first preselected', () => {
		const { body } = render(LeaseSignForm, {
			props: {
				providers: [
					{ id: 'bankid_sign', level: 'qualified' },
					{ id: 'mock', level: 'simple' }
				]
			}
		});
		expect(body.match(/type="radio"/g)).toHaveLength(2);
		expect(body).toContain('kvalifikovaný podpis (Bank iD)');
		expect(body).toMatch(/value="bankid_sign"[^>]*checked/);
		expect(body).toContain('name="confirm"');
	});

	it('says signing is unavailable without providers', () => {
		const { body } = render(LeaseSignForm, { props: { providers: [] } });
		expect(body).toContain('lease-sign-unavailable');
		expect(body).not.toContain('action="?/sign"');
	});
});

describe('LandlordNoticeForm', () => {
	it('shows the statutory hint and every reason for an indefinite-term lease', () => {
		const { body } = render(LandlordNoticeForm, { props: { endsOn: null } });
		expect(body).toContain('nejméně 3 měsíce');
		expect(body).toContain('písemnou formu');
		expect(body).toContain('value="flat_needed_for_landlord_or_relative"');
		expect(body).toContain('name="explanation"');
		expect(body).toContain('name="delivered_on"');
	});

	it('hides the own-use reason for a fixed-term lease and shows errors', () => {
		const { body } = render(LandlordNoticeForm, {
			props: { endsOn: '2027-01-31', error: 'Chyba výpovědi' }
		});
		expect(body).not.toContain('value="flat_needed_for_landlord_or_relative"');
		expect(body).toContain('Chyba výpovědi');
	});
});

describe('LoadMore', () => {
	it('renders plain links and nothing on a single page', () => {
		expect(render(LoadMore, { props: { next: null } }).body).not.toContain('<nav');
		const { body } = render(LoadMore, { props: { next: '/x?before=1', first: '/x' } });
		expect(body).toContain('href="/x?before=1"');
		expect(body).toContain('Načíst další');
		expect(body).toContain('href="/x"');
	});
});

const party = (extra: Record<string, unknown>) => ({
	id: '0192f0c0-0000-7000-8000-000000000001',
	role: 'tenant' as const,
	name: 'Jana Nová',
	share_bps: 10000,
	position: 1,
	me: false,
	has_account: false,
	...extra
});

const importedDetail = (parties: ReturnType<typeof party>[], extra = {}) => ({
	lease: {
		id: '0192f0c0-0000-7000-8000-0000000000aa',
		org_id: '0192f0c0-0000-7000-8000-0000000000bb',
		code: 100042,
		state: 'active' as const,
		origin: 'imported' as const,
		cutover_on: '2026-11-01',
		variable_symbol: '123456',
		template: 'byt_doba_neurcita' as const,
		property_address: 'Dejvická 12, Praha 6',
		starts_on: '2024-03-01',
		rent_amount: 1_850_000,
		currency: 'CZK',
		created_at: '2026-10-20T10:00:00Z'
	},
	parties: [
		party({
			id: '0192f0c0-0000-7000-8000-0000000000cc',
			role: 'landlord',
			name: 'Lucie',
			has_account: true
		}),
		...parties
	],
	documents: [],
	landlord_view: true,
	payee_iban: 'CZ6508000000192000145399',
	payee_name: 'Lucie',
	due_day: 15,
	notice_months: 3,
	deposit_amount: 3_700_000,
	services_amount: 0,
	deposit_held: true,
	clauses: [],
	total_debt: 0,
	sign_providers: [],
	...extra
});

describe('LeaseImportForm', () => {
	it('defaults the cutover, holds the deposit and asks for opening balances', () => {
		const { body } = render(LeaseImportForm, { props: { submit: 'Přidat nájem' } });
		expect(body).toContain('name="cutover_on"');
		expect(body).toMatch(/name="deposit_held"[^>]*checked/);
		expect(body).toContain('name="variable_symbol"');
		expect(body).toContain('Počáteční zůstatek (Kč)');
		expect(body).toContain('trvalém příkazu');
		expect(body).not.toContain('name="clauses"');
	});

	it('shows an api error on its field', () => {
		const { body } = render(LeaseImportForm, {
			props: {
				submit: 'Přidat nájem',
				error: { field: 'cutover_on', message: 'Sledování plateb může začít nejvýše 31 dní zpět' }
			}
		});
		expect(body).toContain('data-testid="error-cutover_on"');
		expect(body).toMatch(/name="cutover_on"[^>]*aria-invalid="true"/);
		expect(body).not.toContain('data-testid="error-variable_symbol"');
	});
});

describe('ImportedLeasePanel', () => {
	it('offers an invitation to tenants without an account and explains the silence', () => {
		const { body } = render(ImportedLeasePanel, {
			props: { detail: importedDetail([party({ email: 'jana@example.com' })]), locale: 'cs' }
		});
		expect(body).toContain('Pozvat do nájemního portálu');
		expect(body).toContain('value="jana@example.com"');
		expect(body).toContain('žádný e-mail');
		expect(body).toContain('Sken papírové smlouvy zatím chybí');
		expect(body).not.toContain('Lucie</strong>');
	});

	it('shows the invitation date with a re-send, and nothing for linked tenants', () => {
		const { body } = render(ImportedLeasePanel, {
			props: {
				detail: importedDetail(
					[
						party({ invited_at: '2026-10-18T09:00:00Z' }),
						party({ id: '0192f0c0-0000-7000-8000-000000000002', name: 'Petr', has_account: true })
					],
					{ contract_scan_url: 'https://s3.local/scan.pdf' }
				),
				locale: 'cs'
			}
		});
		expect(body).toMatch(/Pozváno 18\.\s10\.\s2026/);
		expect(body).toContain('Poslat pozvánku znovu');
		expect(body.match(/action="\?\/invite"/g)).toHaveLength(1);
		expect(body).toContain('používá nájemní portál');
		expect(body).toContain('href="https://s3.local/scan.pdf"');
	});
});

describe('LeaseSummary', () => {
	it('marks an imported lease with its cutover, symbol and held deposit', () => {
		const { body } = render(LeaseSummary, {
			props: { detail: importedDetail([party({})]), chain: null, locale: 'cs' }
		});
		expect(body).toContain('Převzatá smlouva');
		expect(body).toContain('data-testid="lease-cutover"');
		expect(body).toContain('123456');
		expect(body).toContain('kauci už drží pronajímatel');
		expect(body).toContain('podepsáno mimo platformu');
		expect(body).not.toContain('nepodepsáno');
	});
});
