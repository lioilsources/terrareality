# terra_api.model.ModerationCase

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**kind** | **String** | What was reported. | 
**source_** | **String** |  | 
**conversationId** | **String** | Set for conversation cases. | [optional] 
**listingId** | **String** | The reported listing (listing cases) or the conversation's listing. | [optional] 
**messageId** | **String** |  | [optional] 
**reason** | **String** |  | 
**note** | **String** |  | [optional] 
**status** | **String** |  | 
**reporterName** | **String** |  | [optional] 
**reporterEmail** | **String** |  | [optional] 
**reporterAnonymous** | **bool** | The reporter was not signed in (listing reports). | [optional] 
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


