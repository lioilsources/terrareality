import type { Health, Version } from '@terra/contracts';
import { api } from '#lib/server/api.js';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch }) => {
	const client = api(fetch);
	let health: Health | null = null;
	let version: Version | null = null;
	try {
		const [h, v] = await Promise.all([client.GET('/healthz'), client.GET('/v1/version')]);
		// /healthz answers 503 with the same body when degraded.
		health = h.data ?? (h.error as Health | undefined) ?? null;
		version = v.data ?? null;
	} catch {
		// API unreachable: the page renders the "unreachable" state.
	}
	return { health, version };
};
