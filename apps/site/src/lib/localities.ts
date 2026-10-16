/**
 * Locality landing pages: api municipalities (cs only) merged with the static
 * Prague-area set (cs + en, see praha.ts). Shared by the page routes and the sitemap.
 */
import type { MunicipalityStat } from '@terra/contracts';
import { czk, municipalities } from './api';
import { prahaBySlug, prahaLocalities, type Locality } from './praha';

export type Lang = 'cs' | 'en';

export interface KindInfo {
  kind: 'apartment' | 'room';
  title: string;
  noun: string;
  /** Kind slug of the other language. */
  alt: string;
}

export const kindsByLang: Record<Lang, Record<string, KindInfo>> = {
  cs: {
    'pronajem-bytu': { kind: 'apartment', title: 'Pronájem bytů', noun: 'bytů', alt: 'apartments-for-rent' },
    'pronajem-pokoje': { kind: 'room', title: 'Pronájem pokojů', noun: 'pokojů', alt: 'rooms-for-rent' }
  },
  en: {
    'apartments-for-rent': { kind: 'apartment', title: 'Apartments for rent', noun: 'apartments', alt: 'pronajem-bytu' },
    'rooms-for-rent': { kind: 'room', title: 'Rooms for rent', noun: 'rooms', alt: 'pronajem-pokoje' }
  }
};

export interface LocalityPage {
  slug: string;
  name: string;
  /** Admin path used for search links. */
  path: string;
  stat?: MunicipalityStat;
  praha?: Locality;
}

/** Pages for one kind and language: Prague area always, api municipalities in Czech. */
export async function localityPages(lang: Lang, kindSlug: string): Promise<LocalityPage[]> {
  const k = kindsByLang[lang][kindSlug];
  const stats = await municipalities(k.kind);
  const bySlug = new Map(stats.map((s) => [s.slug, s]));
  const out: LocalityPage[] = prahaLocalities.map((l) => {
    const stat = bySlug.get(l.slug);
    return { slug: l.slug, name: l.name, path: stat?.path ?? l.path, stat, praha: l };
  });
  if (lang === 'cs') {
    for (const s of stats) {
      if (!prahaBySlug.has(s.slug)) out.push({ slug: s.slug, name: s.name, path: s.path, stat: s });
    }
  }
  return out;
}

/**
 * Whether a locality page is worth indexing: hubs (Prague city page) always,
 * other localities only with at least one current listing. Empty pages are
 * thin content, so they get noindex and stay out of the sitemap.
 */
export const indexable = (page: LocalityPage) =>
  page.praha?.kind === 'city' || (page.stat?.listings ?? 0) > 0;

/** Czech plural of "nabídka" (1 nabídka, 2–4 nabídky, 5+ nabídek). */
const nabidek = (n: number) => (n === 1 ? 'aktuální nabídka' : n >= 2 && n <= 4 ? 'aktuální nabídky' : 'aktuálních nabídek');
const offers = (n: number) => (n === 1 ? 'current offer' : 'current offers');

export const pagePath = (lang: Lang, kindSlug: string, slug?: string) =>
  `${lang === 'en' ? '/en' : ''}/${kindSlug}${slug ? `/${slug}` : ''}`;

/** cs/en URLs of a locality page; en exists only for the Prague area. */
export function alternates(lang: Lang, kindSlug: string, page?: LocalityPage) {
  const k = kindsByLang[lang][kindSlug];
  const [csKind, enKind] = lang === 'cs' ? [kindSlug, k.alt] : [k.alt, kindSlug];
  if (page && !page.praha) return null;
  return { cs: pagePath('cs', csKind, page?.slug), en: pagePath('en', enKind, page?.slug) };
}

export { czk };

/** SEO copy for a locality page. */
export function localityCopy(lang: Lang, k: KindInfo, p: LocalityPage) {
  const l = p.praha;
  const title = `${k.title} ${p.name}`;
  if (lang === 'cs') {
    const where =
      l?.kind === 'district'
        ? `${p.name} (${l.parts!.slice(0, 3).join(', ')})`
        : l?.kind === 'municipality'
          ? `${p.name} (okres ${l.okres})`
          : p.name;
    const stats = p.stat?.listings
      ? `${p.stat.listings} ${nabidek(p.stat.listings)}, medián nájmu ${czk(p.stat.median_rent)}.`
      : 'Nabídky přímo od majitelů a správců.';
    const intro =
      l?.kind === 'city'
        ? 'Praha je největší nájemní trh v Česku. Vyberte městskou část nebo obec v okolí, nebo hledejte rovnou na mapě.'
        : l?.kind === 'district'
          ? `${p.name} zahrnuje mimo jiné ${l.parts!.join(', ')}.`
          : l?.kind === 'municipality'
            ? `${p.name} leží v okrese ${l.okres}, v dojezdové vzdálenosti Prahy.`
            : '';
    return {
      title,
      description: `${k.title} ${where} – ${stats} Bez provize, smlouva online, platby přímo majiteli.`,
      intro,
      statsLine: p.stat?.listings
        ? `${p.stat.listings} ${nabidek(p.stat.listings)} · medián nájmu ${czk(p.stat.median_rent)} měsíčně`
        : 'Zatím tu nejsou žádné nabídky. Uložte si hledání a dáme vám vědět, až se objeví.',
      cta: 'Všechny nabídky na mapě',
      nearby: l?.kind === 'municipality' ? 'Další obce v okolí Prahy' : 'Městské části Prahy',
      around: 'Okolí Prahy'
    };
  }
  const where =
    l?.kind === 'district'
      ? `${p.name} (${l.parts!.slice(0, 3).join(', ')})`
      : l?.kind === 'municipality'
        ? `${p.name} (${l.okres} district)`
        : p.name === 'Praha'
          ? 'Prague'
          : p.name;
  const stats = p.stat?.listings
    ? `${p.stat.listings} ${offers(p.stat.listings)}, median rent ${czk(p.stat.median_rent)}.`
    : 'Offers directly from landlords and managers.';
  const intro =
    l?.kind === 'city'
      ? 'Prague is the largest rental market in Czechia. Pick a district or a town nearby, or search straight on the map.'
      : l?.kind === 'district'
        ? `${p.name} covers, among others, ${l.parts!.join(', ')}.`
        : l?.kind === 'municipality'
          ? `${p.name} lies in the ${l.okres} district, within commuting distance of Prague.`
          : '';
  return {
    title: `${k.title} in ${p.name === 'Praha' ? 'Prague' : p.name}`,
    description: `${k.title} in ${where} – ${stats} No agency fee, lease signed online, rent paid straight to the landlord.`,
    intro,
    statsLine: p.stat?.listings
      ? `${p.stat.listings} ${offers(p.stat.listings)} · median rent ${czk(p.stat.median_rent)} per month`
      : 'No offers here yet. Save your search and we will let you know.',
    cta: 'All offers on the map',
    nearby: l?.kind === 'municipality' ? 'Other towns around Prague' : 'Prague districts',
    around: 'Around Prague'
  };
}
