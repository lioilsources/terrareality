import { describe, expect, it } from 'vitest';
import { m } from '#lib/paraglide/messages.js';
import {
	deliveredOnRange,
	landlordNoticeFromForm,
	landlordNoticeReasons,
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
