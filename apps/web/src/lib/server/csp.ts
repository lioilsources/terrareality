/**
 * Runtime additions to the Content-Security-Policy that SvelteKit builds from
 * `csp` in vite.config.ts (static directives plus per-request nonces). Origins
 * that differ per environment (imgproxy/S3, Centrifugo, map tiles, Sentry,
 * Stripe) come from env at runtime and are appended here.
 */

export type CspExtras = Partial<Record<string, string[]>>;

/** Returns the origin of a URL (ws/wss kept), or null for empty/invalid input. */
export function originOf(url: string | undefined | null): string | null {
	if (!url) return null;
	try {
		const u = new URL(url);
		return u.origin === 'null' ? null : u.origin;
	} catch {
		return null;
	}
}

/** Splits a space/comma separated origin list and keeps valid origins. */
export function origins(list: string | undefined | null): string[] {
	return (list ?? '')
		.split(/[\s,]+/)
		.map((s) => originOf(s.trim()))
		.filter((o): o is string => !!o);
}

/**
 * Appends sources to directives of a CSP header value. Directives that are
 * missing are added; 'none' is replaced; duplicates are skipped.
 */
export function extendCsp(header: string, extras: CspExtras): string {
	const parts = header
		.split(';')
		.map((p) => p.trim())
		.filter(Boolean);
	const map = new Map<string, string[]>();
	for (const p of parts) {
		const [name, ...values] = p.split(/\s+/);
		map.set(name.toLowerCase(), values);
	}
	for (const [name, add] of Object.entries(extras)) {
		if (!add?.length) continue;
		const cur = (map.get(name) ?? []).filter((v) => v !== "'none'");
		for (const v of add) if (!cur.includes(v)) cur.push(v);
		map.set(name, cur);
	}
	return [...map].map(([name, values]) => [name, ...values].join(' ')).join('; ');
}

/** Builds the runtime extras from the environment. */
export function cspExtras(env: {
	apiPublicUrl?: string;
	mapStyle?: string;
	mapOrigins?: string;
	mediaOrigins?: string;
	realtimeOrigin?: string;
	sentryDsn?: string;
	formActionOrigins?: string;
}): CspExtras {
	const map = [originOf(env.mapStyle), ...origins(env.mapOrigins)].filter((o): o is string => !!o);
	const media = origins(env.mediaOrigins);
	const realtime = origins(env.realtimeOrigin);
	const sentry = originOf(env.sentryDsn);
	const api = originOf(env.apiPublicUrl);
	return {
		'img-src': [...media, ...map],
		'connect-src': [...map, ...realtime, ...(sentry ? [sentry] : [])],
		// Non-enhanced forms whose action redirects off-site (Stripe Checkout,
		// mock checkout pages on the API, presigned downloads, BankID).
		'form-action': [...(api ? [api] : []), ...origins(env.formActionOrigins), ...media]
	};
}
