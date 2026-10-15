import type { ClientInit, HandleClientError } from '@sveltejs/kit/hooks';
import { version } from '$app/env';
import {
	PUBLIC_SENTRY_DSN,
	PUBLIC_SENTRY_ENVIRONMENT,
	PUBLIC_SENTRY_RELEASE
} from '$app/env/public';
import { createReporter } from '#lib/sentry.js';

const sentry = createReporter({
	dsn: PUBLIC_SENTRY_DSN,
	release: PUBLIC_SENTRY_RELEASE || version,
	environment: PUBLIC_SENTRY_ENVIRONMENT,
	platform: 'javascript',
	maxEvents: 10
});

/** Catches errors outside navigation (event handlers, async code). */
export const init: ClientInit = () => {
	if (!sentry) return;
	addEventListener(
		'error',
		(e) => void sentry.capture(e.error ?? e.message, { tags: { runtime: 'browser' } })
	);
	addEventListener(
		'unhandledrejection',
		(e) => void sentry.capture(e.reason, { tags: { runtime: 'browser', unhandled: 'rejection' } })
	);
};

/** Reports unexpected errors during navigation/load to Sentry, without PII. */
export const handleError: HandleClientError = ({ error, event, kind }) => {
	if (sentry && kind === 'unknown') {
		void sentry.capture(error, { route: event.route.id, kind, tags: { runtime: 'browser' } });
	}
};
