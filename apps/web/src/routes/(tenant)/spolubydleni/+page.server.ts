import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const [profile, matches, regions] = await Promise.all([
		locals.api.GET('/v1/me/roommate-profile'),
		locals.api.GET('/v1/roommates'),
		locals.api.GET('/v1/areas')
	]);
	// Regions first; once a region is chosen its municipalities/districts refine it.
	const path = profile.data?.admin_path ?? '';
	const region = path.split('.').slice(0, 2).join('.');
	const children = region
		? ((await locals.api.GET('/v1/areas', { params: { query: { parent: region } } })).data ?? [])
		: [];
	const option = (a: { path: string; name: string }, depth: number) => ({
		path: a.path,
		name: (depth ? '— ' : '') + a.name
	});
	const areas = (regions.data ?? []).flatMap((r) => [
		option(r, 0),
		...(r.path === region ? children.map((c) => option(c, 1)) : [])
	]);
	return { profile: profile.data ?? null, matches: matches.data ?? [], areas };
};

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const f = await request.formData();
		const budget = Math.round(Number(f.get('budget') ?? 0) * 100);
		const { error } = await locals.api.PUT('/v1/me/roommate-profile', {
			body: {
				active: f.get('active') === 'on',
				admin_path: String(f.get('admin_path') ?? ''),
				budget_max: budget > 0 ? budget : 1,
				move_in: String(f.get('move_in') ?? '') || undefined,
				about: String(f.get('about') ?? ''),
				lifestyle: f.getAll('lifestyle').map(String) as 'quiet'[],
				has_room: f.get('has_room') === 'on'
			}
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { saved: true };
	}
};
