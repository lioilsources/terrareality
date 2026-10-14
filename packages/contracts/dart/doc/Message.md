# terra_api.model.Message

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**conversationId** | **String** |  | 
**senderId** | **String** |  | [optional] 
**kind** | **String** |  | 
**body** | **String** | Contact details are masked as [•••]. Empty when removed by a moderator. | 
**flags** | [**List<MessageFlag>**](MessageFlag.md) |  | [default to const []]
**removed** | **bool** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**attachments** | [**List<Attachment>**](Attachment.md) |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


