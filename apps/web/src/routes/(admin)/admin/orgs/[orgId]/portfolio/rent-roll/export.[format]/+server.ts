import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

const types = {
	csv: 'text/csv; charset=utf-8',
	xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
} as const;

/** Rent roll export (proxied: the session cookie stays here); keeps the page filters. */
export const GET: RequestHandler = async ({ params, locals, url }) => {
	const format = params.format as keyof typeof types;
	if (!(format in types)) error(404);
	const { data, response } = await locals.api.GET('/v1/orgs/{orgId}/portfolio/rent-roll', {
		params: {
			path: { orgId: params.orgId },
			query: {
				format,
				municipality: url.searchParams.get('municipality') || undefined,
				region: url.searchParams.get('region') || undefined,
				group_id: url.searchParams.get('group_id') || undefined
			}
		},
		parseAs: format === 'csv' ? 'text' : 'arrayBuffer'
	});
	if (!response.ok || data === undefined) error(response.status);
	return new Response(data as unknown as BodyInit, {
		headers: {
			'Content-Type': types[format],
			'Content-Disposition': `attachment; filename="rent-roll-${new Date().toISOString().slice(0, 10)}.${format}"`
		}
	});
};
