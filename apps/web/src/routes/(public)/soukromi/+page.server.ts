import { legalPage } from '#lib/server/legal.js';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = () => ({ doc: legalPage('privacy') });
