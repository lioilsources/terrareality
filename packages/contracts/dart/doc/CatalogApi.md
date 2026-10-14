# terra_api.api.CatalogApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**changeListingStatus**](CatalogApi.md#changelistingstatus) | **POST** /v1/orgs/{orgId}/listings/{listingId}/status | Pause, resume, mark as rented or archive
[**completeMediaUpload**](CatalogApi.md#completemediaupload) | **POST** /v1/orgs/{orgId}/media/{mediaId}/complete | Start processing (EXIF strip, malware scan, vision) after the upload
[**createListing**](CatalogApi.md#createlisting) | **POST** /v1/orgs/{orgId}/listings | Wizard step 1 – address and unit; creates a draft listing
[**createMediaUpload**](CatalogApi.md#createmediaupload) | **POST** /v1/orgs/{orgId}/listings/{listingId}/media | Reserve a photo and get a presigned upload URL (PUT the file there, then complete)
[**decideSuggestion**](CatalogApi.md#decidesuggestion) | **POST** /v1/orgs/{orgId}/suggestions/{suggestionId}/decision | Accept (all or selected attributes) or reject an AI suggestion
[**deleteMedia**](CatalogApi.md#deletemedia) | **DELETE** /v1/orgs/{orgId}/media/{mediaId} | Remove a photo
[**duplicateListing**](CatalogApi.md#duplicatelisting) | **POST** /v1/orgs/{orgId}/listings/{listingId}/duplicate | Copy the listing onto a new unit in the same building (without photos)
[**getAttributeSchema**](CatalogApi.md#getattributeschema) | **GET** /v1/attributes | Listing attribute schema (catalog plus approved options)
[**getListing**](CatalogApi.md#getlisting) | **GET** /v1/orgs/{orgId}/listings/{listingId} | Listing with unit, address, photos, AI suggestions and versions
[**listListings**](CatalogApi.md#listlistings) | **GET** /v1/orgs/{orgId}/listings | Listings of an organization
[**requestSuggestion**](CatalogApi.md#requestsuggestion) | **POST** /v1/orgs/{orgId}/listings/{listingId}/suggestions | Ask the AI for attribute or text suggestions (generated in the background)
[**searchAddresses**](CatalogApi.md#searchaddresses) | **GET** /v1/addresses/search | Autocomplete Czech addresses (RÚIAN)
[**submitListing**](CatalogApi.md#submitlisting) | **POST** /v1/orgs/{orgId}/listings/{listingId}/submit | Send the working copy to moderation as a new version
[**updateListing**](CatalogApi.md#updatelisting) | **PUT** /v1/orgs/{orgId}/listings/{listingId} | Save the working copy (withdraws a pending review)
[**updateMedia**](CatalogApi.md#updatemedia) | **PATCH** /v1/orgs/{orgId}/media/{mediaId} | Change order and caption


# **changeListingStatus**
> Listing changeListingStatus(orgId, listingId, changeListingStatusRequest)

Pause, resume, mark as rented or archive

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final changeListingStatusRequest = ChangeListingStatusRequest(); // ChangeListingStatusRequest | 

try {
    final result = api_instance.changeListingStatus(orgId, listingId, changeListingStatusRequest);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->changeListingStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 
 **changeListingStatusRequest** | [**ChangeListingStatusRequest**](ChangeListingStatusRequest.md)|  | 

### Return type

[**Listing**](Listing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **completeMediaUpload**
> Media completeMediaUpload(orgId, mediaId)

Start processing (EXIF strip, malware scan, vision) after the upload

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final mediaId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.completeMediaUpload(orgId, mediaId);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->completeMediaUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **mediaId** | **String**|  | 

### Return type

[**Media**](Media.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createListing**
> Listing createListing(orgId, listingCreate)

Wizard step 1 – address and unit; creates a draft listing

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingCreate = ListingCreate(); // ListingCreate | 

try {
    final result = api_instance.createListing(orgId, listingCreate);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->createListing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingCreate** | [**ListingCreate**](ListingCreate.md)|  | 

### Return type

[**Listing**](Listing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createMediaUpload**
> MediaUpload createMediaUpload(orgId, listingId, mediaUploadRequest)

Reserve a photo and get a presigned upload URL (PUT the file there, then complete)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final mediaUploadRequest = MediaUploadRequest(); // MediaUploadRequest | 

try {
    final result = api_instance.createMediaUpload(orgId, listingId, mediaUploadRequest);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->createMediaUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 
 **mediaUploadRequest** | [**MediaUploadRequest**](MediaUploadRequest.md)|  | 

### Return type

[**MediaUpload**](MediaUpload.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **decideSuggestion**
> Suggestion decideSuggestion(orgId, suggestionId, suggestionDecision)

Accept (all or selected attributes) or reject an AI suggestion

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final suggestionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final suggestionDecision = SuggestionDecision(); // SuggestionDecision | 

try {
    final result = api_instance.decideSuggestion(orgId, suggestionId, suggestionDecision);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->decideSuggestion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **suggestionId** | **String**|  | 
 **suggestionDecision** | [**SuggestionDecision**](SuggestionDecision.md)|  | 

### Return type

[**Suggestion**](Suggestion.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMedia**
> deleteMedia(orgId, mediaId)

Remove a photo

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final mediaId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteMedia(orgId, mediaId);
} catch (e) {
    print('Exception when calling CatalogApi->deleteMedia: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **mediaId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **duplicateListing**
> Listing duplicateListing(orgId, listingId)

Copy the listing onto a new unit in the same building (without photos)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.duplicateListing(orgId, listingId);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->duplicateListing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 

### Return type

[**Listing**](Listing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAttributeSchema**
> AttributeSchema getAttributeSchema()

Listing attribute schema (catalog plus approved options)

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = CatalogApi();

try {
    final result = api_instance.getAttributeSchema();
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->getAttributeSchema: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AttributeSchema**](AttributeSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getListing**
> Listing getListing(orgId, listingId)

Listing with unit, address, photos, AI suggestions and versions

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getListing(orgId, listingId);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->getListing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 

### Return type

[**Listing**](Listing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listListings**
> List<ListingSummary> listListings(orgId, status)

Listings of an organization

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final status = ; // ListingStatus | 

try {
    final result = api_instance.listListings(orgId, status);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->listListings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **status** | [**ListingStatus**](.md)|  | [optional] 

### Return type

[**List<ListingSummary>**](ListingSummary.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestSuggestion**
> Suggestion requestSuggestion(orgId, listingId, requestSuggestionRequest)

Ask the AI for attribute or text suggestions (generated in the background)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final requestSuggestionRequest = RequestSuggestionRequest(); // RequestSuggestionRequest | 

try {
    final result = api_instance.requestSuggestion(orgId, listingId, requestSuggestionRequest);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->requestSuggestion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 
 **requestSuggestionRequest** | [**RequestSuggestionRequest**](RequestSuggestionRequest.md)|  | 

### Return type

[**Suggestion**](Suggestion.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchAddresses**
> List<AddressSuggestion> searchAddresses(q, limit)

Autocomplete Czech addresses (RÚIAN)

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = CatalogApi();
final q = q_example; // String | 
final limit = 56; // int | 

try {
    final result = api_instance.searchAddresses(q, limit);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->searchAddresses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | 
 **limit** | **int**|  | [optional] [default to 8]

### Return type

[**List<AddressSuggestion>**](AddressSuggestion.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitListing**
> Listing submitListing(orgId, listingId)

Send the working copy to moderation as a new version

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.submitListing(orgId, listingId);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->submitListing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 

### Return type

[**Listing**](Listing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateListing**
> Listing updateListing(orgId, listingId, listingUpdate)

Save the working copy (withdraws a pending review)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingUpdate = ListingUpdate(); // ListingUpdate | 

try {
    final result = api_instance.updateListing(orgId, listingId, listingUpdate);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->updateListing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 
 **listingUpdate** | [**ListingUpdate**](ListingUpdate.md)|  | 

### Return type

[**Listing**](Listing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMedia**
> Media updateMedia(orgId, mediaId, mediaUpdate)

Change order and caption

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CatalogApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final mediaId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final mediaUpdate = MediaUpdate(); // MediaUpdate | 

try {
    final result = api_instance.updateMedia(orgId, mediaId, mediaUpdate);
    print(result);
} catch (e) {
    print('Exception when calling CatalogApi->updateMedia: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **mediaId** | **String**|  | 
 **mediaUpdate** | [**MediaUpdate**](MediaUpdate.md)|  | 

### Return type

[**Media**](Media.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

