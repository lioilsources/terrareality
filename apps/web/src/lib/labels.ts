import { m } from '#lib/paraglide/messages.js';
import type { Role } from '@terra/contracts';

export const roleLabel: Record<Role, () => string> = {
	owner: m.role_owner,
	admin: m.role_admin,
	agent: m.role_agent,
	accountant: m.role_accountant,
	maintenance: m.role_maintenance,
	viewer: m.role_viewer
};

export const levelLabel: Record<string, () => string> = {
	none: m.level_none,
	email: m.level_email,
	phone: m.level_phone,
	identity: m.level_identity
};

export const gdprStatus: Record<string, () => string> = {
	pending: m.gdpr_pending,
	processing: m.gdpr_processing,
	done: m.gdpr_done,
	failed: m.gdpr_failed,
	cancelled: m.gdpr_cancelled,
	rejected: m.gdpr_rejected
};

export const invitableRoles = ['admin', 'agent', 'accountant', 'maintenance', 'viewer'] as const;

export function fmtDate(iso: string, locale: string): string {
	return new Date(iso).toLocaleDateString(locale === 'en' ? 'en-GB' : 'cs-CZ');
}

export function fmtDateTime(iso: string, locale: string): string {
	return new Date(iso).toLocaleString(locale === 'en' ? 'en-GB' : 'cs-CZ', {
		dateStyle: 'short',
		timeStyle: 'short'
	});
}
