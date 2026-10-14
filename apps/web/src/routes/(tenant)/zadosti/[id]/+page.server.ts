import { error as kitError, fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { data } = await locals.api.GET('/v1/applications/{applicationId}', {
		params: { path: { applicationId: params.id } }
	});
	if (!data) kitError(404);
	return { detail: data };
};

const path = (id: string) => ({ params: { path: { applicationId: id } } });

export const actions: Actions = {
	consent: async ({ params, locals }) => {
		const { error } = await locals.api.POST(
			'/v1/applications/{applicationId}/consent',
			path(params.id)
		);
		if (error) return fail(400, { error: errorMessage(error) });
	},
	withdraw: async ({ params, locals }) => {
		const { error } = await locals.api.POST(
			'/v1/applications/{applicationId}/withdraw',
			path(params.id)
		);
		if (error) return fail(400, { error: errorMessage(error) });
	},
	book: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.POST('/v1/applications/{applicationId}/bookings', {
			...path(params.id),
			body: { slot_id: String(f.get('slot_id')) }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	cancel: async ({ request, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.DELETE('/v1/viewing-bookings/{bookingId}', {
			params: { path: { bookingId: String(f.get('booking_id')) } }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
