import { describe, expect, it } from 'vitest';
import { readConsent, writeConsent } from './consent';

describe('cookie consent', () => {
	it('is undecided without a cookie or with an old version', () => {
		expect(readConsent(undefined)).toEqual({ decided: false, categories: [] });
		expect(readConsent('v0')).toEqual({ decided: false, categories: [] });
	});

	it('records a dismissal of the notice', () => {
		expect(writeConsent([])).toBe('v1');
		expect(readConsent('v1')).toEqual({ decided: true, categories: [] });
	});

	it('ignores categories that are not in use (analytics stays off)', () => {
		expect(writeConsent(['analytics', 'ads'])).toBe('v1');
		expect(readConsent('v1.analytics.ads').categories).toEqual([]);
	});
});
