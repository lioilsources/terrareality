import type { RequestHandler } from './$types';

/** Read receipt while the thread is open. */
export const POST: RequestHandler = async ({ locals, params }) => {
	const { response } = await locals.api.POST('/v1/conversations/{conversationId}/read', {
		params: { path: { conversationId: params.id } }
	});
	return new Response(null, { status: response.status });
};
