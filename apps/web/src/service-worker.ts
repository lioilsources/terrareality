/// <reference types="@sveltejs/kit" />
/// <reference no-default-lib="true"/>
/// <reference lib="esnext" />
/// <reference lib="webworker" />

// Shows Web Push notifications about new messages (payload from the api:
// {title, body, link}) and opens the conversation on click.
const sw = self as unknown as ServiceWorkerGlobalScope;

sw.addEventListener('push', (event) => {
	const data = (event.data?.json() ?? {}) as { title?: string; body?: string; link?: string };
	event.waitUntil(
		sw.registration.showNotification(data.title ?? 'TerraReality', {
			body: data.body,
			icon: '/favicon.svg',
			data: { link: data.link ?? '/zpravy' }
		})
	);
});

sw.addEventListener('notificationclick', (event) => {
	event.notification.close();
	event.waitUntil(sw.clients.openWindow(event.notification.data?.link ?? '/zpravy'));
});
