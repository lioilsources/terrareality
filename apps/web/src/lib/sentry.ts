/**
 * Minimal Sentry reporter (envelope API over fetch). @sentry/sveltekit does not
 * support SvelteKit 3 yet, so this covers what we need: unknown errors from the
 * server and client `handleError` hooks, no PII, no cookies, no tracing.
 * Disabled (null) when no DSN is configured, so dev and tests send nothing.
 */

export interface SentryOptions {
	dsn: string;
	release?: string;
	environment?: string;
	platform: 'node' | 'javascript';
	/** Max events per process/page load; protects the quota during error loops. */
	maxEvents?: number;
}

export interface ErrorContext {
	/** SvelteKit route id (pattern, never the concrete URL, which may hold tokens). */
	route?: string | null;
	status?: number;
	kind?: string;
	tags?: Record<string, string>;
}

export interface Reporter {
	capture(error: unknown, ctx?: ErrorContext): Promise<void>;
}

interface Dsn {
	envelopeUrl: string;
	dsn: string;
}

/** Parses https://<key>@<host>/<project> into the envelope endpoint. */
export function parseDsn(dsn: string): Dsn | null {
	try {
		const u = new URL(dsn);
		const project = u.pathname.split('/').filter(Boolean).pop();
		if (!u.username || !project || !/^\d+$/.test(project)) return null;
		const prefix = u.pathname.slice(0, u.pathname.lastIndexOf('/'));
		const q = new URLSearchParams({
			sentry_key: u.username,
			sentry_version: '7',
			sentry_client: 'terra-minimal/1.0'
		});
		return {
			envelopeUrl: `${u.protocol}//${u.host}${prefix}/api/${project}/envelope/?${q}`,
			dsn: `${u.protocol}//${u.username}@${u.host}${u.pathname}`
		};
	} catch {
		return null;
	}
}

const EMAIL = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi;
const BEARER = /\b(bearer|token|session|password|secret)([=:\s"']+)[^\s"'&,;]+/gi;
const IBAN = /\b[A-Z]{2}\d{2}(?:\s?[A-Z0-9]{4}){3,7}\b/g;
const PHONE = /\+?\d[\d\s]{8,14}\d/g;
const QUERY = /(https?:\/\/[^\s?#"']+)\?[^\s#"']*/g;

/** Removes e-mails, credentials, IBANs, phone numbers and URL query strings. */
export function scrub(s: string): string {
	return s
		.replace(QUERY, '$1?[query]')
		.replace(EMAIL, '[email]')
		.replace(BEARER, '$1$2[redacted]')
		.replace(IBAN, '[iban]')
		.replace(PHONE, '[phone]');
}

interface Frame {
	function?: string;
	filename?: string;
	lineno?: number;
	colno?: number;
	in_app?: boolean;
}

/** Parses V8 ("at fn (file:1:2)") and Gecko/WebKit ("fn@file:1:2") stack lines. */
export function parseStack(stack: string | undefined): Frame[] {
	if (!stack) return [];
	const frames: Frame[] = [];
	for (const line of stack.split('\n')) {
		const m =
			/^\s*at (?:(.+?) \()?(.+?):(\d+):(\d+)\)?$/.exec(line) ??
			/^\s*(.*?)@(.+?):(\d+):(\d+)$/.exec(line);
		if (!m) continue;
		const filename = scrub(m[2]);
		frames.push({
			function: m[1] || '?',
			filename,
			lineno: Number(m[3]),
			colno: Number(m[4]),
			in_app: !filename.includes('node_modules')
		});
	}
	return frames.reverse(); // Sentry wants the outermost frame first
}

function eventId(): string {
	return crypto.randomUUID().replaceAll('-', '');
}

/** Builds the Sentry event payload (exported for tests). */
export function buildEvent(error: unknown, ctx: ErrorContext, opts: SentryOptions) {
	const err =
		error instanceof Error
			? error
			: new Error(typeof error === 'string' ? error : 'Non-Error thrown');
	const tags: Record<string, string> = { ...ctx.tags };
	if (ctx.kind) tags.kind = ctx.kind;
	if (ctx.status) tags.status = String(ctx.status);
	return {
		event_id: eventId(),
		timestamp: Date.now() / 1000,
		platform: opts.platform,
		level: 'error',
		logger: opts.platform === 'node' ? 'sveltekit.server' : 'sveltekit.client',
		release: opts.release,
		environment: opts.environment,
		transaction: ctx.route ?? undefined,
		tags,
		exception: {
			values: [
				{
					type: err.name || 'Error',
					value: scrub(err.message ?? ''),
					stacktrace: { frames: parseStack(err.stack) }
				}
			]
		}
	};
}

/** Returns a reporter, or null when the DSN is empty or invalid. */
export function createReporter(
	opts: SentryOptions,
	fetchImpl: typeof fetch = fetch
): Reporter | null {
	const dsn = opts.dsn ? parseDsn(opts.dsn) : null;
	if (!dsn) return null;
	let budget = opts.maxEvents ?? 30;
	return {
		async capture(error, ctx = {}) {
			if (budget <= 0) return;
			budget--;
			try {
				const event = buildEvent(error, ctx, opts);
				const body =
					JSON.stringify({
						event_id: event.event_id,
						sent_at: new Date().toISOString(),
						dsn: dsn.dsn
					}) +
					'\n' +
					JSON.stringify({ type: 'event' }) +
					'\n' +
					JSON.stringify(event) +
					'\n';
				// text/plain keeps the browser request "simple" (no CORS preflight).
				await fetchImpl(dsn.envelopeUrl, {
					method: 'POST',
					body,
					headers: { 'content-type': 'text/plain;charset=UTF-8' },
					keepalive: true,
					credentials: 'omit'
				});
			} catch {
				// reporting must never break the app
			}
		}
	};
}
