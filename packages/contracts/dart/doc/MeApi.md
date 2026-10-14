# terra_api.api.MeApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cancelErasure**](MeApi.md#cancelerasure) | **DELETE** /v1/me/erasure | Cancel a scheduled erasure during the grace period
[**changePassword**](MeApi.md#changepassword) | **POST** /v1/me/password | Change or set the password; revokes other sessions
[**disableTotp**](MeApi.md#disabletotp) | **POST** /v1/me/mfa/totp/disable | Disable TOTP after confirming a current code
[**enableTotp**](MeApi.md#enabletotp) | **POST** /v1/me/mfa/totp/enable | Confirm the TOTP secret with a code; returns one-time recovery codes
[**finishIdentityVerification**](MeApi.md#finishidentityverification) | **POST** /v1/me/identity/callback | Finish identity verification with the code from the provider redirect
[**getDataExportDownload**](MeApi.md#getdataexportdownload) | **GET** /v1/me/data-exports/{requestId}/download | Short-lived download URL of a finished export
[**getMe**](MeApi.md#getme) | **GET** /v1/me | Current user, verification level and organizations
[**listConsents**](MeApi.md#listconsents) | **GET** /v1/me/consents | Consent history (append-only)
[**listGdprRequests**](MeApi.md#listgdprrequests) | **GET** /v1/me/gdpr-requests | My data export and erasure requests
[**listMySessions**](MeApi.md#listmysessions) | **GET** /v1/me/sessions | Active sessions of the current user
[**recordConsent**](MeApi.md#recordconsent) | **POST** /v1/me/consents | Grant or withdraw a consent
[**requestDataExport**](MeApi.md#requestdataexport) | **POST** /v1/me/data-exports | Request a machine-readable export of my data (GDPR art. 15 and 20)
[**requestErasure**](MeApi.md#requesterasure) | **POST** /v1/me/erasure | Request account erasure (GDPR art. 17) after a grace period
[**revokeMySession**](MeApi.md#revokemysession) | **DELETE** /v1/me/sessions/{sessionId} | Revoke one of my sessions
[**setupTotp**](MeApi.md#setuptotp) | **POST** /v1/me/mfa/totp/setup | Generate a new TOTP secret (not active until confirmed)
[**startIdentityVerification**](MeApi.md#startidentityverification) | **POST** /v1/me/identity/start | Begin identity verification (BankID in CZ); returns the provider URL
[**startPhoneVerification**](MeApi.md#startphoneverification) | **POST** /v1/me/phone | Send a verification code by SMS
[**updateMe**](MeApi.md#updateme) | **PATCH** /v1/me | Update profile
[**verifyPhone**](MeApi.md#verifyphone) | **POST** /v1/me/phone/verify | Confirm the phone number with the SMS code


# **cancelErasure**
> cancelErasure()

Cancel a scheduled erasure during the grace period

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();

try {
    api_instance.cancelErasure();
} catch (e) {
    print('Exception when calling MeApi->cancelErasure: $e\n');
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

# **changePassword**
> changePassword(changePasswordRequest)

Change or set the password; revokes other sessions

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final changePasswordRequest = ChangePasswordRequest(); // ChangePasswordRequest | 

try {
    api_instance.changePassword(changePasswordRequest);
} catch (e) {
    print('Exception when calling MeApi->changePassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **changePasswordRequest** | [**ChangePasswordRequest**](ChangePasswordRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **disableTotp**
> disableTotp(codeRequest)

Disable TOTP after confirming a current code

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final codeRequest = CodeRequest(); // CodeRequest | 

try {
    api_instance.disableTotp(codeRequest);
} catch (e) {
    print('Exception when calling MeApi->disableTotp: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **codeRequest** | [**CodeRequest**](CodeRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **enableTotp**
> RecoveryCodes enableTotp(codeRequest)

Confirm the TOTP secret with a code; returns one-time recovery codes

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final codeRequest = CodeRequest(); // CodeRequest | 

try {
    final result = api_instance.enableTotp(codeRequest);
    print(result);
} catch (e) {
    print('Exception when calling MeApi->enableTotp: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **codeRequest** | [**CodeRequest**](CodeRequest.md)|  | 

### Return type

[**RecoveryCodes**](RecoveryCodes.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **finishIdentityVerification**
> Me finishIdentityVerification(oidcCallbackRequest)

Finish identity verification with the code from the provider redirect

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final oidcCallbackRequest = OidcCallbackRequest(); // OidcCallbackRequest | 

try {
    final result = api_instance.finishIdentityVerification(oidcCallbackRequest);
    print(result);
} catch (e) {
    print('Exception when calling MeApi->finishIdentityVerification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **oidcCallbackRequest** | [**OidcCallbackRequest**](OidcCallbackRequest.md)|  | 

### Return type

[**Me**](Me.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDataExportDownload**
> DownloadLink getDataExportDownload(requestId)

Short-lived download URL of a finished export

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final requestId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getDataExportDownload(requestId);
    print(result);
} catch (e) {
    print('Exception when calling MeApi->getDataExportDownload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 

### Return type

[**DownloadLink**](DownloadLink.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMe**
> Me getMe()

Current user, verification level and organizations

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();

try {
    final result = api_instance.getMe();
    print(result);
} catch (e) {
    print('Exception when calling MeApi->getMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Me**](Me.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listConsents**
> List<Consent> listConsents()

Consent history (append-only)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();

try {
    final result = api_instance.listConsents();
    print(result);
} catch (e) {
    print('Exception when calling MeApi->listConsents: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Consent>**](Consent.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listGdprRequests**
> List<GdprRequest> listGdprRequests()

My data export and erasure requests

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();

try {
    final result = api_instance.listGdprRequests();
    print(result);
} catch (e) {
    print('Exception when calling MeApi->listGdprRequests: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<GdprRequest>**](GdprRequest.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMySessions**
> List<SessionInfo> listMySessions()

Active sessions of the current user

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();

try {
    final result = api_instance.listMySessions();
    print(result);
} catch (e) {
    print('Exception when calling MeApi->listMySessions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<SessionInfo>**](SessionInfo.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recordConsent**
> Consent recordConsent(consentInput)

Grant or withdraw a consent

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final consentInput = ConsentInput(); // ConsentInput | 

try {
    final result = api_instance.recordConsent(consentInput);
    print(result);
} catch (e) {
    print('Exception when calling MeApi->recordConsent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **consentInput** | [**ConsentInput**](ConsentInput.md)|  | 

### Return type

[**Consent**](Consent.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestDataExport**
> GdprRequest requestDataExport()

Request a machine-readable export of my data (GDPR art. 15 and 20)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();

try {
    final result = api_instance.requestDataExport();
    print(result);
} catch (e) {
    print('Exception when calling MeApi->requestDataExport: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**GdprRequest**](GdprRequest.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestErasure**
> GdprRequest requestErasure()

Request account erasure (GDPR art. 17) after a grace period

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();

try {
    final result = api_instance.requestErasure();
    print(result);
} catch (e) {
    print('Exception when calling MeApi->requestErasure: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**GdprRequest**](GdprRequest.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revokeMySession**
> revokeMySession(sessionId)

Revoke one of my sessions

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final sessionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.revokeMySession(sessionId);
} catch (e) {
    print('Exception when calling MeApi->revokeMySession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sessionId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setupTotp**
> TotpSetup setupTotp()

Generate a new TOTP secret (not active until confirmed)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();

try {
    final result = api_instance.setupTotp();
    print(result);
} catch (e) {
    print('Exception when calling MeApi->setupTotp: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**TotpSetup**](TotpSetup.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startIdentityVerification**
> OidcStart startIdentityVerification(oidcStartRequest)

Begin identity verification (BankID in CZ); returns the provider URL

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final oidcStartRequest = OidcStartRequest(); // OidcStartRequest | 

try {
    final result = api_instance.startIdentityVerification(oidcStartRequest);
    print(result);
} catch (e) {
    print('Exception when calling MeApi->startIdentityVerification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **oidcStartRequest** | [**OidcStartRequest**](OidcStartRequest.md)|  | 

### Return type

[**OidcStart**](OidcStart.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startPhoneVerification**
> startPhoneVerification(phoneRequest)

Send a verification code by SMS

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final phoneRequest = PhoneRequest(); // PhoneRequest | 

try {
    api_instance.startPhoneVerification(phoneRequest);
} catch (e) {
    print('Exception when calling MeApi->startPhoneVerification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **phoneRequest** | [**PhoneRequest**](PhoneRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMe**
> Me updateMe(updateMeRequest)

Update profile

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final updateMeRequest = UpdateMeRequest(); // UpdateMeRequest | 

try {
    final result = api_instance.updateMe(updateMeRequest);
    print(result);
} catch (e) {
    print('Exception when calling MeApi->updateMe: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateMeRequest** | [**UpdateMeRequest**](UpdateMeRequest.md)|  | 

### Return type

[**Me**](Me.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifyPhone**
> Me verifyPhone(codeRequest)

Confirm the phone number with the SMS code

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MeApi();
final codeRequest = CodeRequest(); // CodeRequest | 

try {
    final result = api_instance.verifyPhone(codeRequest);
    print(result);
} catch (e) {
    print('Exception when calling MeApi->verifyPhone: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **codeRequest** | [**CodeRequest**](CodeRequest.md)|  | 

### Return type

[**Me**](Me.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

