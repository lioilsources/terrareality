import { error as kitError } from '@sveltejs/kit';
import { m } from '#lib/paraglide/messages.js';
import { isProblem } from '@terra/contracts';

const byCode: Record<string, () => string> = {
	invalid_credentials: m.err_invalid_credentials,
	invalid_code: m.err_invalid_code,
	invalid_token: m.err_invalid_token,
	email_taken: m.err_email_taken,
	email_not_verified: m.err_email_not_verified,
	password_too_short: m.err_password_too_short,
	password_too_weak: m.err_password_too_weak,
	password_breached: m.err_password_breached,
	rate_limited: m.err_rate_limited,
	validation_failed: m.err_validation_failed,
	mfa_expired: m.err_mfa_expired,
	already_member: m.err_already_member,
	last_owner: m.err_last_owner,
	insufficient_role: m.err_insufficient_role,
	invitation_email_mismatch: m.err_invitation_email_mismatch,
	identity_in_use: m.err_identity_in_use,
	impersonation_forbidden: m.err_impersonation_forbidden,
	provider_unavailable: m.err_provider_unavailable,
	email_required: m.err_email_required,
	reporter_email_required: m.err_reporter_email_required,
	invalid_explanation: m.err_invalid_explanation,
	note_required: m.err_note_required,
	staff_mfa_required: m.err_staff_mfa_required,
	invalid_fields: m.err_invalid_fields,
	listing_locked: m.err_listing_locked,
	demo_listing: m.err_demo_listing,
	unsupported_format: m.err_unsupported_format,
	file_too_large: m.err_file_too_large,
	feature_disabled: m.err_feature_disabled,
	unknown_address: m.err_unknown_address,
	conversation_blocked: m.err_conversation_blocked,
	messaging_suspended: m.err_messaging_suspended,
	prescreen_incomplete: m.err_prescreen_incomplete,
	own_listing: m.err_own_listing,
	attachment_type: m.err_attachment_type,
	attachment_size: m.err_attachment_size,
	attachment_infected: m.err_attachment_infected,
	message_empty: m.err_message_empty,
	already_applied: m.err_already_applied,
	slot_full: m.err_slot_full,
	identity_required: m.err_identity_required,
	invalid_reason: m.err_invalid_reason,
	group_full: m.err_group_full,
	budget_required: m.err_budget_required,
	deposit_too_high: m.err_deposit_too_high,
	invalid_iban: m.err_invalid_iban,
	joint_needs_two: m.err_joint_needs_two,
	end_required: m.err_end_required,
	end_not_allowed: m.err_end_not_allowed,
	lease_locked: m.err_lease_locked,
	already_signed: m.err_already_signed,
	shares_total: m.err_shares_total,
	invalid_provider: m.err_invalid_provider,
	terms_outdated: m.err_terms_outdated,
	not_a_party: m.err_not_a_party,
	lease_not_proposed: m.err_lease_not_proposed,
	lease_not_active: m.err_lease_not_active,
	lease_not_terminated: m.err_lease_not_terminated,
	document_changed: m.err_document_changed,
	party_incomplete: m.err_party_incomplete,
	rent_required: m.err_rent_required,
	tenant_required: m.err_tenant_required,
	payee_required: m.err_payee_required,
	address_required: m.err_address_required,
	comment_required: m.err_comment_required,
	invalid_due_day: m.err_invalid_due_day,
	invalid_term: m.err_invalid_term,
	invalid_clause: m.err_invalid_clause,
	currency_mismatch: m.err_currency_mismatch,
	notice_not_allowed: m.err_notice_not_allowed,
	tenant_only: m.err_tenant_only,
	already_paid: m.err_already_paid,
	share_paid: m.err_share_paid,
	revolut_not_connected: m.err_revolut_not_connected,
	payment_provider_unavailable: m.err_payment_provider_unavailable,
	bank_not_linked: m.err_bank_not_linked,
	bank_unavailable: m.err_bank_unavailable,
	billing_unavailable: m.err_billing_unavailable,
	invitation_expired: m.err_invitation_expired,
	invalid_transition: m.err_invalid_transition,
	application_closed: m.err_application_closed,
	slot_in_past: m.err_slot_in_past,
	message_too_long: m.err_message_too_long,
	account_erased: m.err_account_erased,
	erasure_in_progress: m.err_erasure_in_progress,
	export_not_ready: m.err_export_not_ready,
	mfa_already_enabled: m.err_mfa_already_enabled,
	mfa_not_enabled: m.err_mfa_not_enabled,
	mfa_not_pending: m.err_mfa_not_pending,
	phone_verification_unavailable: m.err_phone_verification_unavailable,
	owner_required: m.err_owner_required,
	promo_code_taken: m.err_promo_code_taken,
	invalid_email: m.err_invalid_email,
	invalid_amount: m.err_invalid_amount,
	group_exists: m.err_group_exists,
	about_too_long: m.err_about_too_long,
	unknown_area: m.err_unknown_area,
	listing_not_published: m.err_listing_not_published,
	impersonation_not_allowed: m.err_impersonation_not_allowed,
	pdf_unavailable: m.err_renderer_unavailable,
	renderer_unavailable: m.err_renderer_unavailable,
	typst_unavailable: m.err_renderer_unavailable,
	redirect_not_allowed: m.err_invalid_redirect,
	invalid_redirect: m.err_invalid_redirect,
	landlord_notice_reason_required: m.err_landlord_notice_reason_required,
	invalid_delivered_on: m.err_invalid_delivered_on,
	email_unverified: m.err_email_unverified,
	listing_already_accepted: m.err_listing_already_accepted,
	invalid_query: m.err_invalid_query,
	notice_reason_not_applicable: m.err_notice_reason_not_applicable,
	invalid_role: m.err_invalid_role,
	income_proof_not_found: m.err_income_proof_not_found,
	application_not_found: m.err_application_not_found
};

/** Fallback by HTTP status when the code is unknown (new api codes, proxies, outages). */
const byStatus: Record<number, () => string> = {
	401: m.err_unauthenticated,
	403: m.err_forbidden,
	404: m.err_not_found,
	409: m.err_conflict,
	413: m.err_file_too_large,
	429: m.err_rate_limited,
	502: m.err_unavailable,
	503: m.err_unavailable,
	504: m.err_unavailable
};

/** Translates an api problem into a user-facing message. */
export function errorMessage(error: unknown): string {
	if (isProblem(error)) {
		if (error.code && byCode[error.code]) return byCode[error.code]();
		if (byStatus[error.status]) return byStatus[error.status]();
	}
	return m.err_generic();
}

/** Problem codes with a translated message (tests check messages exist for api codes). */
export const knownCodes = (): string[] => Object.keys(byCode);

/** A page whose essential data could not be loaded: friendly 503 instead of a 500 + Sentry. */
export function serviceUnavailable(): never {
	kitError(503, m.err_unavailable());
}
