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
	staff_mfa_required: m.err_staff_mfa_required,
	invalid_fields: m.err_invalid_fields,
	listing_locked: m.err_listing_locked,
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
	shares_total: m.err_shares_total
};

/** Translates an api problem into a user-facing message. */
export function errorMessage(error: unknown): string {
	if (isProblem(error) && error.code && byCode[error.code]) return byCode[error.code]();
	return m.err_generic();
}
