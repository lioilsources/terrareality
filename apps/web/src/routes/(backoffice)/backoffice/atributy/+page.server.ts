import { fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const view = url.searchParams.get('stav') === 'rozhodnute' ? 'decided' : 'open';
	const statuses = view === 'open' ? (['open'] as const) : (['approved', 'rejected'] as const);
	const res = await Promise.all(
		statuses.map((status) =>
			locals.api.GET('/v1/backoffice/attribute-suggestions', { params: { query: { status } } })
		)
	);
	const failed = res.find((r) => r.error);
	const items = res
		.flatMap((r) => r.data?.items ?? [])
		.sort((a, b) => (b.decided_at ?? b.created_at).localeCompare(a.decided_at ?? a.created_at));
	return { view, items, error: failed ? errorMessage(failed.error) : null };
};

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const f = await request.formData();
		const note = String(f.get('note') ?? '').trim();
		// Approving only queues the attribute for a catalog change (ADR 0003); nothing is applied here.
		const { error } = await locals.api.POST(
			'/v1/backoffice/attribute-suggestions/{suggestionId}/decision',
			{
				params: { path: { suggestionId: String(f.get('id')) } },
				body: {
					decision: f.get('decision') === 'approve' ? 'approve' : 'reject',
					note: note || undefined
				}
			}
		);
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
