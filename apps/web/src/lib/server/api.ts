import { API_URL } from '$app/env/private';
import { createApiClient, type ApiClient } from '@terra/contracts';

/** Server-side API client. API_URL points at the Go api (internal network in prod). */
export function api(fetchFn: typeof fetch): ApiClient {
	return createApiClient(API_URL, { fetch: fetchFn });
}
