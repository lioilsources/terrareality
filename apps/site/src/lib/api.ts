/**
 * Build-time access to the TerraReality api for static locality pages.
 * API_URL defaults to the local dev api; when it is unreachable the build
 * produces no locality pages instead of failing (landing page only).
 */
import type { ListingCard, MunicipalityStat, SearchResult } from '@terra/contracts';

const API_URL = (import.meta.env.API_URL ?? process.env.API_URL ?? 'http://localhost:8080').replace(/\/$/, '');
export const APP_URL = (import.meta.env.PUBLIC_APP_URL ?? process.env.PUBLIC_APP_URL ?? 'http://localhost:5173').replace(/\/$/, '');

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
    body: JSON.stringify({ kinds: [kind], admin_path: path, sort: 'newest', limit: 12 })
  });
  return { items: res?.items ?? [], total: res?.total ?? 0 };
}

export const czk = (minor: number) => new Intl.NumberFormat('cs-CZ').format(Math.round(minor / 100)) + ' Kč';
