//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ApplicationsApi {
  ApplicationsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Book a viewing slot (replaces an earlier booking of this application)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] applicationId (required):
  ///
  /// * [BookViewingRequest] bookViewingRequest (required):
  Future<Response> bookViewingWithHttpInfo(String applicationId, BookViewingRequest bookViewingRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/applications/{applicationId}/bookings'
      .replaceAll('{applicationId}', applicationId);

    // ignore: prefer_final_locals
    Object? postBody = bookViewingRequest;

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

  /// Book a viewing slot (replaces an earlier booking of this application)
  ///
  /// Parameters:
  ///
  /// * [String] applicationId (required):
  ///
  /// * [BookViewingRequest] bookViewingRequest (required):
  Future<ReportConversation201Response?> bookViewing(String applicationId, BookViewingRequest bookViewingRequest,) async {
    final response = await bookViewingWithHttpInfo(applicationId, bookViewingRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ReportConversation201Response',) as ReportConversation201Response;
    
    }
    return null;
  }

  /// Cancel a booked viewing
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] bookingId (required):
  Future<Response> cancelViewingWithHttpInfo(String bookingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/viewing-bookings/{bookingId}'
      .replaceAll('{bookingId}', bookingId);

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

  /// Cancel a booked viewing
  ///
  /// Parameters:
  ///
  /// * [String] bookingId (required):
  Future<void> cancelViewing(String bookingId,) async {
    final response = await cancelViewingWithHttpInfo(bookingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Check the insolvency register (needs a verified identity; once a day)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> checkInsolvencyWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/passport/insolvency-check';

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

  /// Check the insolvency register (needs a verified identity; once a day)
  Future<Passport?> checkInsolvency() async {
    final response = await checkInsolvencyWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Passport',) as Passport;
    
    }
    return null;
  }

  /// Check the uploaded income proof and attach it to the passport
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CompleteIncomeUploadRequest] completeIncomeUploadRequest (required):
  Future<Response> completeIncomeUploadWithHttpInfo(CompleteIncomeUploadRequest completeIncomeUploadRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/passport/income/complete';

    // ignore: prefer_final_locals
    Object? postBody = completeIncomeUploadRequest;

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

  /// Check the uploaded income proof and attach it to the passport
  ///
  /// Parameters:
  ///
  /// * [CompleteIncomeUploadRequest] completeIncomeUploadRequest (required):
  Future<Passport?> completeIncomeUpload(CompleteIncomeUploadRequest completeIncomeUploadRequest,) async {
    final response = await completeIncomeUploadWithHttpInfo(completeIncomeUploadRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Passport',) as Passport;
    
    }
    return null;
  }

  /// Consent to a group application; the last consent submits it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] applicationId (required):
  Future<Response> consentApplicationWithHttpInfo(String applicationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/applications/{applicationId}/consent'
      .replaceAll('{applicationId}', applicationId);

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

  /// Consent to a group application; the last consent submits it
  ///
  /// Parameters:
  ///
  /// * [String] applicationId (required):
  Future<void> consentApplication(String applicationId,) async {
    final response = await consentApplicationWithHttpInfo(applicationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Apply for a listing, alone or as a group (a group application waits for every member's consent)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ApplicationInput] applicationInput (required):
  Future<Response> createApplicationWithHttpInfo(ApplicationInput applicationInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/applications';

    // ignore: prefer_final_locals
    Object? postBody = applicationInput;

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

  /// Apply for a listing, alone or as a group (a group application waits for every member's consent)
  ///
  /// Parameters:
  ///
  /// * [ApplicationInput] applicationInput (required):
  Future<ApplicationDetail?> createApplication(ApplicationInput applicationInput,) async {
    final response = await createApplicationWithHttpInfo(applicationInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApplicationDetail',) as ApplicationDetail;
    
    }
    return null;
  }

  /// Create a tenant group and invite flatmates by e-mail
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateGroupRequest] createGroupRequest (required):
  Future<Response> createGroupWithHttpInfo(CreateGroupRequest createGroupRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/groups';

    // ignore: prefer_final_locals
    Object? postBody = createGroupRequest;

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

  /// Create a tenant group and invite flatmates by e-mail
  ///
  /// Parameters:
  ///
  /// * [CreateGroupRequest] createGroupRequest (required):
  Future<Group?> createGroup(CreateGroupRequest createGroupRequest,) async {
    final response = await createGroupWithHttpInfo(createGroupRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Group',) as Group;
    
    }
    return null;
  }

  /// Reserve an upload for an income proof (PUT the file, then complete)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateIncomeUploadRequest] createIncomeUploadRequest (required):
  Future<Response> createIncomeUploadWithHttpInfo(CreateIncomeUploadRequest createIncomeUploadRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/passport/income';

    // ignore: prefer_final_locals
    Object? postBody = createIncomeUploadRequest;

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

  /// Reserve an upload for an income proof (PUT the file, then complete)
  ///
  /// Parameters:
  ///
  /// * [CreateIncomeUploadRequest] createIncomeUploadRequest (required):
  Future<CreateIncomeUpload201Response?> createIncomeUpload(CreateIncomeUploadRequest createIncomeUploadRequest,) async {
    final response = await createIncomeUploadWithHttpInfo(createIncomeUploadRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CreateIncomeUpload201Response',) as CreateIncomeUpload201Response;
    
    }
    return null;
  }

  /// Offer a viewing slot
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [CreateViewingSlotRequest] createViewingSlotRequest (required):
  Future<Response> createViewingSlotWithHttpInfo(String orgId, String listingId, CreateViewingSlotRequest createViewingSlotRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/viewing-slots'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

    // ignore: prefer_final_locals
    Object? postBody = createViewingSlotRequest;

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

  /// Offer a viewing slot
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [CreateViewingSlotRequest] createViewingSlotRequest (required):
  Future<ViewingSlot?> createViewingSlot(String orgId, String listingId, CreateViewingSlotRequest createViewingSlotRequest,) async {
    final response = await createViewingSlotWithHttpInfo(orgId, listingId, createViewingSlotRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ViewingSlot',) as ViewingSlot;
    
    }
    return null;
  }

  /// Invite to a viewing, accept (other applicants get an automatic answer) or reject with a reason code
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] applicationId (required):
  ///
  /// * [DecideApplicationRequest] decideApplicationRequest (required):
  Future<Response> decideApplicationWithHttpInfo(String orgId, String applicationId, DecideApplicationRequest decideApplicationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/applications/{applicationId}/decision'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{applicationId}', applicationId);

    // ignore: prefer_final_locals
    Object? postBody = decideApplicationRequest;

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

  /// Invite to a viewing, accept (other applicants get an automatic answer) or reject with a reason code
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] applicationId (required):
  ///
  /// * [DecideApplicationRequest] decideApplicationRequest (required):
  Future<void> decideApplication(String orgId, String applicationId, DecideApplicationRequest decideApplicationRequest,) async {
    final response = await decideApplicationWithHttpInfo(orgId, applicationId, decideApplicationRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Remove my income proof
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> deleteIncomeProofWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/passport/income';

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

  /// Remove my income proof
  Future<void> deleteIncomeProof() async {
    final response = await deleteIncomeProofWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Remove a slot (its bookings are cancelled)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] slotId (required):
  Future<Response> deleteViewingSlotWithHttpInfo(String orgId, String slotId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/viewing-slots/{slotId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{slotId}', slotId);

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

  /// Remove a slot (its bookings are cancelled)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] slotId (required):
  Future<void> deleteViewingSlot(String orgId, String slotId,) async {
    final response = await deleteViewingSlotWithHttpInfo(orgId, slotId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Application with consents, bookable viewing slots and my booking
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] applicationId (required):
  Future<Response> getApplicationWithHttpInfo(String applicationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/applications/{applicationId}'
      .replaceAll('{applicationId}', applicationId);

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

  /// Application with consents, bookable viewing slots and my booking
  ///
  /// Parameters:
  ///
  /// * [String] applicationId (required):
  Future<ApplicationDetail?> getApplication(String applicationId,) async {
    final response = await getApplicationWithHttpInfo(applicationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApplicationDetail',) as ApplicationDetail;
    
    }
    return null;
  }

  /// Group with members and chat (chat only for joined members)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  Future<Response> getGroupWithHttpInfo(String groupId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/groups/{groupId}'
      .replaceAll('{groupId}', groupId);

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

  /// Group with members and chat (chat only for joined members)
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  Future<Group?> getGroup(String groupId,) async {
    final response = await getGroupWithHttpInfo(groupId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Group',) as Group;
    
    }
    return null;
  }

  /// My Tenant Passport
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getPassportWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/passport';

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

  /// My Tenant Passport
  Future<Passport?> getPassport() async {
    final response = await getPassportWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Passport',) as Passport;
    
    }
    return null;
  }

  /// My \"looking for a flatmate\" profile (404 when none)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getRoommateProfileWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/roommate-profile';

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

  /// My \"looking for a flatmate\" profile (404 when none)
  Future<RoommateProfile?> getRoommateProfile() async {
    final response = await getRoommateProfileWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RoommateProfile',) as RoommateProfile;
    
    }
    return null;
  }

  /// Invite a flatmate by e-mail
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  ///
  /// * [InviteToGroupRequest] inviteToGroupRequest (required):
  Future<Response> inviteToGroupWithHttpInfo(String groupId, InviteToGroupRequest inviteToGroupRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/groups/{groupId}/invitations'
      .replaceAll('{groupId}', groupId);

    // ignore: prefer_final_locals
    Object? postBody = inviteToGroupRequest;

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

  /// Invite a flatmate by e-mail
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  ///
  /// * [InviteToGroupRequest] inviteToGroupRequest (required):
  Future<void> inviteToGroup(String groupId, InviteToGroupRequest inviteToGroupRequest,) async {
    final response = await inviteToGroupWithHttpInfo(groupId, inviteToGroupRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Accept an invitation (consent to act as a member of the group)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  Future<Response> joinGroupWithHttpInfo(String groupId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/groups/{groupId}/join'
      .replaceAll('{groupId}', groupId);

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

  /// Accept an invitation (consent to act as a member of the group)
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  Future<void> joinGroup(String groupId,) async {
    final response = await joinGroupWithHttpInfo(groupId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Leave a group
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  Future<Response> leaveGroupWithHttpInfo(String groupId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/groups/{groupId}/leave'
      .replaceAll('{groupId}', groupId);

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

  /// Leave a group
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  Future<void> leaveGroup(String groupId,) async {
    final response = await leaveGroupWithHttpInfo(groupId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Applicants of a listing, verified first, with passport facts and the AI summary
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Response> listListingApplicationsWithHttpInfo(String orgId, String listingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/applications'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

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

  /// Applicants of a listing, verified first, with passport facts and the AI summary
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<List<Applicant>?> listListingApplications(String orgId, String listingId,) async {
    final response = await listListingApplicationsWithHttpInfo(orgId, listingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Applicant>') as List)
        .cast<Applicant>()
        .toList(growable: false);

    }
    return null;
  }

  /// Seekers who match a published room listing
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Response> listListingRoommatesWithHttpInfo(String orgId, String listingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/roommates'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

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

  /// Seekers who match a published room listing
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<List<RoommateMatch>?> listListingRoommates(String orgId, String listingId,) async {
    final response = await listListingRoommatesWithHttpInfo(orgId, listingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<RoommateMatch>') as List)
        .cast<RoommateMatch>()
        .toList(growable: false);

    }
    return null;
  }

  /// My applications, including my groups' applications
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyApplicationsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/applications';

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

  /// My applications, including my groups' applications
  Future<List<Application>?> listMyApplications() async {
    final response = await listMyApplicationsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Application>') as List)
        .cast<Application>()
        .toList(growable: false);

    }
    return null;
  }

  /// Groups I belong to or am invited to
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyGroupsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/groups';

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

  /// Groups I belong to or am invited to
  Future<List<GroupSummary>?> listMyGroups() async {
    final response = await listMyGroupsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<GroupSummary>') as List)
        .cast<GroupSummary>()
        .toList(growable: false);

    }
    return null;
  }

  /// My upcoming viewings
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyViewingsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/viewings';

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

  /// My upcoming viewings
  Future<List<Viewing>?> listMyViewings() async {
    final response = await listMyViewingsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Viewing>') as List)
        .cast<Viewing>()
        .toList(growable: false);

    }
    return null;
  }

  /// Other seekers ranked by match with my profile
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] area:
  ///   Admin unit path.
  Future<Response> listRoommatesWithHttpInfo({ String? area, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/roommates';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (area != null) {
      queryParams.addAll(_queryParams('', 'area', area));
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

  /// Other seekers ranked by match with my profile
  ///
  /// Parameters:
  ///
  /// * [String] area:
  ///   Admin unit path.
  Future<List<RoommateMatch>?> listRoommates({ String? area, }) async {
    final response = await listRoommatesWithHttpInfo( area: area, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<RoommateMatch>') as List)
        .cast<RoommateMatch>()
        .toList(growable: false);

    }
    return null;
  }

  /// Upcoming viewing slots with bookings
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Response> listViewingSlotsWithHttpInfo(String orgId, String listingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/viewing-slots'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

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

  /// Upcoming viewing slots with bookings
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<List<ViewingSlot>?> listViewingSlots(String orgId, String listingId,) async {
    final response = await listViewingSlotsWithHttpInfo(orgId, listingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<ViewingSlot>') as List)
        .cast<ViewingSlot>()
        .toList(growable: false);

    }
    return null;
  }

  /// Create or update my roommate profile
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RoommateProfile] roommateProfile (required):
  Future<Response> saveRoommateProfileWithHttpInfo(RoommateProfile roommateProfile,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/roommate-profile';

    // ignore: prefer_final_locals
    Object? postBody = roommateProfile;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create or update my roommate profile
  ///
  /// Parameters:
  ///
  /// * [RoommateProfile] roommateProfile (required):
  Future<RoommateProfile?> saveRoommateProfile(RoommateProfile roommateProfile,) async {
    final response = await saveRoommateProfileWithHttpInfo(roommateProfile,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RoommateProfile',) as RoommateProfile;
    
    }
    return null;
  }

  /// Post to the group chat
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  ///
  /// * [SendGroupMessageRequest] sendGroupMessageRequest (required):
  Future<Response> sendGroupMessageWithHttpInfo(String groupId, SendGroupMessageRequest sendGroupMessageRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/groups/{groupId}/messages'
      .replaceAll('{groupId}', groupId);

    // ignore: prefer_final_locals
    Object? postBody = sendGroupMessageRequest;

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

  /// Post to the group chat
  ///
  /// Parameters:
  ///
  /// * [String] groupId (required):
  ///
  /// * [SendGroupMessageRequest] sendGroupMessageRequest (required):
  Future<GroupMessage?> sendGroupMessage(String groupId, SendGroupMessageRequest sendGroupMessageRequest,) async {
    final response = await sendGroupMessageWithHttpInfo(groupId, sendGroupMessageRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'GroupMessage',) as GroupMessage;
    
    }
    return null;
  }

  /// Withdraw my application
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] applicationId (required):
  Future<Response> withdrawApplicationWithHttpInfo(String applicationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/applications/{applicationId}/withdraw'
      .replaceAll('{applicationId}', applicationId);

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

  /// Withdraw my application
  ///
  /// Parameters:
  ///
  /// * [String] applicationId (required):
  Future<void> withdrawApplication(String applicationId,) async {
    final response = await withdrawApplicationWithHttpInfo(applicationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
