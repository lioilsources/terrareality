import { defineEnvVars } from '@sveltejs/kit/env';

/** Runtime environment of the web app (SvelteKit 3 env schema). */
export const variables = defineEnvVars({
	API_URL: {
		description: 'Base URL of the Go api, reachable from the SvelteKit server.',
		schema: (v) => v || 'http://localhost:8080'
	}
});
