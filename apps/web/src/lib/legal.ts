/**
 * Legal documents (packages/attributes/legal/{cs,en}/*.md): front matter and a
 * small, escaping Markdown renderer. The subset is documented in
 * packages/attributes/legal/README.md; anything else renders as plain text.
 */

export const LEGAL_DOCS = ['terms', 'privacy', 'cookies', 'dsa'] as const;
export type LegalDoc = (typeof LEGAL_DOCS)[number];

/** Public route of each document (Czech slugs, /en/... via paraglide). */
export const LEGAL_ROUTES: Record<LegalDoc, string> = {
	terms: '/podminky',
	privacy: '/soukromi',
	cookies: '/cookies',
	dsa: '/dsa'
};

export interface LegalMeta {
	title: string;
	version: string;
	draft: boolean;
}

/** A rendered document as passed from the server to the page. */
export interface LegalPage extends LegalMeta {
	doc: LegalDoc;
	locale: string;
	html: string;
}

export interface ParsedLegal {
	meta: LegalMeta;
	body: string;
}

export function parseFrontMatter(source: string): ParsedLegal {
	const meta: LegalMeta = { title: '', version: '', draft: true };
	const m = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?/.exec(source);
	if (!m) return { meta, body: source };
	for (const line of m[1].split(/\r?\n/)) {
		const i = line.indexOf(':');
		if (i < 0) continue;
		const key = line.slice(0, i).trim();
		const value = line.slice(i + 1).trim();
		if (key === 'title') meta.title = value;
		else if (key === 'version') meta.version = value;
		else if (key === 'draft') meta.draft = value !== 'false';
	}
	return { meta, body: source.slice(m[0].length) };
}

function escapeHtml(s: string): string {
	return s
		.replace(/&/g, '&amp;')
		.replace(/</g, '&lt;')
		.replace(/>/g, '&gt;')
		.replace(/"/g, '&quot;')
		.replace(/'/g, '&#39;');
}

/** Only relative, http(s) and mailto links survive. */
function safeHref(href: string, localize: (path: string) => string): string | null {
	if (href.startsWith('/') && !href.startsWith('//')) return localize(href);
	if (/^(https?:|mailto:)/i.test(href)) return href;
	return null;
}

function inline(text: string, localize: (path: string) => string): string {
	let out = escapeHtml(text);
	out = out.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
	out = out.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (whole, label: string, href: string) => {
		// href was escaped above; undo the entity for the check, re-escape on output.
		const raw = href.replace(/&amp;/g, '&');
		const safe = safeHref(raw, localize);
		return safe ? `<a href="${escapeHtml(safe)}">${label}</a>` : whole;
	});
	return out;
}

function slugify(s: string): string {
	return s
		.normalize('NFD')
		.replace(/[\u0300-\u036f]/g, '')
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/^-|-$/g, '');
}

/** Renders the Markdown subset to HTML. Input is escaped, so the result is safe for {@html}. */
export function renderLegalMarkdown(
	md: string,
	localize: (path: string) => string = (p) => p
): string {
	const lines = md.replace(/\r\n/g, '\n').split('\n');
	const out: string[] = [];
	let para: string[] = [];
	let list: { tag: 'ul' | 'ol'; items: string[] } | null = null;

	const flushPara = () => {
		if (para.length) out.push(`<p>${inline(para.join(' '), localize)}</p>`);
		para = [];
	};
	const flushList = () => {
		if (list) {
			out.push(
				`<${list.tag}>${list.items.map((i) => `<li>${inline(i, localize)}</li>`).join('')}</${list.tag}>`
			);
		}
		list = null;
	};
	const flush = () => {
		flushPara();
		flushList();
	};

	for (let i = 0; i < lines.length; i++) {
		const line = lines[i].trimEnd();
		if (!line.trim()) {
			flush();
			continue;
		}
		const h = /^(#{1,3})\s+(.*)$/.exec(line);
		if (h) {
			flush();
			// The page title is the <h1>; "#" and "##" both render as <h2>.
			const level = Math.max(h[1].length, 2);
			out.push(`<h${level} id="${slugify(h[2])}">${inline(h[2], localize)}</h${level}>`);
			continue;
		}
		if (line.startsWith('> ')) {
			flush();
			out.push(`<aside class="legal-note">${inline(line.slice(2), localize)}</aside>`);
			continue;
		}
		if (line.startsWith('|')) {
			flush();
			const rows: string[][] = [];
			while (i < lines.length && lines[i].trim().startsWith('|')) {
				const cells = lines[i]
					.trim()
					.replace(/^\||\|$/g, '')
					.split('|')
					.map((c) => c.trim());
				if (!cells.every((c) => /^:?-{3,}:?$/.test(c))) rows.push(cells);
				i++;
			}
			i--;
			const [head, ...body] = rows;
			out.push(
				'<div class="legal-table"><table><thead><tr>' +
					(head ?? []).map((c) => `<th scope="col">${inline(c, localize)}</th>`).join('') +
					'</tr></thead><tbody>' +
					body
						.map((r) => `<tr>${r.map((c) => `<td>${inline(c, localize)}</td>`).join('')}</tr>`)
						.join('') +
					'</tbody></table></div>'
			);
			continue;
		}
		const li = /^(-|\d+\.)\s+(.*)$/.exec(line);
		if (li) {
			flushPara();
			const tag = li[1] === '-' ? 'ul' : 'ol';
			if (list && list.tag !== tag) flushList();
			if (!list) list = { tag, items: [] };
			list.items.push(li[2]);
			continue;
		}
		if (list) {
			// Continuation line of the previous list item.
			list.items[list.items.length - 1] += ' ' + line.trim();
			continue;
		}
		para.push(line.trim());
	}
	flush();
	return out.join('\n');
}
