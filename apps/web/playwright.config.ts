import { defineConfig } from '@playwright/test';

export default defineConfig({
	webServer: {
		command: 'npm run build && npm run preview',
		port: 4173,
		reuseExistingServer: !process.env.CI,
		timeout: 180_000,
		// vite preview runs with NODE_ENV=production; the e2e stack is local.
		env: { ALLOW_LOCALHOST_DEFAULTS: '1' }
	},
	testMatch: '**/*.e2e.{ts,js}',
	testDir: 'e2e'
});
