import { expect, test as base, type APIResponse, type Page } from '@playwright/test';

function env(name: 'BASE_URL' | 'API_URL' | 'SITE_URL'): string {
	const v = process.env[name];
	if (!v) throw new Error(`smoke: ${name} is required`);
	return v.replace(/\/+$/, '');
}

export const BASE_URL = env('BASE_URL');
export const API_URL = env('API_URL');
export const SITE_URL = env('SITE_URL');

/** Console messages matching SMOKE_IGNORE_CONSOLE (a regex) are tolerated, e.g. a known third-party warning. */
const ignore = process.env.SMOKE_IGNORE_CONSOLE
	? new RegExp(process.env.SMOKE_IGNORE_CONSOLE)
	: null;

/**
 * Page fixture that fails the test on console errors and uncaught exceptions,
 * so every smoke page also checks "no console errors".
 */
export const test = base.extend<{ consoleErrors: string[] }>({
	consoleErrors: async ({ page }, use) => {
		const errors: string[] = [];
		page.on('console', (msg) => {
			if (msg.type() === 'error' && !(ignore && ignore.test(msg.text()))) {
				errors.push(`console: ${msg.text()}`);
			}
		});
		page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));
		await use(errors);
		expect(errors, 'no console errors or uncaught exceptions').toEqual([]);
	}
});

export { expect };

/** Opens a URL and asserts a successful document response. */
export async function open(page: Page, url: string): Promise<void> {
	const res = await page.goto(url);
	expect(res, `response for ${url}`).not.toBeNull();
	expect(res!.status(), `status of ${url}`).toBeLessThan(400);
}

/** Security headers every public origin must send (Caddy baseline + app CSP). */
export function expectSecurityHeaders(res: APIResponse, opts: { csp: boolean }): void {
	const h = res.headers();
	const url = res.url();
	expect(h['x-content-type-options'], `nosniff on ${url}`).toBe('nosniff');
	if (opts.csp) {
		expect(h['content-security-policy'], `CSP on ${url}`).toBeTruthy();
	}
	if (url.startsWith('https://')) {
		expect(h['strict-transport-security'], `HSTS on ${url}`).toMatch(/max-age=\d{6,}/);
	}
	expect(h['x-powered-by'], `no X-Powered-By on ${url}`).toBeUndefined();
}
