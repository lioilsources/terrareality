# terra_api.model.Application

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**listingId** | **String** |  | 
**orgId** | **String** |  | 
**listingTitle** | [**I18nText**](I18nText.md) |  | 
**groupId** | **String** |  | [optional] 
**groupName** | **String** |  | [optional] 
**status** | [**ApplicationStatus**](ApplicationStatus.md) |  | 
**rejectReason** | [**RejectReason**](RejectReason.md) |  | [optional] 
**message** | **String** |  | [optional] 
**preferredFrom** | [**DateTime**](DateTime.md) |  | [optional] 
**durationMonths** | **int** |  | [optional] 
**householdSize** | **int** |  | 
**consentNeeded** | **bool** | True when I am asked to consent (group application). | 
**myConsentAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**submittedAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


