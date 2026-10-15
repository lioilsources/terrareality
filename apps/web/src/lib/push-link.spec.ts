import { describe, expect, it } from 'vitest';
import { PUSH_FALLBACK, safePushLink } from './push-link';

const origin = 'https://app.terrareality.cz';

describe('safePushLink', () => {
	it('keeps same-origin links', () => {
		expect(safePushLink('/zpravy/123?x=1#m', origin)).toBe('/zpravy/123?x=1#m');
		expect(safePushLink('https://app.terrareality.cz/en/zpravy/1', origin)).toBe('/en/zpravy/1');
	});

	it('rejects other origins and schemes', () => {
		expect(safePushLink('https://evil.example/zpravy', origin)).toBe(PUSH_FALLBACK);
		expect(safePushLink('//evil.example/x', origin)).toBe(PUSH_FALLBACK);
		expect(safePushLink('javascript:alert(1)', origin)).toBe(PUSH_FALLBACK);
		expect(safePushLink(undefined, origin)).toBe(PUSH_FALLBACK);
		expect(safePushLink(42, origin)).toBe(PUSH_FALLBACK);
	});
});
