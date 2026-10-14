import type { Health } from '@terra/contracts';

export type CheckView = {
	name: string;
	state: 'ok' | 'fail' | 'disabled';
	latencyMs?: number;
	error?: string;
};

/** Stable, display-ordered list of health checks. Unknown checks go last, alphabetically. */
export function orderChecks(health: Health): CheckView[] {
	const order = ['database', 'worker', 'centrifugo', 'vision'];
	return Object.entries(health.checks)
		.map(([name, c]) => ({ name, state: c.status, latencyMs: c.latency_ms, error: c.error }))
		.sort((a, b) => {
			const ia = order.indexOf(a.name);
			const ib = order.indexOf(b.name);
			if (ia === -1 && ib === -1) return a.name.localeCompare(b.name);
			if (ia === -1) return 1;
			if (ib === -1) return -1;
			return ia - ib;
		});
}
