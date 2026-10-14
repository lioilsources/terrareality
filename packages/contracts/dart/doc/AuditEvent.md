# terra_api.model.AuditEvent

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**occurredAt** | [**DateTime**](DateTime.md) |  | 
**actorId** | **String** |  | [optional] 
**actorEmail** | **String** |  | [optional] 
**impersonatorId** | **String** |  | [optional] 
**orgId** | **String** |  | [optional] 
**entity** | **String** |  | 
**entityId** | **String** |  | [optional] 
**action** | **String** |  | 
**diff** | [**Map<String, Object>**](Object.md) |  | [default to const {}]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


