import { error as kitError } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const path = { params: { path: { listingId: params.id } } };
	const [listing, similar, schema] = await Promise.all([
		locals.api.GET('/v1/listings/{listingId}', path),
		locals.api.GET('/v1/listings/{listingId}/similar', path),
		locals.api.GET('/v1/attributes')
	]);
	if (!listing.data) kitError(404);
	return { listing: listing.data, similar: similar.data ?? [], schema: schema.data! };
};
