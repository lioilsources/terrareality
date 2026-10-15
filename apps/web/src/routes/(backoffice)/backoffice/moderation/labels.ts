import type { ModerationVerdict } from '@terra/contracts';
import { m } from '#lib/paraglide/messages.js';

export const verdicts: ModerationVerdict[] = ['dismiss', 'warn', 'remove_message', 'suspend_user'];
/** Decisions on DSA listing reports (human only, ADR 0003). */
export const listingVerdicts: ModerationVerdict[] = ['keep', 'unpublish', 'request_change'];

const verdictLabels: Record<ModerationVerdict, () => string> = {
	dismiss: m.bo_verdict_dismiss,
	warn: m.bo_verdict_warn,
	remove_message: m.bo_verdict_remove_message,
	suspend_user: m.bo_verdict_suspend_user,
	keep: m.bo_verdict_keep,
	unpublish: m.bo_verdict_unpublish,
	request_change: m.bo_verdict_request_change
};

const reasonLabels: Record<string, () => string> = {
	scam: m.msg_reason_scam,
	advance_payment: m.msg_reason_advance_payment,
	harassment: m.msg_reason_harassment,
	discrimination: m.msg_reason_discrimination,
	spam: m.msg_reason_spam,
	contact_sharing: m.msg_flag_contact,
	other: m.msg_reason_other,
	illegal_content: m.dsa_reason_illegal_content,
	fraud: m.dsa_reason_fraud,
	wrong_info: m.dsa_reason_wrong_info
};

export const verdictLabel = (v: ModerationVerdict) => verdictLabels[v]();
export const reasonLabel = (r: string) => reasonLabels[r]?.() ?? r;
