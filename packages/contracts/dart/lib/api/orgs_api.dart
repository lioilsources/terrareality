//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class OrgsApi {
  OrgsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Accept an invitation; the invitee e-mail must match my account
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<Response> acceptInvitationWithHttpInfo(String token,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/invitations/{token}/accept'
      .replaceAll('{token}', token);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Accept an invitation; the invitee e-mail must match my account
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<OrgMembership?> acceptInvitation(String token,) async {
    final response = await acceptInvitationWithHttpInfo(token,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'OrgMembership',) as OrgMembership;
    
    }
    return null;
  }

  /// Create a company organization; the caller becomes its owner
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [OrgInput] orgInput (required):
  Future<Response> createOrgWithHttpInfo(OrgInput orgInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs';

    // ignore: prefer_final_locals
    Object? postBody = orgInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a company organization; the caller becomes its owner
  ///
  /// Parameters:
  ///
  /// * [OrgInput] orgInput (required):
  Future<OrgMembership?> createOrg(OrgInput orgInput,) async {
    final response = await createOrgWithHttpInfo(orgInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'OrgMembership',) as OrgMembership;
    
    }
    return null;
  }

  /// Invite someone by e-mail (owner, admin)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [InvitationInput] invitationInput (required):
  Future<Response> createOrgInvitationWithHttpInfo(String orgId, InvitationInput invitationInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/invitations'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = invitationInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Invite someone by e-mail (owner, admin)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [InvitationInput] invitationInput (required):
  Future<Invitation?> createOrgInvitation(String orgId, InvitationInput invitationInput,) async {
    final response = await createOrgInvitationWithHttpInfo(orgId, invitationInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Invitation',) as Invitation;
    
    }
    return null;
  }

  /// Preview an invitation before accepting it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<Response> getInvitationWithHttpInfo(String token,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/invitations/{token}'
      .replaceAll('{token}', token);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Preview an invitation before accepting it
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<InvitationPreview?> getInvitation(String token,) async {
    final response = await getInvitationWithHttpInfo(token,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InvitationPreview',) as InvitationPreview;
    
    }
    return null;
  }

  /// One organization and my role in it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> getOrgWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// One organization and my role in it
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<OrgMembership?> getOrg(String orgId,) async {
    final response = await getOrgWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'OrgMembership',) as OrgMembership;
    
    }
    return null;
  }

  /// Organizations I belong to, personal first
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyOrgsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Organizations I belong to, personal first
  Future<List<OrgMembership>?> listMyOrgs() async {
    final response = await listMyOrgsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<OrgMembership>') as List)
        .cast<OrgMembership>()
        .toList(growable: false);

    }
    return null;
  }

  /// Audit log of an organization (owner, admin)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<Response> listOrgAuditWithHttpInfo(String orgId, { String? before, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/audit'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (before != null) {
      queryParams.addAll(_queryParams('', 'before', before));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Audit log of an organization (owner, admin)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<AuditPage?> listOrgAudit(String orgId, { String? before, int? limit, }) async {
    final response = await listOrgAuditWithHttpInfo(orgId,  before: before, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuditPage',) as AuditPage;
    
    }
    return null;
  }

  /// Open invitations
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> listOrgInvitationsWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/invitations'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Open invitations
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<List<Invitation>?> listOrgInvitations(String orgId,) async {
    final response = await listOrgInvitationsWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Invitation>') as List)
        .cast<Invitation>()
        .toList(growable: false);

    }
    return null;
  }

  /// Members of an organization
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> listOrgMembersWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/members'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Members of an organization
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<List<Member>?> listOrgMembers(String orgId,) async {
    final response = await listOrgMembersWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Member>') as List)
        .cast<Member>()
        .toList(growable: false);

    }
    return null;
  }

  /// Remove a member, or leave the organization when userId is me
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] userId (required):
  Future<Response> removeOrgMemberWithHttpInfo(String orgId, String userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/members/{userId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Remove a member, or leave the organization when userId is me
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] userId (required):
  Future<void> removeOrgMember(String orgId, String userId,) async {
    final response = await removeOrgMemberWithHttpInfo(orgId, userId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Revoke an open invitation
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] invitationId (required):
  Future<Response> revokeOrgInvitationWithHttpInfo(String orgId, String invitationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/invitations/{invitationId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{invitationId}', invitationId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Revoke an open invitation
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] invitationId (required):
  Future<void> revokeOrgInvitation(String orgId, String invitationId,) async {
    final response = await revokeOrgInvitationWithHttpInfo(orgId, invitationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Update organization details (owner, admin)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [OrgInput] orgInput (required):
  Future<Response> updateOrgWithHttpInfo(String orgId, OrgInput orgInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = orgInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Update organization details (owner, admin)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [OrgInput] orgInput (required):
  Future<OrgMembership?> updateOrg(String orgId, OrgInput orgInput,) async {
    final response = await updateOrgWithHttpInfo(orgId, orgInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'OrgMembership',) as OrgMembership;
    
    }
    return null;
  }

  /// Change a member's role (owner, admin)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [RoleInput] roleInput (required):
  Future<Response> updateOrgMemberWithHttpInfo(String orgId, String userId, RoleInput roleInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/members/{userId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody = roleInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Change a member's role (owner, admin)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [RoleInput] roleInput (required):
  Future<void> updateOrgMember(String orgId, String userId, RoleInput roleInput,) async {
    final response = await updateOrgMemberWithHttpInfo(orgId, userId, roleInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
