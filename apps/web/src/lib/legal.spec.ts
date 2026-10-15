import { describe, expect, it } from 'vitest';
import { parseFrontMatter, renderLegalMarkdown } from './legal';

describe('legal documents', () => {
	it('reads front matter', () => {
		const { meta, body } = parseFrontMatter(
			'---\ntitle: Podmínky\nversion: 2026-10\ndraft: true\n---\n\n## A\n'
		);
		expect(meta).toEqual({ title: 'Podmínky', version: '2026-10', draft: true });
		expect(body.trim()).toBe('## A');
	});

	it('renders the subset and escapes html', () => {
		const html = renderLegalMarkdown(
			'## 1. Úvod\n\nText <script>x</script> **tučně**.\n\n1. první\n2. druhý\n\n- a\n- b',
			(p) => '/en' + p
		);
		expect(html).toContain('<h2 id="1-uvod">1. Úvod</h2>');
		expect(html).toContain('&lt;script&gt;');
		expect(html).not.toContain('<script>');
		expect(html).toContain('<strong>tučně</strong>');
		expect(html).toContain('<ol><li>první</li><li>druhý</li></ol>');
		expect(html).toContain('<ul><li>a</li><li>b</li></ul>');
	});

	it('localizes relative links and drops unsafe ones', () => {
		const html = renderLegalMarkdown(
			'[DSA](/dsa) [web](https://uoou.cz) [x](javascript:alert(1))',
			(p) => '/en' + p
		);
		expect(html).toContain('<a href="/en/dsa">DSA</a>');
		expect(html).toContain('<a href="https://uoou.cz">web</a>');
		expect(html).not.toContain('href="javascript');
	});

	it('renders tables', () => {
		const html = renderLegalMarkdown('| A | B |\n| --- | --- |\n| 1 | 2 |');
		expect(html).toContain('<th scope="col">A</th>');
		expect(html).toContain('<td>2</td>');
	});
});
