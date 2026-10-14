import type { UnitKind } from '@terra/contracts';
import { fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions } from './$types';

const num = (v: FormDataEntryValue | null) => {
	const s = String(v ?? '')
		.replace(',', '.')
		.trim();
	return s === '' || !Number.isFinite(Number(s)) ? undefined : Number(s);
};
const str = (v: FormDataEntryValue | null) => String(v ?? '').trim() || undefined;

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		const f = await request.formData();
		const ruian = Number(f.get('ruian_id'));
		const kind = String(f.get('unit_kind') ?? 'apartment') as UnitKind;
		if (!ruian) return fail(400, { error: 'pick_address' });
		const room = kind === 'room';
		const { data, error } = await locals.api.POST('/v1/orgs/{orgId}/listings', {
			params: { path: { orgId: params.orgId } },
			body: {
				ruian_id: ruian,
				unit_kind: kind,
				unit_label: str(f.get('unit_label')),
				layout: room ? undefined : str(f.get('layout')),
				floor_area: num(f.get('floor_area')),
				floor: num(f.get('floor')),
				parent_layout: room ? str(f.get('parent_layout')) : undefined,
				parent_floor_area: room ? num(f.get('parent_floor_area')) : undefined
			}
		});
		if (!data) return fail(400, { error: errorMessage(error) });
		redirect(303, localizeHref(`/admin/orgs/${params.orgId}/listings/${data.id}?step=attributes`));
	}
};
