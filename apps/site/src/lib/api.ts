/**
 * Build-time access to the TerraReality api for static locality pages.
 * API_URL defaults to the local dev api; when it is unreachable the build
 * produces no locality pages instead of failing (landing page only).
 */
import type { ListingCard, MunicipalityStat, SearchResult } from '@terra/contracts';

const API_URL = (import.meta.env.API_URL ?? process.env.API_URL ?? 'http://localhost:8080').replace(/\/$/, '');
export const APP_URL = (import.meta.env.PUBLIC_APP_URL ?? process.env.PUBLIC_APP_URL ?? 'http://localhost:5173').replace(/\/$/, '');

export const kinds = {
  'pronajem-bytu': { kind: 'apartment', title: 'Pronájem bytů', noun: 'bytů' },
  'pronajem-pokoje': { kind: 'room', title: 'Pronájem pokojů', noun: 'pokojů' }
} as const;
export type KindSlug = keyof typeof kinds;

async function get<T>(path: string, init?: RequestInit): Promise<T | null> {
  try {
    const res = await fetch(API_URL + path, init);
    return res.ok ? ((await res.json()) as T) : null;
  } catch {
    console.warn(`[site] api not reachable at ${API_URL}; skipping locality pages`);
    return null;
  }
}

export async function municipalities(kind: string): Promise<MunicipalityStat[]> {
  return (await get<MunicipalityStat[]>(`/v1/seo/municipalities?kind=${kind}`)) ?? [];
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
