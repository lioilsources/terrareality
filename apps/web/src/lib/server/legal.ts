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
