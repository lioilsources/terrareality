import { redirect } from '@sveltejs/kit';
import { localizeHref } from '#lib/paraglide/runtime.js';
import {
	CONSENT_COOKIE,
	CONSENT_MAX_AGE,
	OPTIONAL_CATEGORIES,
	readConsent,
	writeConsent
} from '#lib/consent.js';
import { legalPage } from '#lib/server/legal.js';
import { safeNext, setCookie } from '#lib/server/session.js';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = ({ cookies }) => ({
	doc: legalPage('cookies'),
	consent: readConsent(cookies.get(CONSENT_COOKIE))
});

export const actions: Actions = {
	/** Stores the cookie notice answer (a strictly necessary cookie). */
	consent: async ({ request, cookies }) => {
		const form = await request.formData();
		const categories =
			form.get('all') === '1'
				? [...OPTIONAL_CATEGORIES]
				: form.getAll('category').map((v) => String(v));
		setCookie(cookies, CONSENT_COOKIE, writeConsent(categories), CONSENT_MAX_AGE);
		redirect(303, safeNext(form.get('next')?.toString(), localizeHref('/')));
	}
};
