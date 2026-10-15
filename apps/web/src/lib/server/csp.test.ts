import { describe, expect, it } from 'vitest';
import { cspExtras, extendCsp, originOf, origins } from './csp.js';

describe('csp', () => {
	it('extracts origins', () => {
		expect(originOf('https://tiles.openfreemap.org/styles/positron')).toBe(
			'https://tiles.openfreemap.org'
		);
		expect(originOf('ws://localhost:8000/connection/websocket')).toBe('ws://localhost:8000');
		expect(originOf('https://abc@o1.ingest.de.sentry.io/42')).toBe(
			'https://o1.ingest.de.sentry.io'
		);
		expect(originOf('')).toBeNull();
		expect(originOf('not a url')).toBeNull();
		expect(origins('http://a:1, http://b:2  nope')).toEqual(['http://a:1', 'http://b:2']);
	});

	it('extends directives without duplicates', () => {
		const h = "default-src 'self'; img-src 'self' data:; form-action 'self'; object-src 'none'";
		const out = extendCsp(h, {
			'img-src': ['http://localhost:8081', "'self'"],
			'connect-src': ['ws://localhost:8000'],
			'object-src': []
		});
		expect(out).toBe(
			"default-src 'self'; img-src 'self' data: http://localhost:8081; form-action 'self'; object-src 'none'; connect-src ws://localhost:8000"
		);
	});

	it('builds extras from env', () => {
		const x = cspExtras({
			apiPublicUrl: 'http://localhost:8080',
			mapStyle: 'https://tiles.openfreemap.org/styles/positron',
			mediaOrigins: 'http://localhost:8081',
			realtimeOrigin: 'ws://localhost:8000',
			sentryDsn: '',
			formActionOrigins: 'https://checkout.stripe.com'
		});
		expect(x['img-src']).toEqual(['http://localhost:8081', 'https://tiles.openfreemap.org']);
		expect(x['connect-src']).toEqual(['https://tiles.openfreemap.org', 'ws://localhost:8000']);
		expect(x['form-action']).toEqual([
			'http://localhost:8080',
			'https://checkout.stripe.com',
			'http://localhost:8081'
		]);
	});
});
