import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { getRentRoll } from '#lib/server/portfolio.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const path = { params: { path: { orgId: params.orgId } } };
	const [groups, rules, weights, roll] = await Promise.all([
		locals.api.GET('/v1/orgs/{orgId}/portfolio/groups', path),
		locals.api.GET('/v1/orgs/{orgId}/portfolio/rules', path),
		locals.api.GET('/v1/orgs/{orgId}/portfolio/risk-weights', path),
		getRentRoll(locals.api, params.orgId)
	]);
	return {
		groups: groups.data ?? { groups: [], properties: [] },
		rules: rules.data ?? null,
		weights: weights.data ?? null,
		leases: (roll.data?.rows ?? [])
			.filter((r) => r.lease_id)
			.map((r) => ({ id: r.lease_id!, label: `${r.address}${r.unit ? `, ${r.unit}` : ''}` })),
		role: roll.data?.role ?? 'viewer',
		error: groups.error ? errorMessage(groups.error) : null
	};
};

const num = (v: FormDataEntryValue | null) => (v === null || v === '' ? undefined : Number(v));

export const actions: Actions = {
	saveGroup: async ({ request, params, locals }) => {
		const f = await request.formData();
		const id = String(f.get('id') ?? '');
		const body = {
			name: String(f.get('name') ?? ''),
			color: String(f.get('color') ?? '#64748b'),
			property_ids: f.getAll('property_ids').map(String),
			lease_ids: f.getAll('lease_ids').map(String)
		};
		const { error } = id
			? await locals.api.PUT('/v1/orgs/{orgId}/portfolio/groups/{portfolioGroupId}', {
					params: { path: { orgId: params.orgId, portfolioGroupId: id } },
					body
				})
			: await locals.api.POST('/v1/orgs/{orgId}/portfolio/groups', {
					params: { path: { orgId: params.orgId } },
					body
				});
		if (error) return fail(400, { error: errorMessage(error) });
		return { saved: 'group' };
	},
	deleteGroup: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.DELETE(
			'/v1/orgs/{orgId}/portfolio/groups/{portfolioGroupId}',
			{
				params: { path: { orgId: params.orgId, portfolioGroupId: String(f.get('id')) } }
			}
		);
		if (error) return fail(400, { error: errorMessage(error) });
	},
	saveRule: async ({ request, params, locals }) => {
		const f = await request.formData();
		const scope = String(f.get('scope'));
		const { error } = await locals.api.PUT('/v1/orgs/{orgId}/portfolio/rules', {
			params: { path: { orgId: params.orgId } },
			body: {
				municipality: scope === 'municipality' ? String(f.get('municipality')) : undefined,
				group_id: scope === 'group' ? String(f.get('group_id')) : undefined,
				rules: {
					reminder_before_days: num(f.get('reminder_before_days')),
					overdue_days: num(f.get('overdue_days')),
					escalation_days: num(f.get('escalation_days')),
					deposit_months: num(f.get('deposit_months')),
					notice_months: num(f.get('notice_months'))
				}
			}
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { saved: 'rule' };
	},
	deleteRule: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.DELETE('/v1/orgs/{orgId}/portfolio/rules/{ruleId}', {
			params: { path: { orgId: params.orgId, ruleId: String(f.get('id')) } }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	saveWeights: async ({ request, params, locals }) => {
		const f = await request.formData();
		const weights: Record<string, number> = {};
		for (const [k, v] of f.entries()) weights[k] = Number(v);
		const { error } = await locals.api.PUT('/v1/orgs/{orgId}/portfolio/risk-weights', {
			params: { path: { orgId: params.orgId } },
			body: { weights }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { saved: 'weights' };
	}
};
