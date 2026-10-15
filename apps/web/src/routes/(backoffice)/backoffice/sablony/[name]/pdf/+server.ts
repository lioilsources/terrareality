import { error, redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/** Sample PDF of a contract template, proxied from the api (staff session stays server-side). */
export const GET: RequestHandler = async ({ params, locals, url }) => {
	const { data, response } = await locals.api.GET('/v1/backoffice/templates/{name}/preview', {
		params: { path: { name: params.name } },
		parseAs: 'arrayBuffer'
	});
	if (response.status === 503) {
		// Typst is not installed on the api host: back to the list with an explanation.
		const list = url.pathname.replace(/\/[^/]+\/pdf\/?$/, '');
		redirect(303, `${list}?nahled=nedostupny`);
	}
	if (!response.ok || !data) error(response.status === 404 ? 404 : 502);
	return new Response(data as ArrayBuffer, {
		headers: {
			'Content-Type': 'application/pdf',
			'Content-Disposition': `inline; filename="${params.name}.pdf"`,
			'Cache-Control': 'private, no-store'
		}
	});
};
