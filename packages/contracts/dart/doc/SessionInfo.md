# terra_api.model.SessionInfo

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**client** | **String** |  | 
**expiresAt** | [**DateTime**](DateTime.md) | When the session ends unless it is used again (impersonation sessions do not slide). | 
**userAgent** | **String** |  | [optional] 
**ip** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**lastSeenAt** | [**DateTime**](DateTime.md) |  | 
**current** | **bool** |  | 
**impersonated** | **bool** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


