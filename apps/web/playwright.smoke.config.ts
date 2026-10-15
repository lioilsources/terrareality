import { defineConfig } from '@playwright/test';

/**
 * Production smoke test (M8): read-only checks against an already deployed stack.
 * No webServer, no seeding, no logins, no writes, no AI calls — safe to run against prod.
 *
 *   make smoke BASE_URL=https://app.terrareality.cz API_URL=https://api.terrareality.cz \
 *              SITE_URL=https://terrareality.cz
 */
const required = ['BASE_URL', 'API_URL', 'SITE_URL'] as const;
const missing = required.filter((k) => !process.env[k]);
if (missing.length > 0) {
	throw new Error(`smoke: set ${missing.join(', ')} (no defaults: never guess the target)`);
}

export default defineConfig({
	testDir: 'e2e-smoke',
	testMatch: '**/*.smoke.ts',
	outputDir: 'test-results/smoke',
	fullyParallel: true,
	// Production is shared: keep the load tiny and retry once for transient network blips.
	workers: 2,
	retries: 1,
	timeout: 60_000,
	reporter: process.env.CI ? [['list'], ['github']] : 'list',
	use: {
		baseURL: process.env.BASE_URL,
		trace: 'retain-on-failure',
		screenshot: 'only-on-failure',
		extraHTTPHeaders: { 'User-Agent': 'terra-smoke/1 (+playwright)' }
	}
});
