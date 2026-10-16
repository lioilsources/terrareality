import type { SearchQuery, UnitKind } from '@terra/contracts';

/**
 * Search state lives in readable URL parameters (shareable links):
 * kind, layout, rent_min/rent_max (CZK), area_min/area_max, area (admin path),
 * bbox, text, sort, page and attributes as a.<key>=value (repeated) or a.<key>=true.
 */
export const PAGE_SIZE = 24;

const num = (v: string | null) =>
	v !== null && v !== '' && Number.isFinite(Number(v)) ? Number(v) : undefined;

export function queryFromParams(p: URLSearchParams): SearchQuery {
	// The in-app search shows closed-beta demo listings (labelled); only static locality pages drop them.
	const q: SearchQuery = { exclude_demo: false };
	const kinds = p.getAll('kind').filter(Boolean) as UnitKind[];
	if (kinds.length) q.kinds = kinds;
	const layouts = p.getAll('layout').filter(Boolean);
	if (layouts.length) q.layouts = layouts;
	const rmin = num(p.get('rent_min'));
	const rmax = num(p.get('rent_max'));
	if (rmin !== undefined) q.rent_min = Math.round(rmin * 100);
	if (rmax !== undefined) q.rent_max = Math.round(rmax * 100);
	const amin = num(p.get('area_min'));
	const amax = num(p.get('area_max'));
	if (amin !== undefined) q.area_min = amin;
	if (amax !== undefined) q.area_max = amax;
	const area = p.get('area');
	if (area) q.admin_path = area;
	const bbox = p.get('bbox')?.split(',').map(Number);
	if (bbox?.length === 4 && bbox.every(Number.isFinite)) q.bbox = bbox;
	const text = p.get('text');
	if (text) q.text = text;
	const sort = p.get('sort');
	if (sort) q.sort = sort as SearchQuery['sort'];
	const page = Math.max(1, num(p.get('page')) ?? 1);
	q.limit = PAGE_SIZE;
	q.offset = (page - 1) * PAGE_SIZE;
	const attributes: NonNullable<SearchQuery['attributes']> = {};
	for (const key of new Set([...p.keys()].filter((k) => k.startsWith('a.')))) {
		const name = key.slice(2);
		const values = p.getAll(key).filter(Boolean);
		if (values.length === 1 && (values[0] === 'true' || values[0] === 'false')) {
			attributes[name] = { bool: values[0] === 'true' };
		} else if (values.length) {
			attributes[name] = { values };
		}
	}
	if (Object.keys(attributes).length) q.attributes = attributes;
	return q;
}

export function paramsFromQuery(q: SearchQuery): URLSearchParams {
	const p = new URLSearchParams();
	q.kinds?.forEach((k) => p.append('kind', k));
	q.layouts?.forEach((l) => p.append('layout', l));
	if (q.rent_min !== undefined) p.set('rent_min', String(Math.round(q.rent_min / 100)));
	if (q.rent_max !== undefined) p.set('rent_max', String(Math.round(q.rent_max / 100)));
	if (q.area_min !== undefined) p.set('area_min', String(q.area_min));
	if (q.area_max !== undefined) p.set('area_max', String(q.area_max));
	if (q.admin_path) p.set('area', q.admin_path);
	if (q.bbox?.length === 4) p.set('bbox', q.bbox.map((n) => n.toFixed(5)).join(','));
	if (q.text) p.set('text', q.text);
	if (q.sort && q.sort !== 'relevance') p.set('sort', q.sort);
	for (const [k, f] of Object.entries(q.attributes ?? {})) {
		if (f.bool !== undefined) p.set(`a.${k}`, String(f.bool));
		f.values?.forEach((v) => p.append(`a.${k}`, v));
	}
	return p;
}
