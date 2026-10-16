import { error, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { RequestHandler } from './$types';

/**
 * Applicant's income proof: the API audits every download and returns a short-lived
 * link, so the link is fetched on click and never rendered into the page. Problems
 * (closed application, missing proof, no permission) become a translated error page.
 */
export const GET: RequestHandler = async ({ params, locals }) => {
	const {
		data,
		error: problem,
		response
	} = await locals.api.GET(
		'/v1/orgs/{orgId}/applications/{applicationId}/people/{userId}/income-proof',
		{
			params: {
				path: { orgId: params.orgId, applicationId: params.applicationId, userId: params.userId }
			}
		}
	);
	if (!data?.url) {
		const status = response.status >= 400 ? response.status : 502;
		error(status, errorMessage(problem ?? { status, title: '' }));
	}
	redirect(303, data.url);
};
