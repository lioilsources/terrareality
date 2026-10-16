//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MeApi {
  MeApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Cancel a scheduled erasure during the grace period
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> cancelErasureWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/erasure';

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

  /// Cancel a scheduled erasure during the grace period
  Future<void> cancelErasure() async {
    final response = await cancelErasureWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Change or set the password; revokes other sessions
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ChangePasswordRequest] changePasswordRequest (required):
  Future<Response> changePasswordWithHttpInfo(ChangePasswordRequest changePasswordRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/password';

    // ignore: prefer_final_locals
    Object? postBody = changePasswordRequest;

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

  /// Change or set the password; revokes other sessions
  ///
  /// Parameters:
  ///
  /// * [ChangePasswordRequest] changePasswordRequest (required):
  Future<void> changePassword(ChangePasswordRequest changePasswordRequest,) async {
    final response = await changePasswordWithHttpInfo(changePasswordRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Unregister a push device
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  Future<Response> deletePushDeviceWithHttpInfo(String deviceId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/push-devices/{deviceId}'
      .replaceAll('{deviceId}', deviceId);

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

  /// Unregister a push device
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  Future<void> deletePushDevice(String deviceId,) async {
    final response = await deletePushDeviceWithHttpInfo(deviceId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Disable TOTP after confirming a current code
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CodeRequest] codeRequest (required):
  Future<Response> disableTotpWithHttpInfo(CodeRequest codeRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/mfa/totp/disable';

    // ignore: prefer_final_locals
    Object? postBody = codeRequest;

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

  /// Disable TOTP after confirming a current code
  ///
  /// Parameters:
  ///
  /// * [CodeRequest] codeRequest (required):
  Future<void> disableTotp(CodeRequest codeRequest,) async {
    final response = await disableTotpWithHttpInfo(codeRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Confirm the TOTP secret with a code; returns one-time recovery codes
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CodeRequest] codeRequest (required):
  Future<Response> enableTotpWithHttpInfo(CodeRequest codeRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/mfa/totp/enable';

    // ignore: prefer_final_locals
    Object? postBody = codeRequest;

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

  /// Confirm the TOTP secret with a code; returns one-time recovery codes
  ///
  /// Parameters:
  ///
  /// * [CodeRequest] codeRequest (required):
  Future<RecoveryCodes?> enableTotp(CodeRequest codeRequest,) async {
    final response = await enableTotpWithHttpInfo(codeRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecoveryCodes',) as RecoveryCodes;
    
    }
    return null;
  }

  /// Finish identity verification with the code from the provider redirect
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [OidcCallbackRequest] oidcCallbackRequest (required):
  Future<Response> finishIdentityVerificationWithHttpInfo(OidcCallbackRequest oidcCallbackRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/identity/callback';

    // ignore: prefer_final_locals
    Object? postBody = oidcCallbackRequest;

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

  /// Finish identity verification with the code from the provider redirect
  ///
  /// Parameters:
  ///
  /// * [OidcCallbackRequest] oidcCallbackRequest (required):
  Future<Me?> finishIdentityVerification(OidcCallbackRequest oidcCallbackRequest,) async {
    final response = await finishIdentityVerificationWithHttpInfo(oidcCallbackRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Me',) as Me;
    
    }
    return null;
  }

  /// Short-lived download URL of a finished export
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] requestId (required):
  Future<Response> getDataExportDownloadWithHttpInfo(String requestId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/data-exports/{requestId}/download'
      .replaceAll('{requestId}', requestId);

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

  /// Short-lived download URL of a finished export
  ///
  /// Parameters:
  ///
  /// * [String] requestId (required):
  Future<DownloadLink?> getDataExportDownload(String requestId,) async {
    final response = await getDataExportDownloadWithHttpInfo(requestId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DownloadLink',) as DownloadLink;
    
    }
    return null;
  }

  /// Current user, verification level and organizations
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMeWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me';

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

  /// Current user, verification level and organizations
  Future<Me?> getMe() async {
    final response = await getMeWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Me',) as Me;
    
    }
    return null;
  }

  /// Notification settings
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getNotificationPreferencesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/notification-preferences';

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

  /// Notification settings
  Future<NotificationPreferences?> getNotificationPreferences() async {
    final response = await getNotificationPreferencesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotificationPreferences',) as NotificationPreferences;
    
    }
    return null;
  }

  /// Consent history (append-only)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listConsentsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/consents';

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

  /// Consent history (append-only)
  Future<List<Consent>?> listConsents() async {
    final response = await listConsentsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Consent>') as List)
        .cast<Consent>()
        .toList(growable: false);

    }
    return null;
  }

  /// My data export and erasure requests
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listGdprRequestsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/gdpr-requests';

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

  /// My data export and erasure requests
  Future<List<GdprRequest>?> listGdprRequests() async {
    final response = await listGdprRequestsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<GdprRequest>') as List)
        .cast<GdprRequest>()
        .toList(growable: false);

    }
    return null;
  }

  /// Active sessions of the current user
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMySessionsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/sessions';

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

  /// Active sessions of the current user
  Future<List<SessionInfo>?> listMySessions() async {
    final response = await listMySessionsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<SessionInfo>') as List)
        .cast<SessionInfo>()
        .toList(growable: false);

    }
    return null;
  }

  /// Latest in-app notifications
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listNotificationsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/notifications';

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

  /// Latest in-app notifications
  Future<NotificationList?> listNotifications() async {
    final response = await listNotificationsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotificationList',) as NotificationList;
    
    }
    return null;
  }

  /// Registered push devices
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPushDevicesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/push-devices';

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

  /// Registered push devices
  Future<List<PushDevice>?> listPushDevices() async {
    final response = await listPushDevicesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PushDevice>') as List)
        .cast<PushDevice>()
        .toList(growable: false);

    }
    return null;
  }

  /// Mark one notification (id) or all as read
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MarkNotificationsReadRequest] markNotificationsReadRequest:
  Future<Response> markNotificationsReadWithHttpInfo({ MarkNotificationsReadRequest? markNotificationsReadRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/notifications/read';

    // ignore: prefer_final_locals
    Object? postBody = markNotificationsReadRequest;

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

  /// Mark one notification (id) or all as read
  ///
  /// Parameters:
  ///
  /// * [MarkNotificationsReadRequest] markNotificationsReadRequest:
  Future<void> markNotificationsRead({ MarkNotificationsReadRequest? markNotificationsReadRequest, }) async {
    final response = await markNotificationsReadWithHttpInfo( markNotificationsReadRequest: markNotificationsReadRequest, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Grant or withdraw a consent
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ConsentInput] consentInput (required):
  Future<Response> recordConsentWithHttpInfo(ConsentInput consentInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/consents';

    // ignore: prefer_final_locals
    Object? postBody = consentInput;

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

  /// Grant or withdraw a consent
  ///
  /// Parameters:
  ///
  /// * [ConsentInput] consentInput (required):
  Future<Consent?> recordConsent(ConsentInput consentInput,) async {
    final response = await recordConsentWithHttpInfo(consentInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Consent',) as Consent;
    
    }
    return null;
  }

  /// Register an FCM token or a web push subscription
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PushDeviceInput] pushDeviceInput (required):
  Future<Response> registerPushDeviceWithHttpInfo(PushDeviceInput pushDeviceInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/push-devices';

    // ignore: prefer_final_locals
    Object? postBody = pushDeviceInput;

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

  /// Register an FCM token or a web push subscription
  ///
  /// Parameters:
  ///
  /// * [PushDeviceInput] pushDeviceInput (required):
  Future<PushDevice?> registerPushDevice(PushDeviceInput pushDeviceInput,) async {
    final response = await registerPushDeviceWithHttpInfo(pushDeviceInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PushDevice',) as PushDevice;
    
    }
    return null;
  }

  /// Request a machine-readable export of my data (GDPR art. 15 and 20)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> requestDataExportWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/data-exports';

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

  /// Request a machine-readable export of my data (GDPR art. 15 and 20)
  Future<GdprRequest?> requestDataExport() async {
    final response = await requestDataExportWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'GdprRequest',) as GdprRequest;
    
    }
    return null;
  }

  /// Request account erasure (GDPR art. 17) after a grace period
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> requestErasureWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/erasure';

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

  /// Request account erasure (GDPR art. 17) after a grace period
  Future<GdprRequest?> requestErasure() async {
    final response = await requestErasureWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'GdprRequest',) as GdprRequest;
    
    }
    return null;
  }

  /// Revoke one of my sessions
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] sessionId (required):
  Future<Response> revokeMySessionWithHttpInfo(String sessionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/sessions/{sessionId}'
      .replaceAll('{sessionId}', sessionId);

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

  /// Revoke one of my sessions
  ///
  /// Parameters:
  ///
  /// * [String] sessionId (required):
  Future<void> revokeMySession(String sessionId,) async {
    final response = await revokeMySessionWithHttpInfo(sessionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Change notification settings
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotificationPreferences] notificationPreferences (required):
  Future<Response> setNotificationPreferencesWithHttpInfo(NotificationPreferences notificationPreferences,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/notification-preferences';

    // ignore: prefer_final_locals
    Object? postBody = notificationPreferences;

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

  /// Change notification settings
  ///
  /// Parameters:
  ///
  /// * [NotificationPreferences] notificationPreferences (required):
  Future<NotificationPreferences?> setNotificationPreferences(NotificationPreferences notificationPreferences,) async {
    final response = await setNotificationPreferencesWithHttpInfo(notificationPreferences,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotificationPreferences',) as NotificationPreferences;
    
    }
    return null;
  }

  /// Generate a new TOTP secret (not active until confirmed)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> setupTotpWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/mfa/totp/setup';

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

  /// Generate a new TOTP secret (not active until confirmed)
  Future<TotpSetup?> setupTotp() async {
    final response = await setupTotpWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TotpSetup',) as TotpSetup;
    
    }
    return null;
  }

  /// Begin identity verification (BankID in CZ); returns the provider URL
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [OidcStartRequest] oidcStartRequest (required):
  Future<Response> startIdentityVerificationWithHttpInfo(OidcStartRequest oidcStartRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/identity/start';

    // ignore: prefer_final_locals
    Object? postBody = oidcStartRequest;

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

  /// Begin identity verification (BankID in CZ); returns the provider URL
  ///
  /// Parameters:
  ///
  /// * [OidcStartRequest] oidcStartRequest (required):
  Future<OidcStart?> startIdentityVerification(OidcStartRequest oidcStartRequest,) async {
    final response = await startIdentityVerificationWithHttpInfo(oidcStartRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'OidcStart',) as OidcStart;
    
    }
    return null;
  }

  /// Send a verification code by SMS
  ///
  /// Errors: 503 `phone_verification_unavailable` while SMS verification is switched off.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PhoneRequest] phoneRequest (required):
  Future<Response> startPhoneVerificationWithHttpInfo(PhoneRequest phoneRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/phone';

    // ignore: prefer_final_locals
    Object? postBody = phoneRequest;

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

  /// Send a verification code by SMS
  ///
  /// Errors: 503 `phone_verification_unavailable` while SMS verification is switched off.
  ///
  /// Parameters:
  ///
  /// * [PhoneRequest] phoneRequest (required):
  Future<void> startPhoneVerification(PhoneRequest phoneRequest,) async {
    final response = await startPhoneVerificationWithHttpInfo(phoneRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Update profile
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UpdateMeRequest] updateMeRequest (required):
  Future<Response> updateMeWithHttpInfo(UpdateMeRequest updateMeRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me';

    // ignore: prefer_final_locals
    Object? postBody = updateMeRequest;

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

  /// Update profile
  ///
  /// Parameters:
  ///
  /// * [UpdateMeRequest] updateMeRequest (required):
  Future<Me?> updateMe(UpdateMeRequest updateMeRequest,) async {
    final response = await updateMeWithHttpInfo(updateMeRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Me',) as Me;
    
    }
    return null;
  }

  /// Confirm the phone number with the SMS code
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CodeRequest] codeRequest (required):
  Future<Response> verifyPhoneWithHttpInfo(CodeRequest codeRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/phone/verify';

    // ignore: prefer_final_locals
    Object? postBody = codeRequest;

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

  /// Confirm the phone number with the SMS code
  ///
  /// Parameters:
  ///
  /// * [CodeRequest] codeRequest (required):
  Future<Me?> verifyPhone(CodeRequest codeRequest,) async {
    final response = await verifyPhoneWithHttpInfo(codeRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Me',) as Me;
    
    }
    return null;
  }
}
