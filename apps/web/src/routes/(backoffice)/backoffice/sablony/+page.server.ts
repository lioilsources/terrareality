import { errorMessage } from '#lib/errors.js';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const { data, error } = await locals.api.GET('/v1/backoffice/templates');
	return {
		templates: data ?? { version: '', items: [] },
		error: error ? errorMessage(error) : null,
		previewUnavailable: url.searchParams.get('nahled') === 'nedostupny'
	};
};
