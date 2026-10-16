import { describe, expect, it } from 'vitest';
import { errorMessage, knownCodes } from './errors';
import { m } from '#lib/paraglide/messages.js';

const problem = (status: number, code?: string) => ({
	type: 'about:blank',
	title: 't',
	status,
	code
});

describe('errorMessage', () => {
	it('translates signing and leasing codes', () => {
		expect(errorMessage(problem(422, 'invalid_provider'))).toBe(m.err_invalid_provider());
		expect(errorMessage(problem(409, 'document_changed'))).toBe(m.err_document_changed());
		expect(errorMessage(problem(422, 'terms_outdated'))).toBe(m.err_terms_outdated());
	});

	it('translates notice and applicant codes', () => {
		expect(errorMessage(problem(422, 'notice_reason_not_applicable'))).toBe(
			m.err_notice_reason_not_applicable()
		);
		expect(errorMessage(problem(422, 'landlord_notice_reason_required'))).toBe(
			m.err_landlord_notice_reason_required()
		);
		expect(errorMessage(problem(422, 'invalid_delivered_on'))).toBe(m.err_invalid_delivered_on());
		expect(errorMessage(problem(403, 'notice_not_allowed'))).toBe(m.err_notice_not_allowed());
		expect(errorMessage(problem(422, 'invalid_role'))).toBe(m.err_invalid_role());
		expect(errorMessage(problem(404, 'income_proof_not_found'))).toBe(
			m.err_income_proof_not_found()
		);
		expect(knownCodes()).not.toContain('slot_has_bookings');
	});

	it('falls back by status, then to the generic message', () => {
		expect(errorMessage(problem(503, 'something_new'))).toBe(m.err_unavailable());
		expect(errorMessage(problem(404))).toBe(m.err_not_found());
		expect(errorMessage(problem(422, 'something_new'))).toBe(m.err_generic());
		expect(errorMessage(new Error('x'))).toBe(m.err_generic());
	});

	it('has a non-empty message for every mapped code', () => {
		for (const code of knownCodes()) {
			expect(errorMessage(problem(400, code)), code).not.toBe('');
		}
	});
});

describe('Czech plurals', () => {
	it('uses one / few / other forms', () => {
		const cs = { locale: 'cs' as const };
		expect(m.search_results({ count: 1 }, cs)).toBe('1 nabídka');
		expect(m.search_results({ count: 3 }, cs)).toBe('3 nabídky');
		expect(m.search_results({ count: 5 }, cs)).toBe('5 nabídek');
		expect(m.search_results({ count: 0 }, cs)).toBe('0 nabídek');
		expect(m.billing_days({ days: 2 }, cs)).toBe('2 dny');
		expect(m.search_results({ count: 1 }, { locale: 'en' })).toBe('1 listing');
	});
});
