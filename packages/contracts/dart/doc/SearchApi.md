# terra_api.api.SearchApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**chatSearch**](SearchApi.md#chatsearch) | **POST** /v1/search/chat | Natural-language search – turns a message into filters and a map area, then searches
[**createSavedSearch**](SearchApi.md#createsavedsearch) | **POST** /v1/me/saved-searches | Save a search; new matching listings are e-mailed daily when notify is on
[**deleteSavedSearch**](SearchApi.md#deletesavedsearch) | **DELETE** /v1/me/saved-searches/{savedSearchId} | Delete a saved search
[**getPublicListing**](SearchApi.md#getpubliclisting) | **GET** /v1/listings/{listingId} | Published listing (approved version only)
[**getSimilarListings**](SearchApi.md#getsimilarlistings) | **GET** /v1/listings/{listingId}/similar | Similar listings (embeddings when available, otherwise kind, price and distance)
[**listAreas**](SearchApi.md#listareas) | **GET** /v1/areas | Child administrative units with simplified outlines (regions when parent is empty)
[**listSavedSearches**](SearchApi.md#listsavedsearches) | **GET** /v1/me/saved-searches | My saved searches
[**listSeoMunicipalities**](SearchApi.md#listseomunicipalities) | **GET** /v1/seo/municipalities | Municipalities with at least one listing (static site pages)
[**reportListing**](SearchApi.md#reportlisting) | **POST** /v1/listings/{listingId}/reports | Report a published listing to the moderators (DSA notice, art. 16)
[**search**](SearchApi.md#search) | **POST** /v1/search | Faceted search over published listings with map aggregates


# **chatSearch**
> ChatResponse chatSearch(chatRequest)

Natural-language search – turns a message into filters and a map area, then searches

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = SearchApi();
final chatRequest = ChatRequest(); // ChatRequest | 

try {
    final result = api_instance.chatSearch(chatRequest);
    print(result);
} catch (e) {
    print('Exception when calling SearchApi->chatSearch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatRequest** | [**ChatRequest**](ChatRequest.md)|  | 

### Return type

[**ChatResponse**](ChatResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createSavedSearch**
> SavedSearch createSavedSearch(savedSearchInput)

Save a search; new matching listings are e-mailed daily when notify is on

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SearchApi();
final savedSearchInput = SavedSearchInput(); // SavedSearchInput | 

try {
    final result = api_instance.createSavedSearch(savedSearchInput);
    print(result);
} catch (e) {
    print('Exception when calling SearchApi->createSavedSearch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **savedSearchInput** | [**SavedSearchInput**](SavedSearchInput.md)|  | 

### Return type

[**SavedSearch**](SavedSearch.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteSavedSearch**
> deleteSavedSearch(savedSearchId)

Delete a saved search

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SearchApi();
final savedSearchId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteSavedSearch(savedSearchId);
} catch (e) {
    print('Exception when calling SearchApi->deleteSavedSearch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **savedSearchId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublicListing**
> PublicListing getPublicListing(listingId)

Published listing (approved version only)

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = SearchApi();
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPublicListing(listingId);
    print(result);
} catch (e) {
    print('Exception when calling SearchApi->getPublicListing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **listingId** | **String**|  | 

### Return type

[**PublicListing**](PublicListing.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSimilarListings**
> List<ListingCard> getSimilarListings(listingId)

Similar listings (embeddings when available, otherwise kind, price and distance)

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = SearchApi();
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getSimilarListings(listingId);
    print(result);
} catch (e) {
    print('Exception when calling SearchApi->getSimilarListings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **listingId** | **String**|  | 

### Return type

[**List<ListingCard>**](ListingCard.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAreas**
> List<Area> listAreas(parent)

Child administrative units with simplified outlines (regions when parent is empty)

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = SearchApi();
final parent = parent_example; // String | 

try {
    final result = api_instance.listAreas(parent);
    print(result);
} catch (e) {
    print('Exception when calling SearchApi->listAreas: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **parent** | **String**|  | [optional] 

### Return type

[**List<Area>**](Area.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSavedSearches**
> List<SavedSearch> listSavedSearches()

My saved searches

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SearchApi();

try {
    final result = api_instance.listSavedSearches();
    print(result);
} catch (e) {
    print('Exception when calling SearchApi->listSavedSearches: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<SavedSearch>**](SavedSearch.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSeoMunicipalities**
> List<MunicipalityStat> listSeoMunicipalities(kind)

Municipalities with at least one listing (static site pages)

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = SearchApi();
final kind = ; // UnitKind | 

try {
    final result = api_instance.listSeoMunicipalities(kind);
    print(result);
} catch (e) {
    print('Exception when calling SearchApi->listSeoMunicipalities: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **kind** | [**UnitKind**](.md)|  | [optional] 

### Return type

[**List<MunicipalityStat>**](MunicipalityStat.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportListing**
> ListingReportCreated reportListing(listingId, listingReportInput)

Report a published listing to the moderators (DSA notice, art. 16)

Open to signed-in users and anonymous visitors. Anonymous reporters give an e-mail address for the acknowledgement and the statement of reasons; signed-in reporters use their account e-mail. Staff decide every report (ADR 0003). Rate-limited per user or client IP.

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = SearchApi();
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingReportInput = ListingReportInput(); // ListingReportInput | 

try {
    final result = api_instance.reportListing(listingId, listingReportInput);
    print(result);
} catch (e) {
    print('Exception when calling SearchApi->reportListing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **listingId** | **String**|  | 
 **listingReportInput** | [**ListingReportInput**](ListingReportInput.md)|  | 

### Return type

[**ListingReportCreated**](ListingReportCreated.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **search**
> SearchResult search(searchQuery)

Faceted search over published listings with map aggregates

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = SearchApi();
final searchQuery = SearchQuery(); // SearchQuery | 

try {
    final result = api_instance.search(searchQuery);
    print(result);
} catch (e) {
    print('Exception when calling SearchApi->search: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **searchQuery** | [**SearchQuery**](SearchQuery.md)|  | 

### Return type

[**SearchResult**](SearchResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

