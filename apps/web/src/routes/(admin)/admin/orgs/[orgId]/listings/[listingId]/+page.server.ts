import type { Listing, ListingUpdate } from '@terra/contracts';
import { error as kitError, fail, redirect } from '@sveltejs/kit';
import { applicable, attributesFromForm, toMinor } from '#lib/catalog.js';
import { errorMessage, serviceUnavailable } from '#lib/errors.js';
import { localizeHref } from '#lib/paraglide/runtime.js';
import type { Actions, PageServerLoad } from './$types';

const steps = ['attributes', 'photos', 'text', 'preview'] as const;

export const load: PageServerLoad = async ({ params, locals, url }) => {
	const path = { params: { path: { orgId: params.orgId, listingId: params.listingId } } };
	const [listing, schema] = await Promise.all([
		locals.api.GET('/v1/orgs/{orgId}/listings/{listingId}', path),
		locals.api.GET('/v1/attributes')
	]);
	if (!listing.data) kitError(404);
	if (!schema.data) serviceUnavailable();
	const s = url.searchParams.get('step');
	const step = steps.includes(s as (typeof steps)[number]) ? s! : 'attributes';
	return { listing: listing.data, schema: schema.data, step, steps: [...steps] };
};

type Api = App.Locals['api'];

async function current(api: Api, orgId: string, listingId: string): Promise<Listing> {
	const { data } = await api.GET('/v1/orgs/{orgId}/listings/{listingId}', {
		params: { path: { orgId, listingId } }
	});
	if (!data) kitError(404);
	return data;
}

function baseUpdate(l: Listing): ListingUpdate {
	return {
		title: l.title,
		description: l.description,
		rent_amount: l.rent_amount,
		deposit_amount: l.deposit_amount,
		utilities_amount: l.utilities_amount,
		available_from: l.available_from,
		min_term_months: l.min_term_months,
		attributes: l.attributes,
		location_precision: l.location_precision
	};
}

async function put(api: Api, orgId: string, listingId: string, body: ListingUpdate) {
	return api.PUT('/v1/orgs/{orgId}/listings/{listingId}', {
		params: { path: { orgId, listingId } },
		body
	});
}

export const actions: Actions = {
	attributes: async ({ request, params, locals }) => {
		const f = await request.formData();
		const [l, schema] = await Promise.all([
			current(locals.api, params.orgId, params.listingId),
			locals.api.GET('/v1/attributes')
		]);
		if (!schema.data) return fail(503, { error: errorMessage(schema.error) });
		const defs = applicable(schema.data, l.unit.kind);
		const minTerm = String(f.get('min_term_months') ?? '').trim();
		const body: ListingUpdate = {
			...baseUpdate(l),
			rent_amount: toMinor(f.get('rent')),
			deposit_amount: toMinor(f.get('deposit')),
			utilities_amount: toMinor(f.get('utilities')),
			available_from: String(f.get('available_from') ?? '') || undefined,
			min_term_months: minTerm ? Number(minTerm) : undefined,
			location_precision: f.get('location_precision') === 'exact' ? 'exact' : 'approximate',
			attributes: attributesFromForm(f, defs)
		};
		const { error } = await put(locals.api, params.orgId, params.listingId, body);
		if (error) return fail(400, { error: errorMessage(error), fieldErrors: error.errors });
		return { saved: true };
	},
	text: async ({ request, params, locals }) => {
		const f = await request.formData();
		const l = await current(locals.api, params.orgId, params.listingId);
		const s = (k: string) => String(f.get(k) ?? '').trim();
		const { error } = await put(locals.api, params.orgId, params.listingId, {
			...baseUpdate(l),
			title: { cs: s('title_cs'), en: s('title_en') },
			description: { cs: s('description_cs'), en: s('description_en') }
		});
		if (error) return fail(400, { error: errorMessage(error), fieldErrors: error.errors });
		return { saved: true };
	},
	suggest: async ({ request, params, locals }) => {
		const kind = (await request.formData()).get('kind') === 'text' ? 'text' : 'attributes';
		const { error } = await locals.api.POST('/v1/orgs/{orgId}/listings/{listingId}/suggestions', {
			params: { path: { orgId: params.orgId, listingId: params.listingId } },
			body: { kind }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	decide: async ({ request, params, locals }) => {
		const f = await request.formData();
		const keys = f.getAll('key').map(String);
		const accept = f.get('accept') === 'true';
		const { error } = await locals.api.POST(
			'/v1/orgs/{orgId}/suggestions/{suggestionId}/decision',
			{
				params: { path: { orgId: params.orgId, suggestionId: String(f.get('id')) } },
				body: { accept, keys: f.get('partial') === 'true' ? keys : undefined }
			}
		);
		if (error) return fail(400, { error: errorMessage(error), fieldErrors: error.errors });
	},
	upload: async ({ request, params, locals, fetch }) => {
		const files = (await request.formData())
			.getAll('photos')
			.filter((x): x is File => x instanceof File && x.size > 0);
		for (const file of files) {
			const { data, error } = await locals.api.POST('/v1/orgs/{orgId}/listings/{listingId}/media', {
				params: { path: { orgId: params.orgId, listingId: params.listingId } },
				body: {
					filename: file.name,
					content_type: file.type as 'image/jpeg' | 'image/png' | 'image/webp',
					size: file.size
				}
			});
			if (!data) return fail(400, { error: errorMessage(error) });
			// The browser never talks to object storage; this server streams the file there.
			const res = await fetch(data.upload_url, {
				method: 'PUT',
				body: await file.arrayBuffer(),
				headers: { 'Content-Type': file.type }
			});
			if (!res.ok) return fail(502, { error: `upload failed (${res.status})` });
			await locals.api.POST('/v1/orgs/{orgId}/media/{mediaId}/complete', {
				params: { path: { orgId: params.orgId, mediaId: data.media.id } }
			});
		}
	},
	movePhoto: async ({ request, params, locals }) => {
		const f = await request.formData();
		const l = await current(locals.api, params.orgId, params.listingId);
		const order = l.media.map((x) => x.id);
		const id = String(f.get('id'));
		const i = order.indexOf(id);
		const j = i + (f.get('dir') === 'left' ? -1 : 1);
		if (i < 0 || j < 0 || j >= order.length) return;
		[order[i], order[j]] = [order[j], order[i]];
		await Promise.all(
			order.map((mid, position) => {
				const media = l.media.find((x) => x.id === mid)!;
				return locals.api.PATCH('/v1/orgs/{orgId}/media/{mediaId}', {
					params: { path: { orgId: params.orgId, mediaId: mid } },
					body: { position, caption: media.caption }
				});
			})
		);
	},
	deletePhoto: async ({ request, params, locals }) => {
		const id = String((await request.formData()).get('id'));
		await locals.api.DELETE('/v1/orgs/{orgId}/media/{mediaId}', {
			params: { path: { orgId: params.orgId, mediaId: id } }
		});
	},
	submit: async ({ params, locals }) => {
		const { error } = await locals.api.POST('/v1/orgs/{orgId}/listings/{listingId}/submit', {
			params: { path: { orgId: params.orgId, listingId: params.listingId } }
		});
		if (error) return fail(400, { error: errorMessage(error), fieldErrors: error.errors });
		return { submitted: true };
	},
	status: async ({ request, params, locals }) => {
		const status = String((await request.formData()).get('status')) as
			'published' | 'paused' | 'rented' | 'archived';
		const { error } = await locals.api.POST('/v1/orgs/{orgId}/listings/{listingId}/status', {
			params: { path: { orgId: params.orgId, listingId: params.listingId } },
			body: { status }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	},
	duplicate: async ({ params, locals }) => {
		const { data, error } = await locals.api.POST(
			'/v1/orgs/{orgId}/listings/{listingId}/duplicate',
			{
				params: { path: { orgId: params.orgId, listingId: params.listingId } }
			}
		);
		if (!data) return fail(400, { error: errorMessage(error) });
		redirect(303, localizeHref(`/admin/orgs/${params.orgId}/listings/${data.id}?step=attributes`));
	}
};
