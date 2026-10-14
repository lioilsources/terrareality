# terra_api.api.AuthApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**completeMfa**](AuthApi.md#completemfa) | **POST** /v1/auth/mfa | Complete a login that requires a second factor
[**finishOidc**](AuthApi.md#finishoidc) | **POST** /v1/auth/oidc/{provider}/callback | Finish a social login with the code from the provider redirect
[**forgotPassword**](AuthApi.md#forgotpassword) | **POST** /v1/auth/password/forgot | E-mail a password reset link
[**listAuthProviders**](AuthApi.md#listauthproviders) | **GET** /v1/auth/providers | Social login providers enabled on this deployment
[**login**](AuthApi.md#login) | **POST** /v1/auth/login | Log in with e-mail and password
[**logout**](AuthApi.md#logout) | **POST** /v1/auth/logout | Revoke the current session
[**register**](AuthApi.md#register) | **POST** /v1/auth/register | Create an account with e-mail and password
[**requestMagicLink**](AuthApi.md#requestmagiclink) | **POST** /v1/auth/magic-link | E-mail a one-time login link (creates the account if needed)
[**resendEmailVerification**](AuthApi.md#resendemailverification) | **POST** /v1/auth/email/resend | Send the verification e-mail again
[**resetPassword**](AuthApi.md#resetpassword) | **POST** /v1/auth/password/reset | Set a new password with a reset token; revokes all sessions
[**startOidc**](AuthApi.md#startoidc) | **POST** /v1/auth/oidc/{provider}/start | Begin a social login; returns the provider authorization URL
[**verifyEmail**](AuthApi.md#verifyemail) | **POST** /v1/auth/email/verify | Confirm an e-mail address with the token from the verification e-mail
[**verifyMagicLink**](AuthApi.md#verifymagiclink) | **POST** /v1/auth/magic-link/verify | Exchange a magic link token for a session


# **completeMfa**
> AuthResult completeMfa(mfaRequest)

Complete a login that requires a second factor

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final mfaRequest = MfaRequest(); // MfaRequest | 

try {
    final result = api_instance.completeMfa(mfaRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->completeMfa: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **mfaRequest** | [**MfaRequest**](MfaRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **finishOidc**
> AuthResult finishOidc(provider, oidcCallbackRequest)

Finish a social login with the code from the provider redirect

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final provider = provider_example; // String | 
final oidcCallbackRequest = OidcCallbackRequest(); // OidcCallbackRequest | 

try {
    final result = api_instance.finishOidc(provider, oidcCallbackRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->finishOidc: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **provider** | **String**|  | 
 **oidcCallbackRequest** | [**OidcCallbackRequest**](OidcCallbackRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **forgotPassword**
> forgotPassword(magicLinkRequest)

E-mail a password reset link

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final magicLinkRequest = MagicLinkRequest(); // MagicLinkRequest | 

try {
    api_instance.forgotPassword(magicLinkRequest);
} catch (e) {
    print('Exception when calling AuthApi->forgotPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **magicLinkRequest** | [**MagicLinkRequest**](MagicLinkRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAuthProviders**
> List<AuthProvider> listAuthProviders()

Social login providers enabled on this deployment

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();

try {
    final result = api_instance.listAuthProviders();
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->listAuthProviders: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<AuthProvider>**](AuthProvider.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **login**
> AuthResult login(loginRequest)

Log in with e-mail and password

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final loginRequest = LoginRequest(); // LoginRequest | 

try {
    final result = api_instance.login(loginRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->login: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logout**
> logout()

Revoke the current session

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AuthApi();

try {
    api_instance.logout();
} catch (e) {
    print('Exception when calling AuthApi->logout: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **register**
> AuthResult register(registerRequest)

Create an account with e-mail and password

Creates the user and their personal organization, records consents and sends a verification e-mail.

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final registerRequest = RegisterRequest(); // RegisterRequest | 

try {
    final result = api_instance.register(registerRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->register: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerRequest** | [**RegisterRequest**](RegisterRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestMagicLink**
> requestMagicLink(magicLinkRequest)

E-mail a one-time login link (creates the account if needed)

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final magicLinkRequest = MagicLinkRequest(); // MagicLinkRequest | 

try {
    api_instance.requestMagicLink(magicLinkRequest);
} catch (e) {
    print('Exception when calling AuthApi->requestMagicLink: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **magicLinkRequest** | [**MagicLinkRequest**](MagicLinkRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resendEmailVerification**
> resendEmailVerification()

Send the verification e-mail again

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AuthApi();

try {
    api_instance.resendEmailVerification();
} catch (e) {
    print('Exception when calling AuthApi->resendEmailVerification: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resetPassword**
> resetPassword(passwordResetRequest)

Set a new password with a reset token; revokes all sessions

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final passwordResetRequest = PasswordResetRequest(); // PasswordResetRequest | 

try {
    api_instance.resetPassword(passwordResetRequest);
} catch (e) {
    print('Exception when calling AuthApi->resetPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **passwordResetRequest** | [**PasswordResetRequest**](PasswordResetRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startOidc**
> OidcStart startOidc(provider, oidcStartRequest)

Begin a social login; returns the provider authorization URL

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final provider = provider_example; // String | 
final oidcStartRequest = OidcStartRequest(); // OidcStartRequest | 

try {
    final result = api_instance.startOidc(provider, oidcStartRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->startOidc: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **provider** | **String**|  | 
 **oidcStartRequest** | [**OidcStartRequest**](OidcStartRequest.md)|  | 

### Return type

[**OidcStart**](OidcStart.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifyEmail**
> verifyEmail(tokenRequest)

Confirm an e-mail address with the token from the verification e-mail

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final tokenRequest = TokenRequest(); // TokenRequest | 

try {
    api_instance.verifyEmail(tokenRequest);
} catch (e) {
    print('Exception when calling AuthApi->verifyEmail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tokenRequest** | [**TokenRequest**](TokenRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifyMagicLink**
> AuthResult verifyMagicLink(tokenRequest)

Exchange a magic link token for a session

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = AuthApi();
final tokenRequest = TokenRequest(); // TokenRequest | 

try {
    final result = api_instance.verifyMagicLink(tokenRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->verifyMagicLink: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tokenRequest** | [**TokenRequest**](TokenRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

