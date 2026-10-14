//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class BackofficeApi {
  BackofficeApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add the option to the schema or reject it (staff)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] proposalId (required):
  ///
  /// * [ProposalDecision] proposalDecision (required):
  Future<Response> backofficeDecideFilterProposalWithHttpInfo(String proposalId, ProposalDecision proposalDecision,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/filter-proposals/{proposalId}/decision'
      .replaceAll('{proposalId}', proposalId);

    // ignore: prefer_final_locals
    Object? postBody = proposalDecision;

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

  /// Add the option to the schema or reject it (staff)
  ///
  /// Parameters:
  ///
  /// * [String] proposalId (required):
  ///
  /// * [ProposalDecision] proposalDecision (required):
  Future<void> backofficeDecideFilterProposal(String proposalId, ProposalDecision proposalDecision,) async {
    final response = await backofficeDecideFilterProposalWithHttpInfo(proposalId, proposalDecision,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Resolve a case (human decision; the AI verdict is only a suggestion)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] caseId (required):
  ///
  /// * [BackofficeDecideModerationRequest] backofficeDecideModerationRequest (required):
  Future<Response> backofficeDecideModerationWithHttpInfo(String caseId, BackofficeDecideModerationRequest backofficeDecideModerationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/moderation/{caseId}/decision'
      .replaceAll('{caseId}', caseId);

    // ignore: prefer_final_locals
    Object? postBody = backofficeDecideModerationRequest;

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

  /// Resolve a case (human decision; the AI verdict is only a suggestion)
  ///
  /// Parameters:
  ///
  /// * [String] caseId (required):
  ///
  /// * [BackofficeDecideModerationRequest] backofficeDecideModerationRequest (required):
  Future<void> backofficeDecideModeration(String caseId, BackofficeDecideModerationRequest backofficeDecideModerationRequest,) async {
    final response = await backofficeDecideModerationWithHttpInfo(caseId, backofficeDecideModerationRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Approve (publish) or reject a version (staff)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] versionId (required):
  ///
  /// * [ReviewDecision] reviewDecision (required):
  Future<Response> backofficeDecideReviewWithHttpInfo(String versionId, ReviewDecision reviewDecision,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/reviews/{versionId}/decision'
      .replaceAll('{versionId}', versionId);

    // ignore: prefer_final_locals
    Object? postBody = reviewDecision;

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

  /// Approve (publish) or reject a version (staff)
  ///
  /// Parameters:
  ///
  /// * [String] versionId (required):
  ///
  /// * [ReviewDecision] reviewDecision (required):
  Future<void> backofficeDecideReview(String versionId, ReviewDecision reviewDecision,) async {
    final response = await backofficeDecideReviewWithHttpInfo(versionId, reviewDecision,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// A case with the conversation transcript and the AI suggestion
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] caseId (required):
  Future<Response> backofficeGetModerationWithHttpInfo(String caseId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/moderation/{caseId}'
      .replaceAll('{caseId}', caseId);

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

  /// A case with the conversation transcript and the AI suggestion
  ///
  /// Parameters:
  ///
  /// * [String] caseId (required):
  Future<ModerationCaseDetail?> backofficeGetModeration(String caseId,) async {
    final response = await backofficeGetModerationWithHttpInfo(caseId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ModerationCaseDetail',) as ModerationCaseDetail;
    
    }
    return null;
  }

  /// One submitted version with its snapshot (staff)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] versionId (required):
  Future<Response> backofficeGetReviewWithHttpInfo(String versionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/reviews/{versionId}'
      .replaceAll('{versionId}', versionId);

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

  /// One submitted version with its snapshot (staff)
  ///
  /// Parameters:
  ///
  /// * [String] versionId (required):
  Future<ReviewDetail?> backofficeGetReview(String versionId,) async {
    final response = await backofficeGetReviewWithHttpInfo(versionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ReviewDetail',) as ReviewDetail;
    
    }
    return null;
  }

  /// User detail with organizations (staff)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<Response> backofficeGetUserWithHttpInfo(String userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/users/{userId}'
      .replaceAll('{userId}', userId);

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

  /// User detail with organizations (staff)
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<AdminUserDetail?> backofficeGetUser(String userId,) async {
    final response = await backofficeGetUserWithHttpInfo(userId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminUserDetail',) as AdminUserDetail;
    
    }
    return null;
  }

  /// Start a short audited session as the user (staff)
  ///
  /// The session cannot change credentials, MFA or request erasure. Ends with POST /v1/auth/logout.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  ///
  /// * [ImpersonateRequest] impersonateRequest (required):
  Future<Response> backofficeImpersonateWithHttpInfo(String userId, ImpersonateRequest impersonateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/users/{userId}/impersonate'
      .replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody = impersonateRequest;

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

  /// Start a short audited session as the user (staff)
  ///
  /// The session cannot change credentials, MFA or request erasure. Ends with POST /v1/auth/logout.
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  ///
  /// * [ImpersonateRequest] impersonateRequest (required):
  Future<AuthResult?> backofficeImpersonate(String userId, ImpersonateRequest impersonateRequest,) async {
    final response = await backofficeImpersonateWithHttpInfo(userId, impersonateRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthResult',) as AuthResult;
    
    }
    return null;
  }

  /// Platform-wide audit log (staff)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] actorId:
  ///
  /// * [String] orgId:
  ///
  /// * [String] entity:
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<Response> backofficeListAuditWithHttpInfo({ String? actorId, String? orgId, String? entity, String? before, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/audit';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (actorId != null) {
      queryParams.addAll(_queryParams('', 'actor_id', actorId));
    }
    if (orgId != null) {
      queryParams.addAll(_queryParams('', 'org_id', orgId));
    }
    if (entity != null) {
      queryParams.addAll(_queryParams('', 'entity', entity));
    }
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

  /// Platform-wide audit log (staff)
  ///
  /// Parameters:
  ///
  /// * [String] actorId:
  ///
  /// * [String] orgId:
  ///
  /// * [String] entity:
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<AuditPage?> backofficeListAudit({ String? actorId, String? orgId, String? entity, String? before, int? limit, }) async {
    final response = await backofficeListAuditWithHttpInfo( actorId: actorId, orgId: orgId, entity: entity, before: before, limit: limit, );
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

  /// New attribute options proposed by AI ingest (staff)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] status:
  Future<Response> backofficeListFilterProposalsWithHttpInfo({ String? status, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/filter-proposals';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
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

  /// New attribute options proposed by AI ingest (staff)
  ///
  /// Parameters:
  ///
  /// * [String] status:
  Future<List<FilterProposal>?> backofficeListFilterProposals({ String? status, }) async {
    final response = await backofficeListFilterProposalsWithHttpInfo( status: status, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<FilterProposal>') as List)
        .cast<FilterProposal>()
        .toList(growable: false);

    }
    return null;
  }

  /// Open reports and automatic flags, oldest first
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> backofficeListModerationWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/moderation';

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

  /// Open reports and automatic flags, oldest first
  Future<List<ModerationCase>?> backofficeListModeration() async {
    final response = await backofficeListModerationWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<ModerationCase>') as List)
        .cast<ModerationCase>()
        .toList(growable: false);

    }
    return null;
  }

  /// Moderation queue of submitted listing versions (staff)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> backofficeListReviewsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/reviews';

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

  /// Moderation queue of submitted listing versions (staff)
  Future<List<ReviewItem>?> backofficeListReviews() async {
    final response = await backofficeListReviewsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<ReviewItem>') as List)
        .cast<ReviewItem>()
        .toList(growable: false);

    }
    return null;
  }

  /// Search users (staff)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q:
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<Response> backofficeListUsersWithHttpInfo({ String? q, String? before, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/backoffice/users';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }
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

  /// Search users (staff)
  ///
  /// Parameters:
  ///
  /// * [String] q:
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<AdminUserPage?> backofficeListUsers({ String? q, String? before, int? limit, }) async {
    final response = await backofficeListUsersWithHttpInfo( q: q, before: before, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminUserPage',) as AdminUserPage;
    
    }
    return null;
  }
}
