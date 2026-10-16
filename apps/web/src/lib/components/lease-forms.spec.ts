import { describe, expect, it } from 'vitest';
import { render } from 'svelte/server';
import LeaseSignForm from './LeaseSignForm.svelte';
import LandlordNoticeForm from './LandlordNoticeForm.svelte';
import LoadMore from './LoadMore.svelte';

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
