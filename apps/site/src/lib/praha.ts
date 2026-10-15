/**
 * Prague and its surroundings: locality landing pages that exist even before
 * the api has listings there (launch city, plan M8 "Seed Praha"). Admin paths
 * follow the api's ltree convention (cz.<kraj>.<obec>[.<obvod>]); when the api
 * knows the locality, its own path and stats win.
 */

export type LocalityKind = 'city' | 'district' | 'municipality';

export interface Locality {
  slug: string;
  name: string;
  kind: LocalityKind;
  /** Okres for municipalities around Prague. */
  okres?: string;
  /** Neighbourhoods (katastrální území / části) for Prague districts. */
  parts?: string[];
  path: string;
}

const label = (s: string) =>
  s
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '');
export const slugify = (s: string) => label(s).replace(/_/g, '-');

const PRAHA_PATH = 'cz.hlavni_mesto_praha.praha';

const districtParts: string[][] = [
  ['Staré Město', 'Josefov', 'Malá Strana', 'Hradčany', 'Nové Město'],
  ['Vinohrady', 'Nové Město', 'Vyšehrad', 'Nusle'],
  ['Žižkov', 'Vinohrady', 'Strašnice'],
  ['Nusle', 'Michle', 'Podolí', 'Braník', 'Krč', 'Lhotka', 'Hodkovičky'],
  ['Smíchov', 'Košíře', 'Motol', 'Jinonice', 'Radlice', 'Hlubočepy'],
  ['Dejvice', 'Bubeneč', 'Břevnov', 'Střešovice', 'Veleslavín', 'Vokovice', 'Ruzyně', 'Liboc'],
  ['Holešovice', 'Bubeneč', 'Troja'],
  ['Karlín', 'Libeň', 'Kobylisy', 'Bohnice', 'Čimice', 'Troja'],
  ['Vysočany', 'Prosek', 'Střížkov', 'Libeň'],
  ['Vršovice', 'Strašnice', 'Malešice', 'Záběhlice'],
  ['Chodov', 'Háje'],
  ['Modřany', 'Komořany', 'Kamýk', 'Cholupice', 'Točná'],
  ['Stodůlky', 'Třebonice', 'Jinonice'],
  ['Černý Most', 'Kyje', 'Hloubětín', 'Hostavice'],
  ['Hostivař', 'Horní Měcholupy', 'Štěrboholy', 'Dolní Měcholupy'],
  ['Radotín', 'Zbraslav', 'Velká Chuchle', 'Lipence', 'Lochkov'],
  ['Řepy', 'Zličín', 'Sobín'],
  ['Letňany', 'Čakovice', 'Miškovice', 'Třeboradice'],
  ['Kbely', 'Vinoř', 'Satalice'],
  ['Horní Počernice'],
  ['Újezd nad Lesy', 'Běchovice', 'Klánovice', 'Koloděje'],
  ['Uhříněves', 'Kolovraty', 'Benice', 'Královice', 'Nedvězí', 'Pitkovice']
];

const nearby: [name: string, okres: string, kraj: string][] = [
  ['Říčany', 'Praha-východ', 'stredocesky_kraj'],
  ['Brandýs nad Labem-Stará Boleslav', 'Praha-východ', 'stredocesky_kraj'],
  ['Úvaly', 'Praha-východ', 'stredocesky_kraj'],
  ['Čelákovice', 'Praha-východ', 'stredocesky_kraj'],
  ['Jesenice', 'Praha-západ', 'stredocesky_kraj'],
  ['Černošice', 'Praha-západ', 'stredocesky_kraj'],
  ['Roztoky', 'Praha-západ', 'stredocesky_kraj'],
  ['Hostivice', 'Praha-západ', 'stredocesky_kraj'],
  ['Rudná', 'Praha-západ', 'stredocesky_kraj'],
  ['Beroun', 'Beroun', 'stredocesky_kraj'],
  ['Kladno', 'Kladno', 'stredocesky_kraj'],
  ['Mělník', 'Mělník', 'stredocesky_kraj']
];

export const praha: Locality = { slug: 'praha', name: 'Praha', kind: 'city', path: PRAHA_PATH };

export const prahaDistricts: Locality[] = districtParts.map((parts, i) => {
  const name = `Praha ${i + 1}`;
  return { slug: slugify(name), name, kind: 'district', parts, path: `${PRAHA_PATH}.${label(name)}` };
});

export const prahaSurroundings: Locality[] = nearby.map(([name, okres, kraj]) => ({
  slug: slugify(name),
  name,
  kind: 'municipality',
  okres,
  path: `cz.${kraj}.${label(name)}`
}));

/** All Prague-area localities, city first. */
export const prahaLocalities: Locality[] = [praha, ...prahaDistricts, ...prahaSurroundings];

export const prahaBySlug = new Map(prahaLocalities.map((l) => [l.slug, l]));
