// See https://svelte.dev/docs/kit/types#app.d.ts
import type { ApiClient, Me } from '@terra/contracts';

declare global {
	namespace App {
		interface Locals {
			/** Current user, null when anonymous. */
			me: Me | null;
			/** Session token for api calls on behalf of the user. */
			token: string | null;
			/** Api client bound to the user's session. */
			api: ApiClient;
			/** Set when an expired session cookie was cleared in this request. */
			sessionCleared?: boolean;
		}
		// interface Error {}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}
}

export {};
