# terra_api.model.RegisterRequest

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**email** | **String** |  | 
**password** | **String** | At least 12 characters; checked against breached-password lists (error code password_breached). | 
**displayName** | **String** |  | 
**locale** | [**UserLocale**](UserLocale.md) |  | [optional] 
**acceptTermsVersion** | **String** |  | 
**acceptPrivacyVersion** | **String** |  | 
**marketing** | **bool** |  | [optional] [default to false]
**client** | [**ClientKind**](ClientKind.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


