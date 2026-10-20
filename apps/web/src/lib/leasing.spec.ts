import { describe, expect, it } from 'vitest';
import { m } from '#lib/paraglide/messages.js';
import {
	cutoverRange,
	defaultCutover,
	deliveredOnRange,
	importErrorField,
	invitable,
	kindLabel,
	landlordNoticeFromForm,
	landlordNoticeReasons,
	leaseImportFromForm,
	normalizeVariableSymbol,
	noticeReasonsFor,
	signProviderFromForm
} from './leasing';

const form = (values: Record<string, string>) => {
	const f = new FormData();
	for (const [k, v] of Object.entries(values)) f.set(k, v);
	return f;
};

describe('sign provider', () => {
	it('accepts only known provider ids', () => {
		expect(signProviderFromForm(form({ provider: 'mock' }))).toBe('mock');
		expect(signProviderFromForm(form({ provider: 'bankid_sign' }))).toBe('bankid_sign');
		expect(signProviderFromForm(form({ provider: 'evil' }))).toBeNull();
		expect(signProviderFromForm(form({}))).toBeNull();
	});
});

describe('landlord notice', () => {
	const ok = { reason: 'gross_breach_tenant', delivered_on: '2026-10-16', confirm: 'on' };

	it('builds the api body from a valid form', () => {
		expect(landlordNoticeFromForm(form({ ...ok, explanation: '  Neplatí 4 měsíce. ' }))).toEqual({
			notice: {
				reason: 'gross_breach_tenant',
				delivered_on: '2026-10-16',
				explanation: 'Neplatí 4 měsíce.'
			}
		});
		expect(landlordNoticeFromForm(form(ok))).toEqual({
			notice: { reason: 'gross_breach_tenant', delivered_on: '2026-10-16', explanation: undefined }
		});
	});

	it('requires a statutory reason, a date and the written-form confirmation', () => {
		expect(landlordNoticeFromForm(form({ ...ok, reason: '' }))).toEqual({
			error: m.err_landlord_notice_reason_required()
		});
		expect(landlordNoticeFromForm(form({ ...ok, reason: 'because' }))).toEqual({
			error: m.err_landlord_notice_reason_required()
		});
		expect(landlordNoticeFromForm(form({ ...ok, delivered_on: '' }))).toEqual({
			error: m.lease_notice_delivered_required()
		});
		expect(landlordNoticeFromForm(form({ ...ok, confirm: '' }))).toEqual({
			error: m.lease_notice_landlord_confirm_required()
		});
	});

	it('requires an explanation for another serious reason', () => {
		const other = { ...ok, reason: 'other_serious_reason' };
		expect(landlordNoticeFromForm(form({ ...other, explanation: '   ' }))).toEqual({
			error: m.lease_notice_explanation_required()
		});
		expect(landlordNoticeFromForm(form({ ...other, explanation: 'Ruší sousedy v noci.' }))).toEqual(
			{
				notice: {
					reason: 'other_serious_reason',
					delivered_on: '2026-10-16',
					explanation: 'Ruší sousedy v noci.'
				}
			}
		);
	});

	it('offers the own-use reason only for indefinite-term leases', () => {
		expect(noticeReasonsFor(undefined)).toHaveLength(landlordNoticeReasons.length);
		const fixed = noticeReasonsFor('2027-10-15').map(([r]) => r);
		expect(fixed).not.toContain('flat_needed_for_landlord_or_relative');
		expect(fixed).toContain('other_serious_reason');
	});

	it('labels every reason with its paragraph of the Civil Code', () => {
		for (const [, label] of landlordNoticeReasons) expect(label()).toMatch(/§ 2288/);
	});

	it('limits the delivery date to 30 days back and 7 days ahead', () => {
		expect(deliveredOnRange(new Date(2026, 9, 16, 12))).toEqual({
			min: '2026-09-16',
			max: '2026-10-23'
		});
	});
});

describe('existing lease import', () => {
	const tenant = (extra: Record<string, unknown> = {}) => ({
		name: ' Jana Nová ',
		email: '',
		role: 'tenant',
		share: '',
		opening: '',
		...extra
	});
	const ok = (parties: unknown[] = [tenant()], extra: Record<string, string> = {}) =>
		form({
			template: 'byt_doba_neurcita',
			starts_on: '2024-03-01',
			rent: '18 500',
			services: '3500,50',
			deposit: '37000',
			deposit_held: 'on',
			due_day: '10',
			notice_months: '',
			payee_iban: ' CZ65 0800 0000 1920 0014 5399 ',
			payee_name: 'Lucie Pronajímatelka',
			property_address: 'Dejvická 12, Praha 6',
			ruian_id: '21717858',
			unit_label: '2+kk, 3. NP',
			cutover_on: '2026-11-01',
			variable_symbol: ' 00123 456 ',
			parties: JSON.stringify(parties),
			...extra
		});

	it('maps the form to the api body in minor units', () => {
		expect(leaseImportFromForm(ok())).toEqual({
			body: {
				template: 'byt_doba_neurcita',
				starts_on: '2024-03-01',
				ends_on: undefined,
				rent_amount: 1_850_000,
				services_amount: 350_050,
				deposit_amount: 3_700_000,
				deposit_held: true,
				due_day: 10,
				notice_months: undefined,
				payee_iban: 'CZ65 0800 0000 1920 0014 5399',
				payee_name: 'Lucie Pronajímatelka',
				property_address: 'Dejvická 12, Praha 6',
				ruian_id: 21717858,
				unit_label: '2+kk, 3. NP',
				cutover_on: '2026-11-01',
				variable_symbol: '123456',
				parties: [
					{
						name: 'Jana Nová',
						email: undefined,
						role: 'tenant',
						share_bps: 0,
						opening_balance: undefined
					}
				]
			}
		});
	});

	it('converts shares and opening balances per tenant; a guarantor has neither', () => {
		const r = leaseImportFromForm(
			ok([
				tenant({ share: 60, opening: '12 500,5', email: ' jana@example.com ' }),
				tenant({ name: 'Petr', role: 'co_tenant', share: '40', opening: 0 }),
				tenant({ name: 'Otec', role: 'guarantor', share: 10, opening: 500 })
			])
		);
		expect('body' in r && r.body.parties).toEqual([
			{
				name: 'Jana Nová',
				email: 'jana@example.com',
				role: 'tenant',
				share_bps: 6000,
				opening_balance: 1_250_050
			},
			{
				name: 'Petr',
				email: undefined,
				role: 'co_tenant',
				share_bps: 4000,
				opening_balance: undefined
			},
			{
				name: 'Otec',
				email: undefined,
				role: 'guarantor',
				share_bps: 0,
				opening_balance: undefined
			}
		]);
	});

	it('leaves optional fields out and keeps an unpicked address as free text', () => {
		const r = leaseImportFromForm(
			ok(undefined, { ruian_id: '', variable_symbol: '', cutover_on: '', deposit_held: '' })
		);
		if (!('body' in r)) throw new Error('expected a body');
		expect(r.body.ruian_id).toBeUndefined();
		expect(r.body.variable_symbol).toBeUndefined();
		expect(r.body.cutover_on).toBeUndefined();
		expect(r.body.deposit_held).toBe(false);
		expect(r.body.property_address).toBe('Dejvická 12, Praha 6');
	});

	it('reports what the contract would reject on its field', () => {
		expect(leaseImportFromForm(ok(undefined, { variable_symbol: '12a' }))).toEqual({
			error: m.err_invalid_variable_symbol(),
			field: 'variable_symbol'
		});
		expect(leaseImportFromForm(ok([tenant({ email: 'not-an-email' })]))).toEqual({
			error: m.err_invalid_email(),
			field: 'parties'
		});
		expect(leaseImportFromForm(ok([tenant({ opening: '-5' })]))).toEqual({
			error: m.err_invalid_opening_balance(),
			field: 'parties'
		});
	});

	it('normalizes the variable symbol like banks do', () => {
		expect(normalizeVariableSymbol('0012 34')).toBe('1234');
		expect(normalizeVariableSymbol('1234567890')).toBe('1234567890');
		expect(normalizeVariableSymbol('12345678901')).toBeNull();
		expect(normalizeVariableSymbol('000')).toBeNull();
		expect(normalizeVariableSymbol('12-34')).toBeNull();
	});

	it('defaults the cutover to the first day of next month, or a later start', () => {
		expect(defaultCutover(new Date(2026, 9, 20, 12))).toBe('2026-11-01');
		expect(defaultCutover(new Date(2026, 11, 31, 12))).toBe('2027-01-01');
		expect(defaultCutover(new Date(2026, 9, 20, 12), '2024-03-01')).toBe('2026-11-01');
		expect(defaultCutover(new Date(2026, 9, 20, 12), '2027-02-15')).toBe('2027-02-15');
		expect(defaultCutover(new Date(2026, 9, 20, 12), 'garbage')).toBe('2026-11-01');
	});

	it('limits the cutover to 31 days back and 12 months ahead', () => {
		expect(cutoverRange(new Date(2026, 9, 20, 12))).toEqual({
			min: '2026-09-19',
			max: '2027-10-20'
		});
	});

	it('puts api errors on their fields', () => {
		expect(importErrorField('cutover_too_old')).toBe('cutover_on');
		expect(importErrorField('variable_symbol_taken')).toBe('variable_symbol');
		expect(importErrorField('opening_balance_guarantor')).toBe('parties');
		expect(importErrorField('invalid_iban')).toBe('payee_iban');
		expect(importErrorField('address_required')).toBe('property_address');
		expect(importErrorField('lease_ended')).toBe('ends_on');
		expect(importErrorField('something_new')).toBeNull();
		expect(importErrorField(undefined)).toBeNull();
	});

	it('labels the opening balance and invites only while the lease runs', () => {
		expect(kindLabel.opening_balance()).toBe(m.kind_opening_balance());
		expect(invitable('active')).toBe(true);
		expect(invitable('signed')).toBe(true);
		expect(invitable('terminated')).toBe(false);
	});
});
