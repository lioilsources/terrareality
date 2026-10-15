import { fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals, url }) => {
	const finish = url.searchParams.get('connection');
	if (finish) {
		// Back from the bank's consent page.
		await locals.api.POST('/v1/orgs/{orgId}/bank/connections/{connectionId}/finish', {
			params: { path: { orgId: params.orgId, connectionId: finish } }
		});
	}
	const { data } = await locals.api.GET('/v1/orgs/{orgId}/bank', {
		params: { path: { orgId: params.orgId } }
	});
	return { bank: data ?? { connections: [], transactions: [] } };
};

const path = (orgId: string) => ({ params: { path: { orgId } } });

export const actions: Actions = {
	connect: async ({ request, params, locals, url }) => {
		const f = await request.formData();
		const { data, error } = await locals.api.POST('/v1/orgs/{orgId}/bank/connections', {
			...path(params.orgId),
			body: {
				institution_id: String(f.get('institution_id') ?? '') || undefined,
				redirect_uri: `${url.origin}${url.pathname}`
			}
		});
		if (error) return fail(400, { error: errorMessage(error) });
		if (data.connection.status !== 'linked' && data.link) {
			redirect(303, data.link);
		}
	},
	sync: async ({ params, locals }) => {
		const { data, error } = await locals.api.POST('/v1/orgs/{orgId}/bank/sync', path(params.orgId));
		if (error) return fail(400, { error: errorMessage(error) });
		return { synced: data };
	},
	match: async ({ request, params, locals }) => {
		const f = await request.formData();
		const ignore = f.get('ignore') === 'true';
		const { error } = await locals.api.POST(
			'/v1/orgs/{orgId}/bank/transactions/{transactionId}/match',
			{
				params: { path: { orgId: params.orgId, transactionId: String(f.get('transaction_id')) } },
				body: ignore ? { ignore: true } : { share_id: String(f.get('share_id')) }
			}
		);
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
