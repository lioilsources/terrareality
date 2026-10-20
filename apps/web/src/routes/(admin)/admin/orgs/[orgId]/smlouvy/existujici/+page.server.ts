import { fail, redirect } from '@sveltejs/kit';
import { isProblem } from '@terra/contracts';
import { errorMessage } from '#lib/errors.js';
import { importErrorField, leaseImportFromForm } from '#lib/leasing.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => ({
	payeeName: locals.me?.display_name ?? ''
});

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		const parsed = leaseImportFromForm(await request.formData());
		if ('error' in parsed) return fail(400, { error: parsed.error, field: parsed.field });
		const { data, error } = await locals.api.POST('/v1/orgs/{orgId}/leases/import', {
			params: { path: { orgId: params.orgId } },
			body: parsed.body
		});
		if (error)
			return fail(400, {
				error: errorMessage(error),
				field: importErrorField(isProblem(error) ? error.code : undefined)
			});
		redirect(303, localizeHref(`/admin/orgs/${params.orgId}/smlouvy/${data.lease.id}`));
	}
};
