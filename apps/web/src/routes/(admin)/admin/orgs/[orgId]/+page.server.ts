import { error as kitError, fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { getLocale } from '#lib/paraglide/runtime.js';
import type { Role } from '@terra/contracts';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const path = { params: { path: { orgId: params.orgId } } };
	const org = await locals.api.GET('/v1/orgs/{orgId}', path);
	if (!org.data) kitError(404);
	const manage = org.data.role === 'owner' || org.data.role === 'admin';
	const [members, invitations, audit] = await Promise.all([
		locals.api.GET('/v1/orgs/{orgId}/members', path),
		manage ? locals.api.GET('/v1/orgs/{orgId}/invitations', path) : Promise.resolve({ data: [] }),
		manage
			? locals.api.GET('/v1/orgs/{orgId}/audit', {
					params: { path: { orgId: params.orgId }, query: { limit: 20 } }
				})
			: Promise.resolve({ data: { items: [] } })
	]);
	return {
		org: org.data,
		manage,
		members: members.data ?? [],
		invitations: invitations.data ?? [],
		audit: audit.data?.items ?? []
	};
};

const path = (orgId: string) => ({ params: { path: { orgId } } });

export const actions: Actions = {
	update: async ({ request, params, locals }) => {
		const f = await request.formData();
		const opt = (k: string) => String(f.get(k) ?? '').trim() || undefined;
		const { error } = await locals.api.PATCH('/v1/orgs/{orgId}', {
			...path(params.orgId),
			body: {
				name: String(f.get('name') ?? ''),
				registration_no: opt('registration_no'),
				vat_no: opt('vat_no')
			}
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { saved: true };
	},
	invite: async ({ request, params, locals }) => {
		const f = await request.formData();
		const email = String(f.get('email') ?? '');
		const { error } = await locals.api.POST('/v1/orgs/{orgId}/invitations', {
			...path(params.orgId),
			body: {
				email,
				role: String(f.get('role')) as 'admin' | 'agent' | 'accountant' | 'maintenance' | 'viewer',
				locale: getLocale() === 'en' ? 'en' : 'cs'
			}
		});
		if (error) return fail(400, { email, inviteError: errorMessage(error) });
		return { invited: true };
	},
	revoke: async ({ request, params, locals }) => {
		const id = String((await request.formData()).get('id') ?? '');
		await locals.api.DELETE('/v1/orgs/{orgId}/invitations/{invitationId}', {
			params: { path: { orgId: params.orgId, invitationId: id } }
		});
	},
	role: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.PATCH('/v1/orgs/{orgId}/members/{userId}', {
			params: { path: { orgId: params.orgId, userId: String(f.get('user_id')) } },
			body: { role: String(f.get('role')) as Role }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	remove: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.DELETE('/v1/orgs/{orgId}/members/{userId}', {
			params: { path: { orgId: params.orgId, userId: String(f.get('user_id')) } }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
