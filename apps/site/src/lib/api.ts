/**
 * Build-time access to the TerraReality api for static locality pages.
 * API_URL defaults to the local dev api; when it is unreachable the build
 * produces no locality pages instead of failing (landing page only).
 */
import type { ListingCard, MunicipalityStat, SearchResult } from '@terra/contracts';

const env = (name: string): string | undefined =>
  (import.meta.env[name] as string | undefined) || process.env[name] || undefined;
const isLocal = (url: string) => /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:|\/|$)/.test(url);

const API_URL = (env('API_URL') ?? 'http://localhost:8080').replace(/\/$/, '');

/**
 * A production build is a `astro build` against a non-local api (deploy runbook)
 * or one with SITE_ENV=production. It must link to the real web app: every CTA,
 * footer link and locality page would otherwise point at localhost.
 */
const productionBuild =
  import.meta.env.PROD && (env('SITE_ENV') === 'production' || !isLocal(API_URL));
const appUrl = env('PUBLIC_APP_URL');
if (productionBuild && (!appUrl || isLocal(appUrl))) {
  throw new Error(
    `[site] PUBLIC_APP_URL must be set to the public web app URL for a production build (got ${appUrl ? `"${appUrl}"` : 'nothing'}; API_URL=${API_URL}).`
  );
}

/** Origin of the SvelteKit app (CTAs, footer, listing links). The only place it is read. */
export const APP_URL = (appUrl ?? 'http://localhost:5173').replace(/\/$/, '');

let unreachable = false;

async function get<T>(path: string, init?: RequestInit): Promise<T | null> {
  if (unreachable) return null;
  try {
    const res = await fetch(API_URL + path, init);
    return res.ok ? ((await res.json()) as T) : null;
  } catch {
    unreachable = true;
    console.warn(`[site] api not reachable at ${API_URL}; building static Praha pages without listings`);
    return null;
  }
}

const muniCache = new Map<string, Promise<MunicipalityStat[]>>();

export function municipalities(kind: string): Promise<MunicipalityStat[]> {
  let p = muniCache.get(kind);
  if (!p) {
    p = get<MunicipalityStat[]>(`/v1/seo/municipalities?kind=${kind}`).then((r) => r ?? []);
    muniCache.set(kind, p);
  }
  return p;
}

export async function topListings(kind: string, path: string): Promise<{ items: ListingCard[]; total: number }> {
  const res = await get<SearchResult>('/v1/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    // Demo listings of the closed beta never appear on the static site.
    body: JSON.stringify({ kinds: [kind], admin_path: path, sort: 'newest', limit: 12, exclude_demo: true })
  });
  return { items: (res?.items ?? []).filter((c) => !c.is_demo), total: res?.total ?? 0 };
}

/** Median rents from /v1/seo/municipalities are CZK minor units (the stat has no currency). */
export const czk = (minor: number) =>
  new Intl.NumberFormat('cs-CZ', { style: 'currency', currency: 'CZK', maximumFractionDigits: 0 }).format(Math.round(minor / 100));
