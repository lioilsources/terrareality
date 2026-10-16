import { describe, expect, it } from 'vitest';
import { PAGE_SIZE, cursorFrom, nextCursor, pageHref, pageLinks } from './paging';

const id = (n: number) => `0190a6b2-0000-7000-8000-${String(n).padStart(12, '0')}`;

describe('paging', () => {
	it('reads only UUID cursors from the URL', () => {
		expect(cursorFrom(new URL(`http://x/a?before=${id(1)}`))).toBe(id(1));
		expect(cursorFrom(new URL('http://x/a?before=1%20OR%201=1'))).toBeUndefined();
		expect(cursorFrom(new URL(`http://x/a?after=${id(2)}`), 'after')).toBe(id(2));
		expect(cursorFrom(new URL('http://x/a'))).toBeUndefined();
	});

	it('offers a next page only after a full page', () => {
		const full = Array.from({ length: PAGE_SIZE }, (_, i) => ({ id: id(i) }));
		expect(nextCursor(full)).toBe(id(PAGE_SIZE - 1));
		expect(nextCursor(full.slice(1))).toBeNull();
		expect(nextCursor([])).toBeNull();
	});

	it('keeps other parameters in the links', () => {
		const url = new URL(`http://x/en/list?status=draft&before=${id(1)}`);
		expect(pageHref(url, 'before', id(9))).toBe(`/en/list?status=draft&before=${id(9)}`);
		expect(pageHref(url, 'before', null)).toBe('/en/list?status=draft');
		expect(pageLinks(url, 'before', null)).toEqual({ next: null, first: '/en/list?status=draft' });
		expect(pageLinks(new URL('http://x/list'), 'before', id(3))).toEqual({
			next: `/list?before=${id(3)}`,
			first: null
		});
	});

	it('drops one-shot return parameters from the links', () => {
		const url = new URL('http://x/banka?connection=abc');
		expect(pageLinks(url, 'before', id(4), ['connection']).next).toBe(`/banka?before=${id(4)}`);
	});
});
