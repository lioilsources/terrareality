# terra_api.api.BackofficeApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**backofficeCreatePromoProduct**](BackofficeApi.md#backofficecreatepromoproduct) | **POST** /v1/backoffice/promo-products | Add a promotion product (staff, audited)
[**backofficeDecideAttributeSuggestion**](BackofficeApi.md#backofficedecideattributesuggestion) | **POST** /v1/backoffice/attribute-suggestions/{suggestionId}/decision | Approve or reject an AI-proposed attribute (staff, audited)
[**backofficeDecideFilterProposal**](BackofficeApi.md#backofficedecidefilterproposal) | **POST** /v1/backoffice/filter-proposals/{proposalId}/decision | Add the option to the schema or reject it (staff)
[**backofficeDecideModeration**](BackofficeApi.md#backofficedecidemoderation) | **POST** /v1/backoffice/moderation/{caseId}/decision | Resolve a case (human decision; the AI verdict is only a suggestion)
[**backofficeDecideReview**](BackofficeApi.md#backofficedecidereview) | **POST** /v1/backoffice/reviews/{versionId}/decision | Approve (publish) or reject a version (staff)
[**backofficeGetMetrics**](BackofficeApi.md#backofficegetmetrics) | **GET** /v1/backoffice/metrics | Platform metrics for the dashboard (staff)
[**backofficeGetModeration**](BackofficeApi.md#backofficegetmoderation) | **GET** /v1/backoffice/moderation/{caseId} | A case with the conversation transcript and the AI suggestion
[**backofficeGetReview**](BackofficeApi.md#backofficegetreview) | **GET** /v1/backoffice/reviews/{versionId} | One submitted version with its snapshot (staff)
[**backofficeGetUser**](BackofficeApi.md#backofficegetuser) | **GET** /v1/backoffice/users/{userId} | User detail with organizations (staff)
[**backofficeImpersonate**](BackofficeApi.md#backofficeimpersonate) | **POST** /v1/backoffice/users/{userId}/impersonate | Start a short audited session as the user (staff)
[**backofficeListAttributeSuggestions**](BackofficeApi.md#backofficelistattributesuggestions) | **GET** /v1/backoffice/attribute-suggestions | New attributes proposed by AI ingest, waiting for a staff decision (ADR 0003)
[**backofficeListAudit**](BackofficeApi.md#backofficelistaudit) | **GET** /v1/backoffice/audit | Platform-wide audit log (staff)
[**backofficeListFeatureFlags**](BackofficeApi.md#backofficelistfeatureflags) | **GET** /v1/backoffice/feature-flags | Feature flags with their source (database row or config default) (staff)
[**backofficeListFilterProposals**](BackofficeApi.md#backofficelistfilterproposals) | **GET** /v1/backoffice/filter-proposals | New attribute options proposed by AI ingest (staff)
[**backofficeListModeration**](BackofficeApi.md#backofficelistmoderation) | **GET** /v1/backoffice/moderation | Open reports and automatic flags, oldest first
[**backofficeListPromoProducts**](BackofficeApi.md#backofficelistpromoproducts) | **GET** /v1/backoffice/promo-products | The promotion catalog including inactive products (staff)
[**backofficeListReviews**](BackofficeApi.md#backofficelistreviews) | **GET** /v1/backoffice/reviews | Moderation queue of submitted listing versions (staff)
[**backofficeListTemplates**](BackofficeApi.md#backofficelisttemplates) | **GET** /v1/backoffice/templates | Contract templates bundled with this release and their legal review state (staff)
[**backofficeListUsers**](BackofficeApi.md#backofficelistusers) | **GET** /v1/backoffice/users | Search users (staff)
[**backofficePreviewTemplate**](BackofficeApi.md#backofficepreviewtemplate) | **GET** /v1/backoffice/templates/{name}/preview | Render a template with sample data as a PDF (staff)
[**backofficeSetFeatureFlag**](BackofficeApi.md#backofficesetfeatureflag) | **PUT** /v1/backoffice/feature-flags/{key} | Turn a feature flag on or off (staff, audited)
[**backofficeUpdatePromoProduct**](BackofficeApi.md#backofficeupdatepromoproduct) | **PATCH** /v1/backoffice/promo-products/{productId} | Change price, duration, name or availability of a product (staff, audited)


# **backofficeCreatePromoProduct**
> PromoProduct backofficeCreatePromoProduct(promoProductInput)

Add a promotion product (staff, audited)

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
final promoProductInput = PromoProductInput(); // PromoProductInput | 

try {
    final result = api_instance.backofficeCreatePromoProduct(promoProductInput);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeCreatePromoProduct: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **promoProductInput** | [**PromoProductInput**](PromoProductInput.md)|  | 

### Return type

[**PromoProduct**](PromoProduct.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeDecideAttributeSuggestion**
> AttributeSuggestion backofficeDecideAttributeSuggestion(suggestionId, attributeSuggestionDecision)

Approve or reject an AI-proposed attribute (staff, audited)

A human decides (ADR 0003). Approval only records who approved it, when and the note; it does not change the attribute catalog, which a developer then extends in packages/attributes. A suggestion can be decided once.

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
final suggestionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final attributeSuggestionDecision = AttributeSuggestionDecision(); // AttributeSuggestionDecision | 

try {
    final result = api_instance.backofficeDecideAttributeSuggestion(suggestionId, attributeSuggestionDecision);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeDecideAttributeSuggestion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **suggestionId** | **String**|  | 
 **attributeSuggestionDecision** | [**AttributeSuggestionDecision**](AttributeSuggestionDecision.md)|  | 

### Return type

[**AttributeSuggestion**](AttributeSuggestion.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

# **backofficeDecideModeration**
> backofficeDecideModeration(caseId, backofficeDecideModerationRequest)

Resolve a case (human decision; the AI verdict is only a suggestion)

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
final caseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final backofficeDecideModerationRequest = BackofficeDecideModerationRequest(); // BackofficeDecideModerationRequest | 

try {
    api_instance.backofficeDecideModeration(caseId, backofficeDecideModerationRequest);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeDecideModeration: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **caseId** | **String**|  | 
 **backofficeDecideModerationRequest** | [**BackofficeDecideModerationRequest**](BackofficeDecideModerationRequest.md)|  | 

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

# **backofficeGetMetrics**
> BackofficeMetrics backofficeGetMetrics()

Platform metrics for the dashboard (staff)

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
    final result = api_instance.backofficeGetMetrics();
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeGetMetrics: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BackofficeMetrics**](BackofficeMetrics.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeGetModeration**
> ModerationCaseDetail backofficeGetModeration(caseId)

A case with the conversation transcript and the AI suggestion

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
final caseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.backofficeGetModeration(caseId);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeGetModeration: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **caseId** | **String**|  | 

### Return type

[**ModerationCaseDetail**](ModerationCaseDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

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

# **backofficeListAttributeSuggestions**
> AttributeSuggestionList backofficeListAttributeSuggestions(status)

New attributes proposed by AI ingest, waiting for a staff decision (ADR 0003)

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
    final result = api_instance.backofficeListAttributeSuggestions(status);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeListAttributeSuggestions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] [default to 'open']

### Return type

[**AttributeSuggestionList**](AttributeSuggestionList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
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

# **backofficeListFeatureFlags**
> FeatureFlagList backofficeListFeatureFlags()

Feature flags with their source (database row or config default) (staff)

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
    final result = api_instance.backofficeListFeatureFlags();
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeListFeatureFlags: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**FeatureFlagList**](FeatureFlagList.md)

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

# **backofficeListModeration**
> List<ModerationCase> backofficeListModeration(after, limit)

Open reports and automatic flags, oldest first

Paged oldest first: a full page may have more; pass the last item's id as `after`.

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
final after = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Cursor of oldest-first lists; return items with an id greater than this one.
final limit = 56; // int | 

try {
    final result = api_instance.backofficeListModeration(after, limit);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeListModeration: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **after** | **String**| Cursor of oldest-first lists; return items with an id greater than this one. | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**List<ModerationCase>**](ModerationCase.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeListPromoProducts**
> PromoProductList backofficeListPromoProducts()

The promotion catalog including inactive products (staff)

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
    final result = api_instance.backofficeListPromoProducts();
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeListPromoProducts: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PromoProductList**](PromoProductList.md)

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

# **backofficeListTemplates**
> ContractTemplateList backofficeListTemplates()

Contract templates bundled with this release and their legal review state (staff)

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
    final result = api_instance.backofficeListTemplates();
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeListTemplates: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ContractTemplateList**](ContractTemplateList.md)

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

# **backofficePreviewTemplate**
> MultipartFile backofficePreviewTemplate(name)

Render a template with sample data as a PDF (staff)

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
final name = name_example; // String | 

try {
    final result = api_instance.backofficePreviewTemplate(name);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficePreviewTemplate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**|  | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/pdf, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeSetFeatureFlag**
> FeatureFlag backofficeSetFeatureFlag(key, featureFlagInput)

Turn a feature flag on or off (staff, audited)

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
final key = key_example; // String | 
final featureFlagInput = FeatureFlagInput(); // FeatureFlagInput | 

try {
    final result = api_instance.backofficeSetFeatureFlag(key, featureFlagInput);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeSetFeatureFlag: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **key** | **String**|  | 
 **featureFlagInput** | [**FeatureFlagInput**](FeatureFlagInput.md)|  | 

### Return type

[**FeatureFlag**](FeatureFlag.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **backofficeUpdatePromoProduct**
> PromoProduct backofficeUpdatePromoProduct(productId, promoProductPatch)

Change price, duration, name or availability of a product (staff, audited)

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
final productId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final promoProductPatch = PromoProductPatch(); // PromoProductPatch | 

try {
    final result = api_instance.backofficeUpdatePromoProduct(productId, promoProductPatch);
    print(result);
} catch (e) {
    print('Exception when calling BackofficeApi->backofficeUpdatePromoProduct: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **productId** | **String**|  | 
 **promoProductPatch** | [**PromoProductPatch**](PromoProductPatch.md)|  | 

### Return type

[**PromoProduct**](PromoProduct.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

