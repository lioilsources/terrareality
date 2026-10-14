import { API_URL } from '$app/env/private';
import { createApiClient, type ApiClient } from '@terra/contracts';

/** Server-side API client. API_URL points at the Go api (internal network in prod). */
export function api(
	fetchFn: typeof fetch,
	opts: { token?: string | null; clientIp?: string; userAgent?: string | null } = {}
): ApiClient {
	const headers: Record<string, string> = {};
	if (opts.token) headers.Authorization = `Bearer ${opts.token}`;
	// The api trusts X-Forwarded-For from this server (TRUSTED_PROXIES), so rate
	// limits and audit logs see the real browser address.
	if (opts.clientIp) headers['X-Forwarded-For'] = opts.clientIp;
	if (opts.userAgent) headers['User-Agent'] = opts.userAgent;
	return createApiClient(API_URL, { fetch: fetchFn, headers });
}
