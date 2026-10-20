import { error as kitError, fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { leaseFromForm } from '#lib/leasing.js';
import { payWithRevolut, revolutState } from '#lib/server/billing.js';
import {
	giveLandlordNotice,
	inviteLeaseParty,
	loadLease,
	signLease,
	uploadContractScan
} from '#lib/server/leases.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const [lease, revolut] = await Promise.all([
		loadLease(locals.api, params.leaseId),
		revolutState(locals.api, params.orgId)
	]);
	if (!lease || !lease.detail.landlord_view) kitError(404);
	return { ...lease, revolut };
};

export const actions: Actions = {
	update: async ({ request, params, locals }) => {
		const { error } = await locals.api.PUT('/v1/orgs/{orgId}/leases/{leaseId}', {
			params: { path: { orgId: params.orgId, leaseId: params.leaseId } },
			body: leaseFromForm(await request.formData())
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	propose: async ({ params, locals }) => {
		const { error } = await locals.api.POST('/v1/orgs/{orgId}/leases/{leaseId}/propose', {
			params: { path: { orgId: params.orgId, leaseId: params.leaseId } }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	sign: async ({ request, params, locals }) =>
		signLease(locals.api, params.leaseId, await request.formData()),
	paid: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.POST('/v1/orgs/{orgId}/obligation-shares/{shareId}/paid', {
			params: { path: { orgId: params.orgId, shareId: String(f.get('share_id')) } },
			body: {}
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	revolut: async ({ request, locals }) => {
		const f = await request.formData();
		return payWithRevolut(locals.api, String(f.get('share_id') ?? ''));
	},
	scan: async ({ request, params, locals }) =>
		uploadContractScan(locals.api, params.orgId, params.leaseId, await request.formData()),
	invite: async ({ request, params, locals }) =>
		inviteLeaseParty(locals.api, params.orgId, params.leaseId, await request.formData()),
	notice: async ({ request, params, locals }) =>
		giveLandlordNotice(locals.api, params.leaseId, await request.formData()),
	settle: async ({ params, locals }) => {
		const { error } = await locals.api.POST('/v1/leases/{leaseId}/settlement', {
			params: { path: { leaseId: params.leaseId } }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { settled: true };
	}
};
