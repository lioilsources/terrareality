/**
 * Cookie consent. Today the web sets only strictly necessary cookies, so the
 * banner is an informational notice and the stored value just records that it
 * was dismissed. Optional categories (analytics, ...) are added to
 * OPTIONAL_CATEGORIES; they are then off by default, shown as toggles in the
 * banner and on /cookies, and code must check `consent.categories` before
 * setting anything optional.
 */

export const CONSENT_COOKIE = 'terra_consent';
export const CONSENT_MAX_AGE = 60 * 60 * 24 * 365;
/** Bump when the cookie list changes materially; older choices are asked again. */
export const CONSENT_VERSION = 1;

export type ConsentCategory = 'analytics';

/** Optional categories in use. Empty: only necessary cookies exist. */
export const OPTIONAL_CATEGORIES: readonly ConsentCategory[] = [];

export interface Consent {
	/** The notice was answered for the current version. */
	decided: boolean;
	categories: ConsentCategory[];
}

const known = new Set<string>(['analytics']);

/** Parses `v1` or `v1.analytics`; anything else counts as undecided. */
export function readConsent(value: string | undefined | null): Consent {
	const parts = (value ?? '').split('.');
	if (parts[0] !== `v${CONSENT_VERSION}`) return { decided: false, categories: [] };
	const categories = parts
		.slice(1)
		.filter((c): c is ConsentCategory => known.has(c))
		.filter((c) => OPTIONAL_CATEGORIES.includes(c));
	return { decided: true, categories };
}

export function writeConsent(categories: readonly string[]): string {
	const allowed = OPTIONAL_CATEGORIES.filter((c) => categories.includes(c));
	return [`v${CONSENT_VERSION}`, ...allowed].join('.');
}
