/**
 * Locale helpers shared by the UI and the server actions.
 *
 * The web UI is available in 45 languages, but the backend (e-mails, search
 * intent, bilingual catalog text) only knows Czech and English: every other
 * locale uses the English server text.
 */

/** Language of server-side texts (e-mails, bilingual catalog data) for a UI locale. */
export function apiLocale(locale: string): 'cs' | 'en' {
	return locale === 'cs' ? 'cs' : 'en';
}

/** BCP 47 tag for Intl formatting (dates, numbers, money). */
export function intlLocale(locale: string): string {
	if (locale === 'cs') return 'cs-CZ';
	if (locale === 'en') return 'en-GB';
	return locale;
}

/** Language names in their own language, in the order shown in the switcher. */
export const autonyms: Record<string, string> = {
	cs: 'Čeština',
	en: 'English',
	ar: 'العربية',
	bn: 'বাংলা',
	ca: 'Català',
	da: 'Dansk',
	de: 'Deutsch',
	el: 'Ελληνικά',
	es: 'Español',
	fi: 'Suomi',
	fr: 'Français',
	gu: 'ગુજરાતી',
	he: 'עברית',
	hi: 'हिन्दी',
	hr: 'Hrvatski',
	hu: 'Magyar',
	id: 'Bahasa Indonesia',
	it: 'Italiano',
	ja: '日本語',
	kn: 'ಕನ್ನಡ',
	ko: '한국어',
	ml: 'മലയാളം',
	mr: 'मराठी',
	ms: 'Bahasa Melayu',
	nb: 'Norsk bokmål',
	nl: 'Nederlands',
	or: 'ଓଡ଼ିଆ',
	pa: 'ਪੰਜਾਬੀ',
	pl: 'Polski',
	'pt-BR': 'Português (Brasil)',
	'pt-PT': 'Português (Portugal)',
	ro: 'Română',
	ru: 'Русский',
	sk: 'Slovenčina',
	sl: 'Slovenščina',
	sv: 'Svenska',
	ta: 'தமிழ்',
	te: 'తెలుగు',
	th: 'ไทย',
	tr: 'Türkçe',
	uk: 'Українська',
	ur: 'اردو',
	vi: 'Tiếng Việt',
	'zh-Hans': '简体中文',
	'zh-Hant': '繁體中文'
};
