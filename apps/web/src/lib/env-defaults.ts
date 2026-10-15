/**
 * Local development defaults for env vars that point at other services. In a
 * production runtime (NODE_ENV=production) a missing value is a deployment
 * error, not a reason to fall back to localhost: the app would start, but CSP
 * would block every photo, websocket and off-site form redirect. Used by
 * src/env.ts (defaults) and hooks.server.ts (startup check).
 */
export const LOCAL_DEFAULTS = {
	API_URL: 'http://localhost:8080',
	API_PUBLIC_URL: 'http://localhost:8080',
	CSP_MEDIA_ORIGINS: 'http://localhost:8081 http://localhost:8333',
	CSP_REALTIME_ORIGIN: 'ws://localhost:8000'
} as const;

export type LocalDefault = keyof typeof LOCAL_DEFAULTS;

type Env = Record<string, string | undefined>;

const runtimeEnv = (): Env => (typeof process === 'undefined' ? {} : process.env);

/**
 * Whether localhost fallbacks are forbidden. `vite preview` (Playwright e2e)
 * also runs with NODE_ENV=production; it opts out with ALLOW_LOCALHOST_DEFAULTS=1.
 */
export function strictEnv(env: Env = runtimeEnv()): boolean {
	return env.NODE_ENV === 'production' && env.ALLOW_LOCALHOST_DEFAULTS !== '1';
}

/** Names of required production variables that are unset or empty. */
export function missingProductionVars(env: Env = runtimeEnv()): LocalDefault[] {
	return (Object.keys(LOCAL_DEFAULTS) as LocalDefault[]).filter((k) => !env[k]);
}

/** Value of `name`, or its localhost default (validated at startup by assertProductionEnv). */
export function withLocalDefault(name: LocalDefault, value: string | undefined): string {
	return value || LOCAL_DEFAULTS[name];
}

/**
 * Fails server startup in production when any service URL / CSP origin is
 * missing, naming all of them at once. Called from hooks.server.ts outside the
 * build (route analysis also runs with NODE_ENV=production but has no runtime env).
 */
export function assertProductionEnv(env: Env = runtimeEnv()): void {
	if (!strictEnv(env)) return;
	const missing = missingProductionVars(env);
	if (missing.length === 0) return;
	throw new Error(
		`Missing environment variables for production: ${missing.join(', ')}. ` +
			'They have localhost defaults only in development (see apps/web/src/env.ts); ' +
			'set them in the web service environment, or ALLOW_LOCALHOST_DEFAULTS=1 for a local preview.'
	);
}
