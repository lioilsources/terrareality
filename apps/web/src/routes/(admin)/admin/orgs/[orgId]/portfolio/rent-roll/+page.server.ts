import { errorMessage } from '#lib/errors.js';
import { getRentRoll } from '#lib/server/portfolio.js';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals, url }) => {
	const query = {
		municipality: url.searchParams.get('municipality') || undefined,
		region: url.searchParams.get('region') || undefined,
		group_id: url.searchParams.get('group_id') || undefined
	};
	const filtered = Boolean(query.municipality || query.region || query.group_id);
	const [roll, all] = await Promise.all([
		getRentRoll(locals.api, params.orgId, query),
		filtered ? getRentRoll(locals.api, params.orgId) : Promise.resolve(null)
	]);
	const filter = {
		municipality: query.municipality ?? '',
		region: query.region ?? '',
		group_id: query.group_id ?? ''
	};
	if (!roll.data)
		return {
			roll: null,
			error: errorMessage(roll.error),
			municipalities: [],
			regions: [],
			filter,
			query: ''
		};
	const source = all?.data?.rows ?? roll.data.rows;
	const uniq = (pairs: [string, string][]) =>
		[...new Map(pairs.filter(([p]) => p)).entries()]
			.map(([path, name]) => ({ path, name }))
			.sort((a, b) => a.name.localeCompare(b.name, 'cs'));
	return {
		roll: roll.data,
		municipalities: uniq(source.map((r) => [r.municipality_path, r.municipality])),
		regions: uniq(source.map((r) => [r.region_path ?? '', r.region])),
		filter,
		error: null,
		query: url.search
	};
};
