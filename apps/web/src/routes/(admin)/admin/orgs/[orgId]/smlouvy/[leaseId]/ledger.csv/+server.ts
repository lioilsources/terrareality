import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/** CSV export of the lease ledger (proxied: the session cookie stays here). */
export const GET: RequestHandler = async ({ params, locals }) => {
	const { data, response } = await locals.api.GET('/v1/leases/{leaseId}/ledger', {
		params: { path: { leaseId: params.leaseId }, query: { format: 'csv' } },
		parseAs: 'text'
	});
	if (!response.ok || data === undefined) error(response.status);
	return new Response(data as unknown as string, {
		headers: {
			'Content-Type': 'text/csv; charset=utf-8',
			'Content-Disposition': `attachment; filename="ledger-${params.leaseId}.csv"`
		}
	});
};
