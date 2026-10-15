import type { APIRoute } from 'astro';
import { alternates, kindsByLang, localityPages, pagePath } from '../lib/localities';

const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

/** Static sitemap of all landing and locality pages with cs/en alternates. */
export const GET: APIRoute = async ({ site }) => {
  const abs = (p: string) => esc(new URL(p, site).toString());
  const entries: { loc: string; alt?: { cs: string; en: string } | null }[] = [
    { loc: '/', alt: { cs: '/', en: '/en/' } },
    { loc: '/en/', alt: { cs: '/', en: '/en/' } }
  ];
  for (const lang of ['cs', 'en'] as const) {
    for (const kindSlug of Object.keys(kindsByLang[lang])) {
      entries.push({ loc: pagePath(lang, kindSlug), alt: alternates(lang, kindSlug) });
      for (const page of await localityPages(lang, kindSlug)) {
        entries.push({ loc: pagePath(lang, kindSlug, page.slug), alt: alternates(lang, kindSlug, page) });
      }
    }
  }
  const urls = entries.map(({ loc, alt }) => {
    const links = alt
      ? [
          `<xhtml:link rel="alternate" hreflang="cs" href="${abs(alt.cs)}"/>`,
          `<xhtml:link rel="alternate" hreflang="en" href="${abs(alt.en)}"/>`,
          `<xhtml:link rel="alternate" hreflang="x-default" href="${abs(alt.cs)}"/>`
        ].join('')
      : '';
    return `<url><loc>${abs(loc)}</loc>${links}</url>`;
  });
  const xml =
    '<?xml version="1.0" encoding="UTF-8"?>\n' +
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n' +
    urls.join('\n') +
    '\n</urlset>\n';
  return new Response(xml, { headers: { 'Content-Type': 'application/xml; charset=utf-8' } });
};
