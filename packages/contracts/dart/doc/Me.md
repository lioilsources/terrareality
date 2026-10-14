# terra_api.model.Me

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**email** | **String** |  | 
**emailVerified** | **bool** |  | 
**displayName** | **String** |  | 
**locale** | [**UserLocale**](UserLocale.md) |  | 
**phone** | **String** |  | [optional] 
**phoneVerified** | **bool** |  | 
**verificationLevel** | [**VerificationLevel**](VerificationLevel.md) |  | 
**identity** | [**VerifiedIdentity**](VerifiedIdentity.md) |  | [optional] 
**mfaEnabled** | **bool** |  | 
**recoveryCodesLeft** | **int** |  | [optional] 
**hasPassword** | **bool** |  | [optional] 
**isStaff** | **bool** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**impersonator** | [**UserRef**](UserRef.md) |  | [optional] 
**organizations** | [**List<OrgMembership>**](OrgMembership.md) |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


