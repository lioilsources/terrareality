# terra_api.model.Conversation

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
**orgName** | **String** |  | 
**seekerId** | **String** |  | 
**seekerName** | **String** |  | 
**listingTitle** | [**I18nText**](I18nText.md) |  | 
**coverUrl** | **String** |  | [optional] 
**role** | [**ConversationRole**](ConversationRole.md) |  | 
**lastMessageAt** | [**DateTime**](DateTime.md) |  | 
**lastMessage** | **String** | Preview of the latest message. | 
**lastSenderId** | **String** |  | [optional] 
**unread** | **int** |  | 
**blocked** | **bool** |  | 
**blockedByMe** | **bool** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


