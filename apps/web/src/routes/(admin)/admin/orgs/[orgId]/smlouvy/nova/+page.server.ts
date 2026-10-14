import { fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { leaseFromForm } from '#lib/leasing.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ url, locals }) => ({
	applicationId: url.searchParams.get('application') ?? '',
	payeeName: locals.me?.display_name ?? ''
});

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		const { data, error } = await locals.api.POST('/v1/orgs/{orgId}/leases', {
			params: { path: { orgId: params.orgId } },
			body: leaseFromForm(await request.formData())
		});
		if (error) return fail(400, { error: errorMessage(error) });
		redirect(303, localizeHref(`/admin/orgs/${params.orgId}/smlouvy/${data.lease.id}`));
	}
};
