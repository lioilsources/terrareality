/**
 * Typed TerraReality API client. Types come from `schema.d.ts`, which is
 * generated from `openapi.yaml` by `npm run gen` — never edit it by hand.
 */
import createFetchClient, { type Client, type ClientOptions } from 'openapi-fetch';
import type { components, paths } from './schema.d.ts';

export type { components, paths };
export type Schemas = components['schemas'];
export type Health = Schemas['Health'];
export type Version = Schemas['Version'];
export type Problem = Schemas['Problem'];
export type Me = Schemas['Me'];
export type AuthResult = Schemas['AuthResult'];
export type Role = Schemas['Role'];
export type OrgMembership = Schemas['OrgMembership'];
export type Organization = Schemas['Organization'];
export type Member = Schemas['Member'];
export type Invitation = Schemas['Invitation'];
export type InvitationPreview = Schemas['InvitationPreview'];
export type AuditEvent = Schemas['AuditEvent'];
export type GdprRequest = Schemas['GdprRequest'];
export type SessionInfo = Schemas['SessionInfo'];
export type AdminUser = Schemas['AdminUser'];
export type Jurisdiction = Schemas['Jurisdiction'];
export type ApiClient = Client<paths>;

/** Create a client bound to the given API base URL. */
export function createApiClient(baseUrl: string, options: Omit<ClientOptions, 'baseUrl'> = {}): ApiClient {
	return createFetchClient<paths>({ baseUrl, ...options });
}

/** Type guard for RFC 9457 problem responses. */
export function isProblem(value: unknown): value is Problem {
	return (
		typeof value === 'object' &&
		value !== null &&
		'status' in value &&
		'title' in value &&
		typeof (value as Problem).status === 'number'
	);
}
