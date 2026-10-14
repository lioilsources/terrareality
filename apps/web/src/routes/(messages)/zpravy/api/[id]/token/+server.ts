import { error, json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/** Subscription token for one conversation channel. */
export const POST: RequestHandler = async ({ locals, params }) => {
	const { data, response } = await locals.api.POST(
		'/v1/conversations/{conversationId}/realtime-token',
		{
			params: { path: { conversationId: params.id } }
		}
	);
	if (!data) error(response.status === 404 ? 404 : 502);
	return json({ token: data.token });
};
