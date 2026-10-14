# terra_api.api.JurisdictionsApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getJurisdiction**](JurisdictionsApi.md#getjurisdiction) | **GET** /v1/jurisdictions/{code} | One jurisdiction
[**listJurisdictions**](JurisdictionsApi.md#listjurisdictions) | **GET** /v1/jurisdictions | Active jurisdictions and their rules


# **getJurisdiction**
> Jurisdiction getJurisdiction(code)

One jurisdiction

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = JurisdictionsApi();
final code = code_example; // String | 

try {
    final result = api_instance.getJurisdiction(code);
    print(result);
} catch (e) {
    print('Exception when calling JurisdictionsApi->getJurisdiction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **code** | **String**|  | 

### Return type

[**Jurisdiction**](Jurisdiction.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listJurisdictions**
> List<Jurisdiction> listJurisdictions()

Active jurisdictions and their rules

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = JurisdictionsApi();

try {
    final result = api_instance.listJurisdictions();
    print(result);
} catch (e) {
    print('Exception when calling JurisdictionsApi->listJurisdictions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Jurisdiction>**](Jurisdiction.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

