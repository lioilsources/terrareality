import type { components } from '@terra/contracts';
import { m } from '#lib/paraglide/messages.js';
import { formatMoney } from '#lib/catalog.js';

export type RiskFactor = components['schemas']['RiskFactor'];
export type RiskBand = components['schemas']['RiskBand'];

export const bandLabel: Record<RiskBand, () => string> = {
	low: m.pf_band_low,
	medium: m.pf_band_medium,
	high: m.pf_band_high
};

/** Tailwind classes of a risk band (light and dark theme). */
export const bandClass: Record<RiskBand, string> = {
	low: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-200',
	medium: 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-200',
	high: 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-200'
};

export const bandColor: Record<RiskBand, string> = {
	low: '#10b981',
	medium: '#f59e0b',
	high: '#ef4444'
};

export const attentionLabel: Record<string, () => string> = {
	escalation: m.pf_kind_escalation,
	debt: m.pf_kind_debt,
	ending: m.pf_kind_ending,
	notice: m.pf_kind_notice,
	vacant: m.pf_kind_vacant,
	high_risk: m.pf_kind_high_risk
};

export const factorLabel: Record<string, () => string> = {
	debt: m.risk_factor_debt,
	escalations: m.risk_factor_escalations,
	overdue_days: m.risk_factor_overdue_days,
	deposit_coverage: m.risk_factor_deposit_coverage,
	passport: m.risk_factor_passport,
	term_end: m.risk_factor_term_end,
	notice: m.risk_factor_notice,
	joint_nonpayer: m.risk_factor_joint_nonpayer,
	market_rent: m.risk_factor_market_rent,
	market_supply: m.risk_factor_market_supply
};

/** Money in major units with the currency sign ("12 500 Kč"). */
export function kc(minor: number | undefined, locale: string): string {
	return `${formatMoney(minor ?? 0, locale)} Kč`;
}

export function pct(share: number): string {
	return String(Math.round(share * 100));
}

/** Human explanation of a factor's detail (the numbers behind the value). */
export function factorDetail(f: RiskFactor, locale: string): string {
	const d = (f.detail ?? {}) as Record<string, number | boolean>;
	const n = (k: string) => Number(d[k] ?? 0);
	switch (f.key) {
		case 'debt':
			return m.risk_detail_debt({
				amount: kc(n('amount'), locale),
				monthly: kc(n('monthly'), locale)
			});
		case 'escalations':
			return m.risk_detail_escalations({ count: n('count') });
		case 'overdue_days':
			return m.risk_detail_overdue_days({ days: n('days') });
		case 'deposit_coverage':
			return m.risk_detail_deposit_coverage({
				paid: kc(n('deposit_paid'), locale),
				deposit: kc(n('deposit'), locale),
				uncovered: kc(n('uncovered'), locale)
			});
		case 'passport':
			return f.known
				? m.risk_detail_passport({
						identity: n('identity'),
						income: n('income_proof'),
						records: n('insolvency_records'),
						tenants: n('tenants')
					})
				: m.risk_unknown();
		case 'term_end':
			return d.indefinite
				? m.risk_detail_term_indefinite()
				: m.risk_detail_term_end({ days: n('days_left') });
		case 'joint_nonpayer':
			return m.risk_detail_joint({ paying: n('paying'), behind: n('behind') });
		case 'market_rent':
			return f.known
				? m.risk_detail_market_rent({
						ratio: n('ratio').toLocaleString(locale === 'en' ? 'en-GB' : 'cs-CZ'),
						median: kc(n('median'), locale),
						listings: n('listings')
					})
				: m.risk_unknown();
		case 'market_supply':
			return f.known
				? m.risk_detail_market_supply({ days: n('avg_days'), listings: n('listings') })
				: m.risk_unknown();
		default:
			return m.risk_detail_none();
	}
}
