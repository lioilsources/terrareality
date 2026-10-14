import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/** Stores this browser's push subscription for the signed-in user. */
export const POST: RequestHandler = async ({ locals, request }) => {
	const sub = (await request.json()) as {
		endpoint?: string;
		keys?: { p256dh?: string; auth?: string };
	};
	if (!sub.endpoint || !sub.keys?.p256dh || !sub.keys.auth) error(400);
	const ua = request.headers.get('user-agent') ?? '';
	const { response } = await locals.api.POST('/v1/me/push-devices', {
		body: { platform: 'webpush', token: sub.endpoint, keys: sub.keys, label: ua.slice(0, 120) }
	});
	return new Response(null, { status: response.ok ? 204 : response.status });
};
