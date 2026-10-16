/** Fallback target of a push notification click. */
export const PUSH_FALLBACK = '/zpravy';

/**
 * Resolves the `link` of a push payload against the app origin and accepts it
 * only when it stays on that origin (relative paths or same-origin URLs).
 * Anything else (other hosts, javascript:, protocol-relative) opens the inbox.
 */
export function safePushLink(link: unknown, origin: string): string {
	if (typeof link !== 'string' || !link) return PUSH_FALLBACK;
	try {
		const url = new URL(link, origin);
		if (url.origin !== origin) return PUSH_FALLBACK;
		return url.pathname + url.search + url.hash;
	} catch {
		return PUSH_FALLBACK;
	}
}
