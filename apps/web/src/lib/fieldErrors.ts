import type { FieldError } from '@terra/contracts';
import { m } from '#lib/paraglide/messages.js';

const reasonKey: Record<string, () => string> = {
	title: m.reason_title,
	description: m.reason_description,
	rent: m.reason_rent,
	photos: m.reason_photos
};

/** Translates field errors from a 422 problem into short messages. */
export function fieldMessages(
	errors: FieldError[] | undefined,
	labelOf: (key: string) => string
): string[] {
	return (errors ?? []).map((e) => {
		if (e.reason === 'privacy_review_pending') return m.reason_privacy_review_pending();
		if (e.reason.startsWith('deposit_over_limit:')) {
			return m.err_deposit_over_limit({ months: e.reason.split(':')[1] });
		}
		const name = reasonKey[e.key]?.() ?? labelOf(e.key);
		return e.reason === 'required' || e.reason.startsWith('at least')
			? name
			: `${name}: ${e.reason}`;
	});
}
