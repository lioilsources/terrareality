import { describe, expect, it } from 'vitest';
import { formatMoney, toMinor } from './catalog';
import { leaseFromForm } from './leasing';

const norm = (s: string) => s.replace(/\s/g, ' ');

describe('money', () => {
	it('formats with the currency from the api', () => {
		expect(norm(formatMoney(1250000, 'CZK', 'cs'))).toBe('12 500 Kč');
		expect(norm(formatMoney(125050, 'EUR', 'cs'))).toBe('1 250,50 €');
		expect(formatMoney(125050, 'EUR', 'en')).toBe('€1,250.50');
		expect(norm(formatMoney(99900, 'PLN', 'cs'))).toBe('999 zł');
		expect(norm(formatMoney(0, undefined, 'cs'))).toBe('0 Kč');
		expect(formatMoney(undefined, 'CZK', 'cs')).toBe('');
	});

	it('parses Czech-formatted amounts once, for listings and leases alike', () => {
		expect(toMinor('12 500,50')).toBe(1250050);
		expect(toMinor('12500.5')).toBe(1250050);
		expect(toMinor('')).toBeUndefined();
		expect(toMinor('abc')).toBeUndefined();
		const f = new FormData();
		f.set('template', 'byt_doba_urcita');
		f.set('starts_on', '2026-11-01');
		f.set('rent', '12 500,50');
		f.set('deposit', '25 000');
		const lease = leaseFromForm(f);
		expect(lease.rent_amount).toBe(1250050);
		expect(lease.deposit_amount).toBe(2500000);
		expect(lease.services_amount).toBeUndefined();
	});
});
