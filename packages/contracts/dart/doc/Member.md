# terra_api.model.Member

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**userId** | **String** |  | 
**email** | **String** | Omitted for callers with the viewer or investor role (except their own row). | [optional] 
**displayName** | **String** |  | 
**role** | [**Role**](Role.md) |  | 
**verificationLevel** | [**VerificationLevel**](VerificationLevel.md) |  | 
**joinedAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


