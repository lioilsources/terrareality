/**
 * Cursor paging of api lists (`before` for newest-first lists, `after` for the
 * oldest-first moderation queue). The cursor lives in the page URL, so "load more"
 * is a plain link: it works without JavaScript and every page can be shared.
 */
export const PAGE_SIZE = 50;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** The cursor from the URL search parameter `name`; anything that is not a UUID is ignored. */
export function cursorFrom(url: URL, name = 'before'): string | undefined {
	const v = url.searchParams.get(name);
	return v && UUID.test(v) ? v : undefined;
}

/**
 * The cursor of the next page for lists without one in the response: a full page
 * (as many items as the limit) may have more, so the last item's id is the cursor.
 */
export function nextCursor(items: readonly { id: string }[], limit = PAGE_SIZE): string | null {
	return items.length >= limit && items.length > 0 ? items[items.length - 1].id : null;
}

/** The current URL with the cursor parameter set (or removed when cursor is null); other parameters stay. */
export function pageHref(url: URL, name: string, cursor: string | null): string {
	const p = new URLSearchParams(url.searchParams);
	if (cursor) p.set(name, cursor);
	else p.delete(name);
	const q = p.toString();
	return q ? `${url.pathname}?${q}` : url.pathname;
}

/**
 * Links of the paging control: the next page and, on a later page, back to the first one.
 * `drop` names one-shot parameters (return markers) the links must not repeat.
 */
export function pageLinks(
	url: URL,
	name: string,
	next: string | null | undefined,
	drop: readonly string[] = []
) {
	const clean = new URL(url);
	for (const d of drop) clean.searchParams.delete(d);
	return {
		next: next ? pageHref(clean, name, next) : null,
		first: clean.searchParams.has(name) ? pageHref(clean, name, null) : null
	};
}
