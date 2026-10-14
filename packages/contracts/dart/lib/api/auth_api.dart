//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AuthApi {
  AuthApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Complete a login that requires a second factor
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MfaRequest] mfaRequest (required):
  Future<Response> completeMfaWithHttpInfo(MfaRequest mfaRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/mfa';

    // ignore: prefer_final_locals
    Object? postBody = mfaRequest;

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

  /// Complete a login that requires a second factor
  ///
  /// Parameters:
  ///
  /// * [MfaRequest] mfaRequest (required):
  Future<AuthResult?> completeMfa(MfaRequest mfaRequest,) async {
    final response = await completeMfaWithHttpInfo(mfaRequest,);
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

  /// Finish a social login with the code from the provider redirect
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] provider (required):
  ///
  /// * [OidcCallbackRequest] oidcCallbackRequest (required):
  Future<Response> finishOidcWithHttpInfo(String provider, OidcCallbackRequest oidcCallbackRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/oidc/{provider}/callback'
      .replaceAll('{provider}', provider);

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

  /// Finish a social login with the code from the provider redirect
  ///
  /// Parameters:
  ///
  /// * [String] provider (required):
  ///
  /// * [OidcCallbackRequest] oidcCallbackRequest (required):
  Future<AuthResult?> finishOidc(String provider, OidcCallbackRequest oidcCallbackRequest,) async {
    final response = await finishOidcWithHttpInfo(provider, oidcCallbackRequest,);
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

  /// E-mail a password reset link
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MagicLinkRequest] magicLinkRequest (required):
  Future<Response> forgotPasswordWithHttpInfo(MagicLinkRequest magicLinkRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/password/forgot';

    // ignore: prefer_final_locals
    Object? postBody = magicLinkRequest;

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

  /// E-mail a password reset link
  ///
  /// Parameters:
  ///
  /// * [MagicLinkRequest] magicLinkRequest (required):
  Future<void> forgotPassword(MagicLinkRequest magicLinkRequest,) async {
    final response = await forgotPasswordWithHttpInfo(magicLinkRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Social login providers enabled on this deployment
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listAuthProvidersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/providers';

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

  /// Social login providers enabled on this deployment
  Future<List<AuthProvider>?> listAuthProviders() async {
    final response = await listAuthProvidersWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AuthProvider>') as List)
        .cast<AuthProvider>()
        .toList(growable: false);

    }
    return null;
  }

  /// Log in with e-mail and password
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [LoginRequest] loginRequest (required):
  Future<Response> loginWithHttpInfo(LoginRequest loginRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/login';

    // ignore: prefer_final_locals
    Object? postBody = loginRequest;

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

  /// Log in with e-mail and password
  ///
  /// Parameters:
  ///
  /// * [LoginRequest] loginRequest (required):
  Future<AuthResult?> login(LoginRequest loginRequest,) async {
    final response = await loginWithHttpInfo(loginRequest,);
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

  /// Revoke the current session
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> logoutWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/logout';

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

  /// Revoke the current session
  Future<void> logout() async {
    final response = await logoutWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Create an account with e-mail and password
  ///
  /// Creates the user and their personal organization, records consents and sends a verification e-mail.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RegisterRequest] registerRequest (required):
  Future<Response> registerWithHttpInfo(RegisterRequest registerRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/register';

    // ignore: prefer_final_locals
    Object? postBody = registerRequest;

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

  /// Create an account with e-mail and password
  ///
  /// Creates the user and their personal organization, records consents and sends a verification e-mail.
  ///
  /// Parameters:
  ///
  /// * [RegisterRequest] registerRequest (required):
  Future<AuthResult?> register(RegisterRequest registerRequest,) async {
    final response = await registerWithHttpInfo(registerRequest,);
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

  /// E-mail a one-time login link (creates the account if needed)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MagicLinkRequest] magicLinkRequest (required):
  Future<Response> requestMagicLinkWithHttpInfo(MagicLinkRequest magicLinkRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/magic-link';

    // ignore: prefer_final_locals
    Object? postBody = magicLinkRequest;

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

  /// E-mail a one-time login link (creates the account if needed)
  ///
  /// Parameters:
  ///
  /// * [MagicLinkRequest] magicLinkRequest (required):
  Future<void> requestMagicLink(MagicLinkRequest magicLinkRequest,) async {
    final response = await requestMagicLinkWithHttpInfo(magicLinkRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Send the verification e-mail again
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> resendEmailVerificationWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/email/resend';

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

  /// Send the verification e-mail again
  Future<void> resendEmailVerification() async {
    final response = await resendEmailVerificationWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Set a new password with a reset token; revokes all sessions
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PasswordResetRequest] passwordResetRequest (required):
  Future<Response> resetPasswordWithHttpInfo(PasswordResetRequest passwordResetRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/password/reset';

    // ignore: prefer_final_locals
    Object? postBody = passwordResetRequest;

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

  /// Set a new password with a reset token; revokes all sessions
  ///
  /// Parameters:
  ///
  /// * [PasswordResetRequest] passwordResetRequest (required):
  Future<void> resetPassword(PasswordResetRequest passwordResetRequest,) async {
    final response = await resetPasswordWithHttpInfo(passwordResetRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Begin a social login; returns the provider authorization URL
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] provider (required):
  ///
  /// * [OidcStartRequest] oidcStartRequest (required):
  Future<Response> startOidcWithHttpInfo(String provider, OidcStartRequest oidcStartRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/oidc/{provider}/start'
      .replaceAll('{provider}', provider);

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

  /// Begin a social login; returns the provider authorization URL
  ///
  /// Parameters:
  ///
  /// * [String] provider (required):
  ///
  /// * [OidcStartRequest] oidcStartRequest (required):
  Future<OidcStart?> startOidc(String provider, OidcStartRequest oidcStartRequest,) async {
    final response = await startOidcWithHttpInfo(provider, oidcStartRequest,);
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

  /// Confirm an e-mail address with the token from the verification e-mail
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TokenRequest] tokenRequest (required):
  Future<Response> verifyEmailWithHttpInfo(TokenRequest tokenRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/email/verify';

    // ignore: prefer_final_locals
    Object? postBody = tokenRequest;

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

  /// Confirm an e-mail address with the token from the verification e-mail
  ///
  /// Parameters:
  ///
  /// * [TokenRequest] tokenRequest (required):
  Future<void> verifyEmail(TokenRequest tokenRequest,) async {
    final response = await verifyEmailWithHttpInfo(tokenRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Exchange a magic link token for a session
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TokenRequest] tokenRequest (required):
  Future<Response> verifyMagicLinkWithHttpInfo(TokenRequest tokenRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/magic-link/verify';

    // ignore: prefer_final_locals
    Object? postBody = tokenRequest;

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

  /// Exchange a magic link token for a session
  ///
  /// Parameters:
  ///
  /// * [TokenRequest] tokenRequest (required):
  Future<AuthResult?> verifyMagicLink(TokenRequest tokenRequest,) async {
    final response = await verifyMagicLinkWithHttpInfo(tokenRequest,);
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
}
