import { fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions } from './$types';

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const f = await request.formData();
		const opt = (k: string) => String(f.get(k) ?? '').trim() || undefined;
		const name = String(f.get('name') ?? '').trim();
		const { data, error } = await locals.api.POST('/v1/orgs', {
			body: { name, registration_no: opt('registration_no'), vat_no: opt('vat_no') }
		});
		if (!data) return fail(400, { name, error: errorMessage(error) });
		redirect(303, localizeHref(`/admin/orgs/${data.organization.id}`));
	}
};
