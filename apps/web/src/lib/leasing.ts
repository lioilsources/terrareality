import type { components } from '@terra/contracts';
import { m } from '#lib/paraglide/messages.js';
import { toMinor } from '#lib/catalog.js';

type Label = () => string;
export type LeaseInput = components['schemas']['LeaseInput'];

export const templates = [
	['spolecny_najem', m.tpl_spolecny_najem],
	['byt_doba_urcita', m.tpl_byt_doba_urcita],
	['byt_doba_neurcita', m.tpl_byt_doba_neurcita],
	['pokoj', m.tpl_pokoj]
] as const;

export const clauses = [
	['pets_allowed', m.clause_pets_allowed],
	['no_smoking', m.clause_no_smoking],
	['inventory', m.clause_inventory],
	['indexation', m.clause_indexation],
	['sublet_forbidden', m.clause_sublet_forbidden],
	['early_termination', m.clause_early_termination]
] as const;

/** A signing method enabled on the server (LeaseDetail.sign_providers, in order of preference). */
export type SignProvider = components['schemas']['SignProvider'];
export type SignProviderId = SignProvider['id'];
const signProviderIds: readonly string[] = ['mock', 'bankid_sign'] satisfies SignProviderId[];

/** What the user is told they are signing with: the legal level, never the provider ("mock"). */
export const signLevelLabel: Record<SignProvider['level'], Label> = {
	simple: m.lease_sign_method_simple,
	qualified: m.lease_sign_method_qualified
};

export const signLevelHint: Record<SignProvider['level'], Label> = {
	simple: m.lease_sign_method_simple_hint,
	qualified: m.lease_sign_method_qualified_hint
};

/** The provider chosen in the sign form; null when missing or not a known provider id. */
export function signProviderFromForm(f: FormData): SignProviderId | null {
	const v = String(f.get('provider') ?? '');
	return signProviderIds.includes(v) ? (v as SignProviderId) : null;
}

export type LandlordNoticeReason = components['schemas']['LandlordNoticeReason'];

/** Statutory reasons of a landlord's notice (§ 2288 OZ) with plain-language labels. */
export const landlordNoticeReasons: readonly (readonly [LandlordNoticeReason, Label])[] = [
	['gross_breach_tenant', m.lease_notice_reason_gross_breach_tenant],
	['conviction', m.lease_notice_reason_conviction],
	['public_interest_vacate', m.lease_notice_reason_public_interest_vacate],
	['other_serious_reason', m.lease_notice_reason_other_serious_reason],
	[
		'flat_needed_for_landlord_or_relative',
		m.lease_notice_reason_flat_needed_for_landlord_or_relative
	]
];

/** Reasons offered for a lease: § 2288(2) applies to indefinite-term leases only. */
export function noticeReasonsFor(endsOn: string | undefined | null) {
	return endsOn
		? landlordNoticeReasons.filter(([r]) => r !== 'flat_needed_for_landlord_or_relative')
		: landlordNoticeReasons;
}

export type LandlordNotice = {
	delivered_on: string;
	reason: LandlordNoticeReason;
	explanation?: string;
};

/**
 * Validates the landlord notice form before it reaches the api (which checks the
 * same rules): a known reason, a delivery date, an explanation for
 * other_serious_reason and the confirmation that the notice is written and
 * informs the tenant of the right to a court review.
 */
export function landlordNoticeFromForm(
	f: FormData
): { notice: LandlordNotice } | { error: string } {
	const reason = String(f.get('reason') ?? '');
	const delivered_on = String(f.get('delivered_on') ?? '').trim();
	const explanation = String(f.get('explanation') ?? '').trim();
	if (!landlordNoticeReasons.some(([r]) => r === reason))
		return { error: m.err_landlord_notice_reason_required() };
	if (!/^\d{4}-\d{2}-\d{2}$/.test(delivered_on))
		return { error: m.lease_notice_delivered_required() };
	if (reason === 'other_serious_reason' && !explanation)
		return { error: m.lease_notice_explanation_required() };
	if (f.get('confirm') !== 'on') return { error: m.lease_notice_landlord_confirm_required() };
	return {
		notice: {
			delivered_on,
			reason: reason as LandlordNoticeReason,
			explanation: explanation || undefined
		}
	};
}

/** Allowed delivery dates (yyyy-mm-dd): 30 days ago to 7 days from today. */
export function deliveredOnRange(now = new Date()) {
	const day = (offset: number) => {
		const d = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate() + offset));
		return d.toISOString().slice(0, 10);
	};
	return { min: day(-30), max: day(7) };
}

export const stateLabel: Record<string, Label> = {
	draft: m.lease_state_draft,
	proposed: m.lease_state_proposed,
	negotiating: m.lease_state_negotiating,
	signed: m.lease_state_signed,
	active: m.lease_state_active,
	notice_given: m.lease_state_notice_given,
	terminated: m.lease_state_terminated,
	settled: m.lease_state_settled,
	cancelled: m.lease_state_cancelled
};

export const roleLabel: Record<string, Label> = {
	landlord: m.role_landlord,
	tenant: m.role_tenant,
	co_tenant: m.role_co_tenant,
	subtenant: m.role_subtenant,
	guarantor: m.role_guarantor
};

export const kindLabel: Record<string, Label> = {
	rent: m.kind_rent,
	deposit: m.kind_deposit,
	services: m.kind_services,
	oneoff: m.kind_oneoff
};

export const matchLabel: Record<string, Label> = {
	unmatched: m.match_unmatched,
	matched: m.match_matched,
	suggested: m.match_suggested,
	ignored: m.match_ignored
};

/** Builds the API body from the lease form. */
export function leaseFromForm(f: FormData): LeaseInput {
	const parties = JSON.parse(String(f.get('parties') || '[]')) as {
		name: string;
		email: string;
		role: string;
		share: number;
	}[];
	return {
		application_id: String(f.get('application_id') ?? '') || undefined,
		template: String(f.get('template')) as LeaseInput['template'],
		starts_on: String(f.get('starts_on')),
		ends_on: String(f.get('ends_on') ?? '') || undefined,
		// "12 500,50" and "12500.5" both parse; an empty or invalid rent is 0, which the api rejects.
		rent_amount: toMinor(f.get('rent')) ?? 0,
		services_amount: toMinor(f.get('services')),
		deposit_amount: toMinor(f.get('deposit')),
		due_day: Number(f.get('due_day') || 15),
		notice_months: Number(f.get('notice_months') || 3),
		payee_iban: String(f.get('payee_iban') ?? ''),
		payee_name: String(f.get('payee_name') ?? ''),
		property_address: String(f.get('property_address') ?? '') || undefined,
		unit_label: String(f.get('unit_label') ?? '') || undefined,
		clauses: f.getAll('clauses').map(String) as LeaseInput['clauses'],
		parties: parties.length
			? parties.map((p) => ({
					name: p.name,
					email: p.email,
					role: p.role as 'co_tenant',
					share_bps: Math.round((p.share || 0) * 100)
				}))
			: undefined
	};
}
