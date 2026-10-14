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
export type Listing = Schemas['Listing'];
export type ListingSummary = Schemas['ListingSummary'];
export type ListingStatus = Schemas['ListingStatus'];
export type ListingUpdate = Schemas['ListingUpdate'];
export type Media = Schemas['Media'];
export type Suggestion = Schemas['Suggestion'];
export type AttributeSchema = Schemas['AttributeSchema'];
export type AttributeDef = Schemas['AttributeDef'];
export type AddressSuggestion = Schemas['AddressSuggestion'];
export type UnitKind = Schemas['UnitKind'];
export type ReviewItem = Schemas['ReviewItem'];
export type FilterProposal = Schemas['FilterProposal'];
export type FieldError = Schemas['FieldError'];
export type I18nText = Schemas['I18nText'];
export type SearchQuery = Schemas['SearchQuery'];
export type SearchResult = Schemas['SearchResult'];
export type ListingCard = Schemas['ListingCard'];
export type Area = Schemas['Area'];
export type AreaAggregate = Schemas['AreaAggregate'];
export type PublicListing = Schemas['PublicListing'];
export type SavedSearch = Schemas['SavedSearch'];
export type MunicipalityStat = Schemas['MunicipalityStat'];
export type Conversation = Schemas['Conversation'];
export type ConversationDetail = Schemas['ConversationDetail'];
export type Message = Schemas['Message'];
export type MessageFlag = Schemas['MessageFlag'];
export type PrescreenQuestion = Schemas['PrescreenQuestion'];
export type ReplyTemplate = Schemas['ReplyTemplate'];
export type NotificationPreferences = Schemas['NotificationPreferences'];
export type ModerationCase = Schemas['ModerationCase'];
export type ModerationVerdict = Schemas['ModerationVerdict'];
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
