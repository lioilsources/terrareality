import { error, json } from '@sveltejs/kit';
import { MESSAGE_PAGE } from '#lib/messaging.js';
import type { RequestHandler } from './$types';

/** Older messages of a thread (oldest first) for "load older"; `before` is an ISO timestamp. */
export const GET: RequestHandler = async ({ locals, params, url }) => {
	const before = url.searchParams.get('before') ?? '';
	if (Number.isNaN(Date.parse(before))) error(400);
	const { data, response } = await locals.api.GET('/v1/conversations/{conversationId}/messages', {
		params: { path: { conversationId: params.id }, query: { before, limit: MESSAGE_PAGE } }
	});
	if (!data) error(response.status === 404 ? 404 : 502);
	return json([...data].reverse());
};
