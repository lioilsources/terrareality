# terra_api.api.SystemApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getHealth**](SystemApi.md#gethealth) | **GET** /healthz | Liveness and dependency health
[**getVersion**](SystemApi.md#getversion) | **GET** /v1/version | Build information


# **getHealth**
> Health getHealth()

Liveness and dependency health

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = SystemApi();

try {
    final result = api_instance.getHealth();
    print(result);
} catch (e) {
    print('Exception when calling SystemApi->getHealth: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Health**](Health.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getVersion**
> Version getVersion()

Build information

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = SystemApi();

try {
    final result = api_instance.getVersion();
    print(result);
} catch (e) {
    print('Exception when calling SystemApi->getVersion: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Version**](Version.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

