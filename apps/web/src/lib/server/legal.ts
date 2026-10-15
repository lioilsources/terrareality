import { error } from '@sveltejs/kit';
import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
import {
	parseFrontMatter,
	renderLegalMarkdown,
	type LegalDoc,
	type LegalPage
} from '#lib/legal.js';

// Bundled at build time from the shared package (the Docker build copies packages/).
const sources = import.meta.glob('../../../../../packages/attributes/legal/*/*.md', {
	query: '?raw',
	import: 'default',
	eager: true
}) as Record<string, string>;

/** Loads a legal document in the request locale (Czech fallback). */
export function legalPage(doc: LegalDoc): LegalPage {
	const locale = getLocale();
	const pick = (l: string) =>
		Object.entries(sources).find(([path]) => path.endsWith(`/legal/${l}/${doc}.md`))?.[1];
	const source = pick(locale) ?? pick('cs');
	if (!source) error(404, 'Not found');
	const { meta, body } = parseFrontMatter(source);
	return {
		...meta,
		doc,
		locale,
		html: renderLegalMarkdown(body, (path) => localizeHref(path))
	};
}

/**
 * Version of a legal document as recorded in the consent log. The Czech text is
 * the binding one, so its front matter is the single source of the version
 * (register, marketing consent and the e2e helpers all read it from here).
 */
export function legalVersion(doc: LegalDoc): string {
	const source = Object.entries(sources).find(([path]) =>
		path.endsWith(`/legal/cs/${doc}.md`)
	)?.[1];
	const version = source ? parseFrontMatter(source).meta.version : '';
	if (!version) throw new Error(`legal document ${doc} has no version in its front matter`);
	return version;
}
