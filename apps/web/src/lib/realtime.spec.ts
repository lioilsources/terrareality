import { describe, expect, it } from 'vitest';
import { backoff } from './realtime';

describe('realtime backoff', () => {
	it('doubles from one second and caps at thirty', () => {
		const mid = () => 0.5; // no jitter
		expect([0, 1, 2, 3, 4, 5, 6, 10].map((n) => backoff(n, mid))).toEqual([
			1000, 2000, 4000, 8000, 16000, 30000, 30000, 30000
		]);
	});

	it('adds at most 20 % jitter', () => {
		expect(backoff(0, () => 0)).toBe(800);
		expect(backoff(0, () => 1)).toBe(1200);
	});
});
