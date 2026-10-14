import type { ModerationVerdict } from '@terra/contracts';
import { m } from '#lib/paraglide/messages.js';

export const verdicts: ModerationVerdict[] = ['dismiss', 'warn', 'remove_message', 'suspend_user'];

const verdictLabels: Record<ModerationVerdict, () => string> = {
	dismiss: m.bo_verdict_dismiss,
	warn: m.bo_verdict_warn,
	remove_message: m.bo_verdict_remove_message,
	suspend_user: m.bo_verdict_suspend_user
};

const reasonLabels: Record<string, () => string> = {
	scam: m.msg_reason_scam,
	advance_payment: m.msg_reason_advance_payment,
	harassment: m.msg_reason_harassment,
	discrimination: m.msg_reason_discrimination,
	spam: m.msg_reason_spam,
	contact_sharing: m.msg_flag_contact,
	other: m.msg_reason_other
};

export const verdictLabel = (v: ModerationVerdict) => verdictLabels[v]();
export const reasonLabel = (r: string) => reasonLabels[r]?.() ?? r;
