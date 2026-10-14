import { m } from '#lib/paraglide/messages.js';

type Label = () => string;

export const statusLabel: Record<string, Label> = {
	pending_consent: m.app_status_pending_consent,
	submitted: m.app_status_submitted,
	invited: m.app_status_invited,
	accepted: m.app_status_accepted,
	rejected: m.app_status_rejected,
	withdrawn: m.app_status_withdrawn
};

/** Reject reasons a landlord can pick (other_applicant_chosen is automatic). */
export const rejectReasons = [
	'income_insufficient',
	'move_in_mismatch',
	'duration_mismatch',
	'incomplete',
	'listing_withdrawn',
	'other'
] as const;

export const reasonLabel: Record<string, Label> = {
	other_applicant_chosen: m.reason_other_applicant_chosen,
	income_insufficient: m.reason_income_insufficient,
	move_in_mismatch: m.reason_move_in_mismatch,
	duration_mismatch: m.reason_duration_mismatch,
	incomplete: m.reason_incomplete,
	listing_withdrawn: m.reason_listing_withdrawn,
	other: m.reason_other
};

export const lifestyle = [
	['non_smoker', m.ls_non_smoker],
	['smoker', m.ls_smoker],
	['pets', m.ls_pets],
	['no_pets', m.ls_no_pets],
	['quiet', m.ls_quiet],
	['social', m.ls_social],
	['early_bird', m.ls_early_bird],
	['night_owl', m.ls_night_owl],
	['works_from_home', m.ls_works_from_home],
	['student', m.ls_student],
	['tidy', m.ls_tidy],
	['vegetarian', m.ls_vegetarian]
] as const;

export const lifestyleLabel: Record<string, Label> = Object.fromEntries(lifestyle);

export const levelLabel: Record<string, Label> = {
	none: m.level_none,
	email: m.level_email,
	phone: m.level_phone,
	identity: m.level_identity
};

export const isirLabel: Record<string, Label> = {
	unchecked: m.isir_unchecked,
	clear: m.isir_clear,
	record: m.isir_record,
	error: m.isir_error
};

export const field = 'rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2';
