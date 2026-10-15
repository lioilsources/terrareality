import { describe, expect, it, vi } from 'vitest';
import { buildEvent, createReporter, parseDsn, parseStack, scrub } from './sentry.js';

describe('sentry reporter', () => {
	it('parses a DSN into the envelope endpoint', () => {
		const d = parseDsn('https://abc123@o42.ingest.de.sentry.io/4507');
		expect(d?.envelopeUrl).toBe(
			'https://o42.ingest.de.sentry.io/api/4507/envelope/?sentry_key=abc123&sentry_version=7&sentry_client=terra-minimal%2F1.0'
		);
		expect(parseDsn('')).toBeNull();
		expect(parseDsn('https://o42.ingest.sentry.io/4507')).toBeNull();
	});

	it('scrubs e-mails, tokens, IBANs, phones and query strings', () => {
		const s = scrub(
			'jana.novak@example.cz token=abc.def CZ65 0800 0000 1920 0014 5399 +420 601 123 456 https://x.cz/reset?t=secret'
		);
		expect(s).not.toContain('jana.novak');
		expect(s).not.toContain('abc.def');
		expect(s).not.toContain('1920');
		expect(s).not.toContain('601 123');
		expect(s).not.toContain('t=secret');
		expect(s).toContain('[email]');
	});

	it('parses V8 stacks outermost first', () => {
		const frames = parseStack(
			'Error: x\n    at inner (/app/a.js:1:2)\n    at /app/node_modules/b.js:3:4'
		);
		expect(frames.map((f) => f.lineno)).toEqual([3, 1]);
		expect(frames[0].in_app).toBe(false);
	});

	it('builds an event with route but no URL or user', () => {
		const ev = buildEvent(
			new Error('fail for a@b.cz'),
			{ route: '/(admin)/admin', status: 500 },
			{
				dsn: 'x',
				platform: 'node',
				release: '1.0.0'
			}
		);
		expect(ev.transaction).toBe('/(admin)/admin');
		expect(ev.exception.values[0].value).toBe('fail for [email]');
		expect(ev).not.toHaveProperty('user');
		expect(ev).not.toHaveProperty('request');
	});

	it('is disabled without a DSN and caps events', async () => {
		expect(createReporter({ dsn: '', platform: 'node' })).toBeNull();
		const f = vi.fn(async () => new Response(null));
		const r = createReporter({ dsn: 'https://k@h.example/1', platform: 'node', maxEvents: 2 }, f);
		for (let i = 0; i < 5; i++) await r!.capture(new Error('x'));
		expect(f).toHaveBeenCalledTimes(2);
	});
});
