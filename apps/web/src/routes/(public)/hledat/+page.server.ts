import { fail, redirect } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
import { paramsFromQuery, queryFromParams } from '#lib/searchParams.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ url, locals }) => {
	const query = queryFromParams(url.searchParams);
	const [result, schema, areas] = await Promise.all([
		locals.api.POST('/v1/search', { body: query }),
		locals.api.GET('/v1/attributes'),
		locals.api.GET('/v1/areas', { params: { query: { parent: query.admin_path ?? '' } } })
	]);
	if (!result.data)
		return {
			error: errorMessage(result.error),
			query,
			result: null,
			schema: schema.data!,
			areas: [],
			reply: null,
			loggedIn: !!locals.me
		};
	return {
		query,
		result: result.data,
		schema: schema.data!,
		areas: areas.data ?? [],
		reply: url.searchParams.get('reply'),
		degraded: url.searchParams.get('degraded') === '1',
		loggedIn: !!locals.me,
		error: null
	};
};

export const actions: Actions = {
	chat: async ({ request, url, locals }) => {
		const message = String((await request.formData()).get('message') ?? '').trim();
		if (!message) return fail(400, { error: '' });
		const current = queryFromParams(url.searchParams);
		const { data, error } = await locals.api.POST('/v1/search/chat', {
			body: { message, query: current, locale: getLocale() === 'en' ? 'en' : 'cs' }
		});
		if (!data) return fail(400, { error: errorMessage(error) });
		const p = paramsFromQuery(data.query);
		p.set('reply', data.reply);
		if (data.degraded) p.set('degraded', '1');
		redirect(303, localizeHref(`/hledat?${p}`));
	},
	save: async ({ request, url, locals }) => {
		if (!locals.me)
			redirect(303, localizeHref(`/login?next=${encodeURIComponent(url.pathname + url.search)}`));
		const name = String((await request.formData()).get('name') ?? '').trim() || 'Hledání';
		const query = queryFromParams(url.searchParams);
		delete query.offset;
		delete query.limit;
		const { error } = await locals.api.POST('/v1/me/saved-searches', {
			body: { name, query, notify: true }
		});
		if (error) return fail(400, { error: errorMessage(error) });
		return { saved: true };
	}
};
