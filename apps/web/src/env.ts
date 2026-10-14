import { defineEnvVars } from '@sveltejs/kit/env';

/** Runtime environment of the web app (SvelteKit 3 env schema). */
export const variables = defineEnvVars({
	API_URL: {
		description: 'Base URL of the Go api, reachable from the SvelteKit server.',
		schema: (v) => v || 'http://localhost:8080'
	},
	MAP_STYLE: {
		public: true,
		description: 'MapLibre style URL for the search map (OpenFreeMap by default, no API key).',
		schema: (v) => v || 'https://tiles.openfreemap.org/styles/positron'
	}
});
