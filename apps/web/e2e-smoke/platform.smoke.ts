import { API_URL, BASE_URL, SITE_URL, expect, expectSecurityHeaders, test } from './env';

type Health = { status: string; checks: Record<string, { status: string }> };

test('/healthz is ok including the worker heartbeat', async ({ request }) => {
	const res = await request.get(`${API_URL}/healthz`);
	const body = (await res.json()) as Health;
	expect(body.status, JSON.stringify(body.checks)).toBe('ok');
	expect(res.status()).toBe(200);
	expect(body.checks.worker?.status, 'worker heartbeat').toBe('ok');
	for (const [name, c] of Object.entries(body.checks)) {
		expect(c.status, `check ${name}`).toBe('ok');
	}
});

test('/v1/version reports a build', async ({ request }) => {
	const res = await request.get(`${API_URL}/v1/version`);
	expect(res.status()).toBe(200);
	const v = (await res.json()) as { version: string; schema_version: number };
	expect(v.version).toBeTruthy();
	expect(v.schema_version).toBeGreaterThan(0);
});

test('internal endpoints are not exposed', async ({ request }) => {
	for (const base of [API_URL, BASE_URL]) {
		const res = await request.get(`${base}/metrics`, { maxRedirects: 0 });
		expect(res.status(), `${base}/metrics`).toBeGreaterThanOrEqual(400);
	}
});

test('security headers on web, api and site', async ({ request }) => {
	expectSecurityHeaders(await request.get(`${BASE_URL}/`), { csp: true });
	expectSecurityHeaders(await request.get(`${API_URL}/healthz`), { csp: true });
	// The static Astro site gets the Caddy baseline (HSTS, nosniff); CSP is optional there.
	expectSecurityHeaders(await request.get(`${SITE_URL}/`), { csp: false });
});

test('plain http redirects to https', async ({ request }) => {
	test.skip(!BASE_URL.startsWith('https://'), 'target is not https');
	const res = await request.get(BASE_URL.replace(/^https:/, 'http:') + '/', { maxRedirects: 0 });
	expect([301, 308]).toContain(res.status());
	expect(res.headers()['location']).toMatch(/^https:\/\//);
});
