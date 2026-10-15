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

/** Signing methods the api accepts (POST /v1/leases/{id}/sign). */
export type SignProvider = 'mock' | 'bankid_sign';

/**
 * The method offered to the user. The api has no endpoint listing the enabled
 * signers yet (contract change requested), so the web offers the one every
 * environment has: a simple electronic signature (click + audit trail), labelled
 * as such. Switch to the api-provided list once it exists.
 */
export const SIGN_PROVIDER: SignProvider = 'mock';

/** What the user is told they are signing with (never "mock"). */
export const signMethodLabel: Record<SignProvider, Label> = {
	mock: m.lease_sign_method_simple,
	bankid_sign: m.lease_sign_method_bankid
};

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
