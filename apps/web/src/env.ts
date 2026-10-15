import { defineEnvVars } from '@sveltejs/kit/env';
import { withLocalDefault } from './lib/env-defaults.js';

/**
 * Runtime environment of the web app (SvelteKit 3 env schema). Service URLs and
 * CSP origins fall back to localhost defaults; with
 * NODE_ENV=production hooks.server.ts refuses to start and names the missing
 * variables (lib/env-defaults.ts).
 */
export const variables = defineEnvVars({
	API_URL: {
		description:
			'Base URL of the Go api, reachable from the SvelteKit server. Required in production.',
		schema: (v) => withLocalDefault('API_URL', v)
	},
	MAP_STYLE: {
		public: true,
		description: 'MapLibre style URL for the search map (OpenFreeMap by default, no API key).',
		schema: (v) => v || 'https://tiles.openfreemap.org/styles/positron'
	},
	SENTRY_DSN: {
		description: 'Sentry DSN for server-side errors. Empty disables reporting (dev default).',
		schema: (v) => v ?? ''
	},
	PUBLIC_SENTRY_DSN: {
		public: true,
		description: 'Sentry DSN for browser errors. Empty disables reporting (dev default).',
		schema: (v) => v ?? ''
	},
	PUBLIC_SENTRY_ENVIRONMENT: {
		public: true,
		description: 'Sentry environment tag (prod, staging).',
		schema: (v) => v || 'dev'
	},
	PUBLIC_SENTRY_RELEASE: {
		public: true,
		description: 'Sentry release; defaults to the SvelteKit build version. CI sets the git SHA.',
		schema: (v) => v ?? ''
	},
	API_PUBLIC_URL: {
		description:
			'Browser-facing URL of the api (mock checkout pages); allowed in CSP form-action. Required in production.',
		schema: (v) => withLocalDefault('API_PUBLIC_URL', v)
	},
	CSP_MEDIA_ORIGINS: {
		description:
			'Space-separated browser origins of imgproxy and S3/MinIO (CSP img-src, form-action). Required in production.',
		schema: (v) => withLocalDefault('CSP_MEDIA_ORIGINS', v)
	},
	CSP_REALTIME_ORIGIN: {
		description:
			'Centrifugo websocket origin (CSP connect-src), e.g. wss://app.terrareality.cz. Required in production.',
		schema: (v) => withLocalDefault('CSP_REALTIME_ORIGIN', v)
	},
	CSP_MAP_ORIGINS: {
		description:
			'Extra map tile/glyph origins beyond the MAP_STYLE origin (CSP connect-src, img-src).',
		schema: (v) => v ?? ''
	},
	CSP_FORM_ACTION_ORIGINS: {
		description:
			'Off-site redirect targets of plain form posts (Stripe Checkout, Revolut, GoCardless bank consent, BankID) for CSP form-action.',
		schema: (v) =>
			v ||
			'https://checkout.stripe.com https://checkout.revolut.com https://ob.gocardless.com https://oidc.bankid.cz'
	},
	ALLOW_LOCALHOST_DEFAULTS: {
		description:
			'Set to 1 to allow the localhost defaults above in a NODE_ENV=production process (vite preview for e2e). Never in deployments.',
		schema: (v) => v ?? ''
	}
});
