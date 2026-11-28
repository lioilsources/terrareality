import { readdirSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { apiLocale, autonyms, intlLocale } from './locale.js';

const dir = resolve(import.meta.dirname, '../../messages');
const files = readdirSync(dir).filter((f) => f.endsWith('.json'));
const load = (code: string): Record<string, unknown> =>
	JSON.parse(readFileSync(resolve(dir, `${code}.json`), 'utf8'));

/** Placeholder names used by a message (plain string or inlang plural pattern). */
function placeholders(value: unknown): string[] {
	const text = typeof value === 'string' ? value : JSON.stringify(value);
	return [...new Set([...text.matchAll(/\{(\w+)\}/g)].map((x) => x[1]))].sort();
}

const base = load('cs');
const keys = Object.keys(base).filter((k) => !k.startsWith('$'));

describe('translations', () => {
	it('ship 45 languages with a native name for each', () => {
		const codes = files.map((f) => f.replace(/\.json$/, '')).sort();
		expect(codes).toHaveLength(45);
		expect(Object.keys(autonyms).sort()).toEqual(codes);
	});

	for (const file of files) {
		const code = file.replace(/\.json$/, '');
		if (code === 'cs') continue;
		it(`${code} has every key of the base locale`, () => {
			const messages = load(code);
			expect(keys.filter((k) => !(k in messages))).toEqual([]);
			expect(Object.keys(messages).filter((k) => !k.startsWith('$') && !(k in base))).toEqual([]);
		});
		it(`${code} keeps the placeholders`, () => {
			const messages = load(code);
			const bad = keys.filter((k) => {
				const expected = placeholders(base[k]);
				// A plural branch may drop {count} in the singular ("one item"); the set must still be a subset.
				return !placeholders(messages[k]).every((p) => expected.includes(p));
			});
			expect(bad).toEqual([]);
		});
	}
});

describe('locale helpers', () => {
	it('maps UI locales to the two server languages', () => {
		expect(apiLocale('cs')).toBe('cs');
		expect(apiLocale('en')).toBe('en');
		expect(apiLocale('de')).toBe('en');
		expect(apiLocale('zh-Hans')).toBe('en');
	});
	it('keeps the established formats for cs and en', () => {
		expect(intlLocale('cs')).toBe('cs-CZ');
		expect(intlLocale('en')).toBe('en-GB');
		expect(intlLocale('pt-BR')).toBe('pt-BR');
	});
});
