import { error, json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/** Centrifugo connection token for the signed-in user. */
export const POST: RequestHandler = async ({ locals }) => {
	const { data } = await locals.api.POST('/v1/realtime/token');
	if (!data) error(502);
	return json({ url: data.url, token: data.token });
};
