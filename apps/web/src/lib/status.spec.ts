import { describe, expect, it } from 'vitest';
import { orderChecks } from './status';

describe('orderChecks', () => {
	it('orders known checks first and unknown ones alphabetically', () => {
		const out = orderChecks({
			status: 'ok',
			checks: {
				zeta: { status: 'ok' },
				vision: { status: 'disabled' },
				database: { status: 'ok', latency_ms: 2 },
				alpha: { status: 'fail', error: 'x' }
			}
		});
		expect(out.map((c) => c.name)).toEqual(['database', 'vision', 'alpha', 'zeta']);
		expect(out[0].latencyMs).toBe(2);
	});
});
