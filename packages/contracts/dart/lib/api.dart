//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/auth_api.dart';
part 'api/backoffice_api.dart';
part 'api/catalog_api.dart';
part 'api/jurisdictions_api.dart';
part 'api/me_api.dart';
part 'api/orgs_api.dart';
part 'api/search_api.dart';
part 'api/system_api.dart';

part 'model/address_suggestion.dart';
part 'model/admin_user.dart';
part 'model/admin_user_detail.dart';
part 'model/admin_user_page.dart';
part 'model/area.dart';
part 'model/area_aggregate.dart';
part 'model/attr_filter.dart';
part 'model/attribute_def.dart';
part 'model/attribute_group.dart';
part 'model/attribute_option.dart';
part 'model/attribute_schema.dart';
part 'model/audit_event.dart';
part 'model/audit_page.dart';
part 'model/auth_provider.dart';
part 'model/auth_result.dart';
part 'model/change_listing_status_request.dart';
part 'model/change_password_request.dart';
part 'model/chat_request.dart';
part 'model/chat_response.dart';
part 'model/client_kind.dart';
part 'model/code_request.dart';
part 'model/consent.dart';
part 'model/consent_input.dart';
part 'model/consent_kind.dart';
part 'model/download_link.dart';
part 'model/facet_count.dart';
part 'model/field_error.dart';
part 'model/filter_proposal.dart';
part 'model/gdpr_request.dart';
part 'model/health.dart';
part 'model/health_check.dart';
part 'model/i18n_text.dart';
part 'model/impersonate_request.dart';
part 'model/invitation.dart';
part 'model/invitation_input.dart';
part 'model/invitation_preview.dart';
part 'model/jurisdiction.dart';
part 'model/listing.dart';
part 'model/listing_address.dart';
part 'model/listing_card.dart';
part 'model/listing_create.dart';
part 'model/listing_status.dart';
part 'model/listing_summary.dart';
part 'model/listing_unit.dart';
part 'model/listing_update.dart';
part 'model/listing_version_info.dart';
part 'model/login_request.dart';
part 'model/magic_link_request.dart';
part 'model/map_point.dart';
part 'model/me.dart';
part 'model/media.dart';
part 'model/media_update.dart';
part 'model/media_upload.dart';
part 'model/media_upload_request.dart';
part 'model/member.dart';
part 'model/mfa_request.dart';
part 'model/municipality_stat.dart';
part 'model/oidc_callback_request.dart';
part 'model/oidc_start.dart';
part 'model/oidc_start_request.dart';
part 'model/org_input.dart';
part 'model/org_membership.dart';
part 'model/organization.dart';
part 'model/password_reset_request.dart';
part 'model/phone_request.dart';
part 'model/photo_variants.dart';
part 'model/place.dart';
part 'model/problem.dart';
part 'model/proposal_decision.dart';
part 'model/public_listing.dart';
part 'model/public_listing_location.dart';
part 'model/public_listing_unit.dart';
part 'model/recovery_codes.dart';
part 'model/register_request.dart';
part 'model/request_suggestion_request.dart';
part 'model/review_decision.dart';
part 'model/review_detail.dart';
part 'model/review_item.dart';
part 'model/role.dart';
part 'model/role_input.dart';
part 'model/saved_search.dart';
part 'model/saved_search_input.dart';
part 'model/search_query.dart';
part 'model/search_result.dart';
part 'model/session_info.dart';
part 'model/session_token.dart';
part 'model/suggestion.dart';
part 'model/suggestion_decision.dart';
part 'model/token_request.dart';
part 'model/totp_setup.dart';
part 'model/unit_kind.dart';
part 'model/update_me_request.dart';
part 'model/user_locale.dart';
part 'model/user_ref.dart';
part 'model/verification_level.dart';
part 'model/verified_identity.dart';
part 'model/version.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
