import type { ApiClient, components } from '@terra/contracts';

export type RentRoll = components['schemas']['RentRoll'];
export type RentRollQuery = { municipality?: string; region?: string; group_id?: string };

/** Loads the rent roll as JSON (the endpoint also serves CSV and XLSX). */
export async function getRentRoll(api: ApiClient, orgId: string, query: RentRollQuery = {}) {
	const { data, error } = await api.GET('/v1/orgs/{orgId}/portfolio/rent-roll', {
		params: { path: { orgId }, query }
	});
	return { data: data as RentRoll | undefined, error };
}
