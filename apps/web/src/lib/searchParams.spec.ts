import { describe, expect, it } from 'vitest';
import { paramsFromQuery, queryFromParams } from './searchParams';

describe('search params', () => {
	it('round-trips a query through readable URL parameters', () => {
		const p = new URLSearchParams(
			'kind=apartment&layout=2%2Bkk&rent_max=18000&area=cz.praha.praha_6&a.pets=dogs&a.balcony=true&page=2'
		);
		const q = queryFromParams(p);
		expect(q).toMatchObject({
			kinds: ['apartment'],
			layouts: ['2+kk'],
			rent_max: 1_800_000,
			admin_path: 'cz.praha.praha_6',
			attributes: { pets: { values: ['dogs'] }, balcony: { bool: true } },
			offset: 24
		});
		const back = paramsFromQuery(q);
		expect(back.get('rent_max')).toBe('18000');
		expect(back.getAll('a.pets')).toEqual(['dogs']);
		expect(back.get('a.balcony')).toBe('true');
	});
});
