import { error as kitError, fail } from '@sveltejs/kit';
import { errorMessage } from '#lib/errors.js';
import { MESSAGE_PAGE } from '#lib/messaging.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const path = { params: { path: { conversationId: params.id } } };
	const [detail, messages] = await Promise.all([
		locals.api.GET('/v1/conversations/{conversationId}', path),
		locals.api.GET('/v1/conversations/{conversationId}/messages', {
			params: { path: { conversationId: params.id }, query: { limit: MESSAGE_PAGE } }
		})
	]);
	if (!detail.data) kitError(404);
	const c = detail.data.conversation;
	const templates =
		c.role === 'owner'
			? ((
					await locals.api.GET('/v1/orgs/{orgId}/reply-templates', {
						params: { path: { orgId: c.org_id } }
					})
				).data ?? [])
			: [];
	await locals.api.POST('/v1/conversations/{conversationId}/read', path);
	return {
		detail: detail.data,
		messages: (messages.data ?? []).reverse(),
		hasOlder: (messages.data?.length ?? 0) >= MESSAGE_PAGE,
		templates,
		meId: locals.me!.id
	};
};

/** Uploads a file through the presigned URL and returns its attachment id. */
async function upload(locals: App.Locals, conversationId: string, file: File) {
	const { data: slot, error } = await locals.api.POST(
		'/v1/conversations/{conversationId}/attachments',
		{
			params: { path: { conversationId } },
			body: {
				filename: file.name,
				content_type: file.type as 'application/pdf',
				size_bytes: file.size
			}
		}
	);
	if (!slot) return { error };
	const put = await fetch(slot.upload_url, {
		method: 'PUT',
		headers: { 'Content-Type': file.type },
		body: Buffer.from(await file.arrayBuffer())
	});
	if (!put.ok) return { error: { status: put.status, title: 'upload failed' } };
	const done = await locals.api.POST('/v1/attachments/{attachmentId}/complete', {
		params: { path: { attachmentId: slot.id } }
	});
	if (done.error) return { error: done.error };
	return { id: slot.id };
}

export const actions: Actions = {
	send: async ({ request, params, locals }) => {
		const f = await request.formData();
		const body = String(f.get('body') ?? '').trim();
		const file = f.get('file');
		const ids: string[] = [];
		if (file instanceof File && file.size > 0) {
			const up = await upload(locals, params.id, file);
			if (!up.id) return fail(400, { error: errorMessage(up.error), body });
			ids.push(up.id);
		}
		const { data, error } = await locals.api.POST('/v1/conversations/{conversationId}/messages', {
			params: { path: { conversationId: params.id } },
			body: { body, attachment_ids: ids.length ? ids : undefined }
		});
		if (error) return fail(400, { error: errorMessage(error), body });
		return { sent: data.message };
	},
	report: async ({ request, params, locals }) => {
		const f = await request.formData();
		const note = String(f.get('note') ?? '').trim();
		const messageId = String(f.get('message_id') ?? '');
		const { error } = await locals.api.POST('/v1/conversations/{conversationId}/reports', {
			params: { path: { conversationId: params.id } },
			body: {
				reason: String(f.get('reason')) as 'scam',
				note: note || undefined,
				message_id: messageId || undefined
			}
		});
		if (error) return fail(400, { reportError: errorMessage(error) });
		return { reported: true };
	},
	block: async ({ request, params, locals }) => {
		const f = await request.formData();
		const { error } = await locals.api.PUT('/v1/conversations/{conversationId}/block', {
			params: { path: { conversationId: params.id } },
			body: { blocked: f.get('blocked') === 'true' }
		});
		if (error) return fail(400, { error: errorMessage(error) });
	}
};
