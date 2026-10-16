import type { AttributeDef, AttributeSchema, I18nText, UnitKind } from '@terra/contracts';
import { m } from '#lib/paraglide/messages.js';

export const statusLabel: Record<string, () => string> = {
	draft: m.status_draft,
	review: m.status_review,
	published: m.status_published,
	paused: m.status_paused,
	rented: m.status_rented,
	archived: m.status_archived
};

export const kindLabel: Record<string, () => string> = {
	apartment: m.kind_apartment,
	house: m.kind_house,
	room: m.kind_room,
	parking: m.kind_parking,
	storage: m.kind_storage,
	commercial: m.kind_commercial
};

export const versionLabel: Record<string, () => string> = {
	pending: m.version_pending,
	approved: m.version_approved,
	rejected: m.version_rejected,
	withdrawn: m.version_withdrawn
};

export const layouts = [
	'1+kk',
	'1+1',
	'2+kk',
	'2+1',
	'3+kk',
	'3+1',
	'4+kk',
	'4+1',
	'5+kk',
	'5+1',
	'6+'
];

/** Text in the current locale with fallback to Czech. */
export function t(text: I18nText | undefined, locale: string): string {
	if (!text) return '';
	return (locale === 'en' ? text.en : text.cs) || text.cs || text.en || '';
}

/** Minor units (haléře) to whole crowns. */
export function crowns(minor: number | undefined | null): string {
	if (minor === undefined || minor === null) return '';
	return String(Math.round(minor / 100));
}

/** Whole crowns from a form field to minor units. */
export function toMinor(value: FormDataEntryValue | null): number | undefined {
	const s = String(value ?? '')
		.replace(/\s/g, '')
		.replace(',', '.');
	if (!s) return undefined;
	const n = Number(s);
	return Number.isFinite(n) && n >= 0 ? Math.round(n * 100) : undefined;
}

/**
 * Money from minor units with its currency sign via Intl ("12 500 Kč", "€1,250.50").
 * Whole amounts drop the fraction; anything else keeps two decimals. The currency
 * comes from the api (`currency` next to every amount); CZK only when the api has
 * none (roommate budgets, risk details).
 */
export function formatMoney(
	minor: number | undefined | null,
	currency: string | undefined | null,
	locale: string
): string {
	if (minor === undefined || minor === null) return '';
	const whole = minor % 100 === 0;
	return new Intl.NumberFormat(locale === 'en' ? 'en-GB' : 'cs-CZ', {
		style: 'currency',
		currency: currency || 'CZK',
		currencyDisplay: 'narrowSymbol',
		minimumFractionDigits: whole ? 0 : 2,
		maximumFractionDigits: whole ? 0 : 2
	}).format(minor / 100);
}

/**
 * Stand-in when /v1/attributes is unavailable: public pages (search, listing
 * detail) still render, just without attribute labels and facets.
 */
export const EMPTY_SCHEMA: AttributeSchema = { groups: [], attributes: [] };

export function applicable(schema: AttributeSchema, kind: UnitKind): AttributeDef[] {
	return schema.attributes.filter((a) => a.applies_to.length === 0 || a.applies_to.includes(kind));
}

/** Human-readable value of an attribute. */
export function valueLabel(a: AttributeDef | undefined, v: unknown, locale: string): string {
	if (!a) return String(v);
	const opt = (val: string) => t(a.options.find((o) => o.value === val)?.label, locale) || val;
	if (typeof v === 'boolean') return v ? m.yes() : m.no();
	if (typeof v === 'number') return a.unit ? `${v} ${a.unit.replace('m2', 'm²')}` : String(v);
	if (typeof v === 'string') return opt(v);
	if (Array.isArray(v)) return v.map((x) => opt(String(x))).join(', ');
	return '';
}

/** Reads the attribute inputs of the editor form ("attr.<key>"). */
export function attributesFromForm(f: FormData, defs: AttributeDef[]): Record<string, unknown> {
	const out: Record<string, unknown> = {};
	for (const a of defs) {
		const name = `attr.${a.key}`;
		switch (a.type) {
			case 'bool': {
				const v = f.get(name);
				if (v === 'true') out[a.key] = true;
				else if (v === 'false') out[a.key] = false;
				break;
			}
			case 'int':
			case 'range': {
				const v = String(f.get(name) ?? '').replace(',', '.');
				if (v !== '' && Number.isFinite(Number(v))) out[a.key] = Number(v);
				break;
			}
			case 'enum': {
				const v = String(f.get(name) ?? '');
				if (v) out[a.key] = v;
				break;
			}
			case 'set': {
				const v = f.getAll(name).map(String);
				if (v.length) out[a.key] = v;
				break;
			}
			case 'text': {
				const v = String(f.get(name) ?? '').trim();
				if (v) out[a.key] = v;
				break;
			}
		}
	}
	return out;
}
