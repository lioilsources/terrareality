import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/** Invoice PDF (proxied: the session cookie stays here). */
export const GET: RequestHandler = async ({ params, locals }) => {
	const { data, response } = await locals.api.GET('/v1/orgs/{orgId}/invoices/{invoiceId}/pdf', {
		params: { path: { orgId: params.orgId, invoiceId: params.invoiceId } },
		parseAs: 'arrayBuffer'
	});
	if (!response.ok || data === undefined) error(response.status === 200 ? 502 : response.status);
	const name = response.headers.get('Content-Disposition');
	return new Response(data as unknown as BodyInit, {
		headers: {
			'Content-Type': 'application/pdf',
			'Content-Disposition': name ?? `attachment; filename="invoice-${params.invoiceId}.pdf"`
		}
	});
};
