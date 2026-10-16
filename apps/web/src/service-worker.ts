/// <reference types="@sveltejs/kit" />
/// <reference no-default-lib="true"/>
/// <reference lib="esnext" />
/// <reference lib="webworker" />
import { PUSH_FALLBACK, safePushLink } from './lib/push-link.js';

// Shows Web Push notifications about new messages (payload from the api:
// {title, body, link}) and opens the conversation on click. Only same-origin
// links are opened; anything else falls back to the inbox.
const sw = self as unknown as ServiceWorkerGlobalScope;

sw.addEventListener('push', (event) => {
	let data: { title?: string; body?: string; link?: unknown } = {};
	try {
		data = event.data?.json() ?? {};
	} catch {
		// not JSON: generic notification
	}
	event.waitUntil(
		sw.registration.showNotification(data.title ?? 'TerraReality', {
			body: data.body,
			icon: '/favicon.svg',
			data: { link: safePushLink(data.link, sw.location.origin) }
		})
	);
});

sw.addEventListener('notificationclick', (event) => {
	event.notification.close();
	const link = safePushLink(event.notification.data?.link ?? PUSH_FALLBACK, sw.location.origin);
	event.waitUntil(sw.clients.openWindow(link));
});
