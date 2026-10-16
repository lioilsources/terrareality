import { describe, expect, it } from 'vitest';
import { isDemo, markerLabel } from './demo';
import { errorMessage, knownCodes } from './errors';
import { m } from '#lib/paraglide/messages.js';

describe('demo listings', () => {
	it('detects only an explicit is_demo flag', () => {
		expect(isDemo({ is_demo: true })).toBe(true);
		expect(isDemo({ is_demo: false })).toBe(false);
		expect(isDemo({})).toBe(false);
		expect(isDemo(null)).toBe(false);
		expect(isDemo(undefined)).toBe(false);
	});

	it('prefixes the map marker of a demo listing', () => {
		expect(markerLabel('15 000 Kč', false)).toBe('15 000 Kč');
		expect(markerLabel('15 000 Kč', true)).toBe(`${m.listing_demo_short()} · 15 000 Kč`);
	});

	it('translates the demo_listing problem code', () => {
		expect(knownCodes()).toContain('demo_listing');
		expect(
			errorMessage({ type: 'about:blank', title: 't', status: 409, code: 'demo_listing' })
		).toBe(m.err_demo_listing());
	});
});
