import { error as kitError, fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { getLocale } from '#lib/paraglide/runtime.js';
import type { components } from '@terra/contracts';
import type { Actions, PageServerLoad } from './$types';

type Reason = components['schemas']['ListingReportReason'];
const reasons: Reason[] = ['illegal_content', 'fraud', 'discrimination', 'wrong_info', 'other'];

// DSA notice-and-action (art. 16): anyone can report a published listing,
// signed in or not. Works without JavaScript (plain form post).
export const load: PageServerLoad = async ({ params, locals }) => {
	const { data } = await locals.api.GET('/v1/listings/{listingId}', {
		params: { path: { listingId: params.id } }
	});
	if (!data) kitError(404);
	return { listing: data, reasons };
};

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		const f = await request.formData();
		const values = {
			reason: String(f.get('reason') ?? ''),
			explanation: String(f.get('explanation') ?? '').trim(),
			email: String(f.get('email') ?? '').trim(),
			name: String(f.get('name') ?? '').trim()
		};
		if (!reasons.includes(values.reason as Reason)) {
			return fail(400, { values, error: null, missingReason: true });
		}
		const { data, error } = await locals.api.POST('/v1/listings/{listingId}/reports', {
			params: { path: { listingId: params.id } },
			body: {
				reason: values.reason as Reason,
				explanation: values.explanation,
				email: locals.me ? undefined : values.email,
				name: locals.me ? undefined : values.name || undefined,
				locale: getLocale() === 'en' ? 'en' : 'cs'
			}
		});
		if (error) return fail(400, { values, error: errorMessage(error), missingReason: false });
		return { sent: data.id };
	}
};
