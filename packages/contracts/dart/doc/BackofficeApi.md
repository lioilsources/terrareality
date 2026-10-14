# terra_api.api.BackofficeApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**backofficeDecideFilterProposal**](BackofficeApi.md#backofficedecidefilterproposal) | **POST** /v1/backoffice/filter-proposals/{proposalId}/decision | Add the option to the schema or reject it (staff)
[**backofficeDecideReview**](BackofficeApi.md#backofficedecidereview) | **POST** /v1/backoffice/reviews/{versionId}/decision | Approve (publish) or reject a version (staff)
[**backofficeGetReview**](BackofficeApi.md#backofficegetreview) | **GET** /v1/backoffice/reviews/{versionId} | One submitted version with its snapshot (staff)
[**backofficeGetUser**](BackofficeApi.md#backofficegetuser) | **GET** /v1/backoffice/users/{userId} | User detail with organizations (staff)
[**backofficeImpersonate**](BackofficeApi.md#backofficeimpersonate) | **POST** /v1/backoffice/users/{userId}/impersonate | Start a short audited session as the user (staff)
[**backofficeListAudit**](BackofficeApi.md#backofficelistaudit) | **GET** /v1/backoffice/audit | Platform-wide audit log (staff)
[**backofficeListFilterProposals**](BackofficeApi.md#backofficelistfilterproposals) | **GET** /v1/backoffice/filter-proposals | New attribute options proposed by AI ingest (staff)
[**backofficeListReviews**](BackofficeApi.md#backofficelistreviews) | **GET** /v1/backoffice/reviews | Moderation queue of submitted listing versions (staff)
[**backofficeListUsers**](BackofficeApi.md#backofficelistusers) | **GET** /v1/backoffice/users | Search users (staff)


# **backofficeDecideFilterProposal**
> backofficeDecideFilterProposal(proposalId, proposalDecision)

Add the option to the schema or reject it (staff)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BackofficeApi();
final proposalId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final proposalDecision = ProposalDecision(); // ProposalDecision | 

try {
    api_instance.backofficeDecideFilterProposal(proposalId, proposalDecision);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeDecideFilterProposal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **proposalId** | **String**|  | 
 **proposalDecision** | [**ProposalDecision**](ProposalDecision.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeDecideReview**
> backofficeDecideReview(versionId, reviewDecision)

Approve (publish) or reject a version (staff)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BackofficeApi();
final versionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final reviewDecision = ReviewDecision(); // ReviewDecision | 

try {
    api_instance.backofficeDecideReview(versionId, reviewDecision);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeDecideReview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **versionId** | **String**|  | 
 **reviewDecision** | [**ReviewDecision**](ReviewDecision.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeGetReview**
> ReviewDetail backofficeGetReview(versionId)

One submitted version with its snapshot (staff)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BackofficeApi();
final versionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.backofficeGetReview(versionId);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeGetReview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **versionId** | **String**|  | 

### Return type

[**ReviewDetail**](ReviewDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeGetUser**
> AdminUserDetail backofficeGetUser(userId)

User detail with organizations (staff)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BackofficeApi();
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.backofficeGetUser(userId);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeGetUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**AdminUserDetail**](AdminUserDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeImpersonate**
> AuthResult backofficeImpersonate(userId, impersonateRequest)

Start a short audited session as the user (staff)

The session cannot change credentials, MFA or request erasure. Ends with POST /v1/auth/logout.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BackofficeApi();
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final impersonateRequest = ImpersonateRequest(); // ImpersonateRequest | 

try {
    final result = api_instance.backofficeImpersonate(userId, impersonateRequest);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeImpersonate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 
 **impersonateRequest** | [**ImpersonateRequest**](ImpersonateRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeListAudit**
> AuditPage backofficeListAudit(actorId, orgId, entity, before, limit)

Platform-wide audit log (staff)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BackofficeApi();
final actorId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final entity = entity_example; // String | 
final before = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Cursor; return items with an id lower than this one.
final limit = 56; // int | 

try {
    final result = api_instance.backofficeListAudit(actorId, orgId, entity, before, limit);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeListAudit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **actorId** | **String**|  | [optional] 
 **orgId** | **String**|  | [optional] 
 **entity** | **String**|  | [optional] 
 **before** | **String**| Cursor; return items with an id lower than this one. | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**AuditPage**](AuditPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeListFilterProposals**
> List<FilterProposal> backofficeListFilterProposals(status)

New attribute options proposed by AI ingest (staff)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BackofficeApi();
final status = status_example; // String | 

try {
    final result = api_instance.backofficeListFilterProposals(status);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeListFilterProposals: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] [default to 'pending']

### Return type

[**List<FilterProposal>**](FilterProposal.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeListReviews**
> List<ReviewItem> backofficeListReviews()

Moderation queue of submitted listing versions (staff)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BackofficeApi();

try {
    final result = api_instance.backofficeListReviews();
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeListReviews: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<ReviewItem>**](ReviewItem.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeListUsers**
> AdminUserPage backofficeListUsers(q, before, limit)

Search users (staff)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BackofficeApi();
final q = q_example; // String | 
final before = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Cursor; return items with an id lower than this one.
final limit = 56; // int | 

try {
    final result = api_instance.backofficeListUsers(q, before, limit);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeListUsers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] 
 **before** | **String**| Cursor; return items with an id lower than this one. | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**AdminUserPage**](AdminUserPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

