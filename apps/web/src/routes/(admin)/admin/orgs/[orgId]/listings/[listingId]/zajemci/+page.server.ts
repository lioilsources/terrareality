import { error as kitError, fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const path = { params: { path: { orgId: params.orgId, listingId: params.listingId } } };
	const [listing, applicants, slots] = await Promise.all([
		locals.api.GET('/v1/orgs/{orgId}/listings/{listingId}', path),
		locals.api.GET('/v1/orgs/{orgId}/listings/{listingId}/applications', path),
		locals.api.GET('/v1/orgs/{orgId}/listings/{listingId}/viewing-slots', path)
	]);
	if (!listing.data) kitError(404);
	const roommates =
		listing.data.unit.kind === 'room' && listing.data.status === 'published'
			? ((await locals.api.GET('/v1/orgs/{orgId}/listings/{listingId}/roommates', path)).data ?? [])
			: [];
	return {
		listing: listing.data,
		applicants: applicants.data ?? [],
		slots: slots.data ?? [],
		roommates
	};
};

export const actions: Actions = {
	decide: async ({ request, params, locals }) => {
		const f = await request.formData();
		const action = String(f.get('action')) as 'invite' | 'accept' | 'reject';
		const reason = String(f.get('reason') ?? '');
		const { error } = await locals.api.POST(
			'/v1/orgs/{orgId}/applications/{applicationId}/decision',
			{
				params: { path: { orgId: params.orgId, applicationId: String(f.get('application_id')) } },
				body: { action, reason: (reason || undefined) as 'other' | undefined }
			}
		);
		if (error) return fail(400, { error: errorMessage(error) });
	},
	slot: async ({ request, params, locals }) => {
		const f = await request.formData();
		const when = new Date(String(f.get('starts_at')));
		const { error } = await locals.api.POST('/v1/orgs/{orgId}/listings/{listingId}/viewing-slots', {
			params: { path: { orgId: params.orgId, listingId: params.listingId } },
			body: {
				starts_at: when.toISOString(),
				duration_min: Number(f.get('duration_min') || 20),
				capacity: Number(f.get('capacity') || 1),
				note: String(f.get('note') ?? '')
			}
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	deleteSlot: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.DELETE('/v1/orgs/{orgId}/viewing-slots/{slotId}', {
			params: { path: { orgId: params.orgId, slotId: String(f.get('slot_id')) } }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
