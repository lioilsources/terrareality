# terra_api.model.ModerationCase

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**source_** | **String** |  | 
**conversationId** | **String** |  | 
**messageId** | **String** |  | [optional] 
**reason** | **String** |  | 
**note** | **String** |  | [optional] 
**status** | **String** |  | 
**reporterName** | **String** |  | [optional] 
**reporterEmail** | **String** |  | [optional] 
**reportedId** | **String** |  | [optional] 
**reportedName** | **String** |  | [optional] 
**reportedEmail** | **String** |  | [optional] 
**listingTitle** | [**I18nText**](I18nText.md) |  | 
**messageBody** | **String** |  | 
**aiStatus** | **String** |  | 
**aiSuggestion** | [**ModerationSuggestion**](ModerationSuggestion.md) |  | [optional] 
**decision** | [**ModerationVerdict**](ModerationVerdict.md) |  | [optional] 
**decisionNote** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


