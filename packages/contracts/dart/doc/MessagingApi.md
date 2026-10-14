# terra_api.api.MessagingApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**completeAttachmentUpload**](MessagingApi.md#completeattachmentupload) | **POST** /v1/attachments/{attachmentId}/complete | Check the uploaded file (type, size, malware) so it can be sent
[**conversationRealtimeToken**](MessagingApi.md#conversationrealtimetoken) | **POST** /v1/conversations/{conversationId}/realtime-token | Subscription token for the conversation's realtime channel
[**createAttachmentUpload**](MessagingApi.md#createattachmentupload) | **POST** /v1/conversations/{conversationId}/attachments | Reserve an attachment and get a presigned upload URL (PUT the file there, then complete)
[**createReplyTemplate**](MessagingApi.md#createreplytemplate) | **POST** /v1/orgs/{orgId}/reply-templates | Create a reply template
[**deleteReplyTemplate**](MessagingApi.md#deletereplytemplate) | **DELETE** /v1/orgs/{orgId}/reply-templates/{templateId} | Delete a reply template
[**getConversation**](MessagingApi.md#getconversation) | **GET** /v1/conversations/{conversationId} | Conversation with read receipts and pre-screening answers
[**getPushConfig**](MessagingApi.md#getpushconfig) | **GET** /v1/push/config | Public key for browser push subscriptions (VAPID)
[**listConversations**](MessagingApi.md#listconversations) | **GET** /v1/conversations | My conversations (as a seeker and for my organizations), newest first
[**listMessages**](MessagingApi.md#listmessages) | **GET** /v1/conversations/{conversationId}/messages | Messages, newest first
[**listReplyTemplates**](MessagingApi.md#listreplytemplates) | **GET** /v1/orgs/{orgId}/reply-templates | Reply templates of the organization
[**markConversationRead**](MessagingApi.md#markconversationread) | **POST** /v1/conversations/{conversationId}/read | Mark the conversation read up to now (read receipt)
[**realtimeToken**](MessagingApi.md#realtimetoken) | **POST** /v1/realtime/token | Connection token for Centrifugo; the connection joins the caller's user channel
[**reportConversation**](MessagingApi.md#reportconversation) | **POST** /v1/conversations/{conversationId}/reports | Report the conversation or one message to the moderators
[**sendMessage**](MessagingApi.md#sendmessage) | **POST** /v1/conversations/{conversationId}/messages | Send a message. Contact details are masked and flagged, never blocked.
[**setConversationBlocked**](MessagingApi.md#setconversationblocked) | **PUT** /v1/conversations/{conversationId}/block | Block or unblock the conversation
[**setListingPrescreen**](MessagingApi.md#setlistingprescreen) | **PUT** /v1/orgs/{orgId}/listings/{listingId}/prescreen | Replace the questions a seeker answers before the first message
[**startConversation**](MessagingApi.md#startconversation) | **POST** /v1/conversations | Contact the landlord of a published listing (reuses an existing conversation)
[**updateReplyTemplate**](MessagingApi.md#updatereplytemplate) | **PUT** /v1/orgs/{orgId}/reply-templates/{templateId} | Update a reply template


# **completeAttachmentUpload**
> Attachment completeAttachmentUpload(attachmentId)

Check the uploaded file (type, size, malware) so it can be sent

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final attachmentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.completeAttachmentUpload(attachmentId);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->completeAttachmentUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **attachmentId** | **String**|  | 

### Return type

[**Attachment**](Attachment.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **conversationRealtimeToken**
> SubscriptionToken conversationRealtimeToken(conversationId)

Subscription token for the conversation's realtime channel

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final conversationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.conversationRealtimeToken(conversationId);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->conversationRealtimeToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**|  | 

### Return type

[**SubscriptionToken**](SubscriptionToken.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createAttachmentUpload**
> AttachmentUpload createAttachmentUpload(conversationId, createAttachmentUploadRequest)

Reserve an attachment and get a presigned upload URL (PUT the file there, then complete)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final conversationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final createAttachmentUploadRequest = CreateAttachmentUploadRequest(); // CreateAttachmentUploadRequest | 

try {
    final result = api_instance.createAttachmentUpload(conversationId, createAttachmentUploadRequest);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->createAttachmentUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**|  | 
 **createAttachmentUploadRequest** | [**CreateAttachmentUploadRequest**](CreateAttachmentUploadRequest.md)|  | 

### Return type

[**AttachmentUpload**](AttachmentUpload.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createReplyTemplate**
> ReplyTemplate createReplyTemplate(orgId, replyTemplateInput)

Create a reply template

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final replyTemplateInput = ReplyTemplateInput(); // ReplyTemplateInput | 

try {
    final result = api_instance.createReplyTemplate(orgId, replyTemplateInput);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->createReplyTemplate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **replyTemplateInput** | [**ReplyTemplateInput**](ReplyTemplateInput.md)|  | 

### Return type

[**ReplyTemplate**](ReplyTemplate.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteReplyTemplate**
> deleteReplyTemplate(orgId, templateId)

Delete a reply template

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final templateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteReplyTemplate(orgId, templateId);
} catch (e) {
    print('Exception when calling MessagingApi->deleteReplyTemplate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **templateId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getConversation**
> ConversationDetail getConversation(conversationId)

Conversation with read receipts and pre-screening answers

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final conversationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getConversation(conversationId);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->getConversation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**|  | 

### Return type

[**ConversationDetail**](ConversationDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPushConfig**
> GetPushConfig200Response getPushConfig()

Public key for browser push subscriptions (VAPID)

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = MessagingApi();

try {
    final result = api_instance.getPushConfig();
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->getPushConfig: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**GetPushConfig200Response**](GetPushConfig200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listConversations**
> List<Conversation> listConversations(orgId, as_)

My conversations (as a seeker and for my organizations), newest first

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Only this organization's inbox.
final as_ = as__example; // String | seeker = only conversations I started.

try {
    final result = api_instance.listConversations(orgId, as_);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->listConversations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**| Only this organization's inbox. | [optional] 
 **as_** | **String**| seeker = only conversations I started. | [optional] 

### Return type

[**List<Conversation>**](Conversation.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMessages**
> List<Message> listMessages(conversationId, before, limit)

Messages, newest first

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final conversationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final before = 2013-10-20T19:20:30+01:00; // DateTime | Return messages older than this time.
final limit = 56; // int | 

try {
    final result = api_instance.listMessages(conversationId, before, limit);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->listMessages: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**|  | 
 **before** | **DateTime**| Return messages older than this time. | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**List<Message>**](Message.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listReplyTemplates**
> List<ReplyTemplate> listReplyTemplates(orgId)

Reply templates of the organization

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listReplyTemplates(orgId);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->listReplyTemplates: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**List<ReplyTemplate>**](ReplyTemplate.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markConversationRead**
> markConversationRead(conversationId)

Mark the conversation read up to now (read receipt)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final conversationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.markConversationRead(conversationId);
} catch (e) {
    print('Exception when calling MessagingApi->markConversationRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **realtimeToken**
> RealtimeToken realtimeToken()

Connection token for Centrifugo; the connection joins the caller's user channel

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();

try {
    final result = api_instance.realtimeToken();
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->realtimeToken: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**RealtimeToken**](RealtimeToken.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportConversation**
> ReportConversation201Response reportConversation(conversationId, reportInput)

Report the conversation or one message to the moderators

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final conversationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final reportInput = ReportInput(); // ReportInput | 

try {
    final result = api_instance.reportConversation(conversationId, reportInput);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->reportConversation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**|  | 
 **reportInput** | [**ReportInput**](ReportInput.md)|  | 

### Return type

[**ReportConversation201Response**](ReportConversation201Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendMessage**
> SentMessage sendMessage(conversationId, messageInput)

Send a message. Contact details are masked and flagged, never blocked.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final conversationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final messageInput = MessageInput(); // MessageInput | 

try {
    final result = api_instance.sendMessage(conversationId, messageInput);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->sendMessage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**|  | 
 **messageInput** | [**MessageInput**](MessageInput.md)|  | 

### Return type

[**SentMessage**](SentMessage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setConversationBlocked**
> setConversationBlocked(conversationId, setConversationBlockedRequest)

Block or unblock the conversation

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final conversationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final setConversationBlockedRequest = SetConversationBlockedRequest(); // SetConversationBlockedRequest | 

try {
    api_instance.setConversationBlocked(conversationId, setConversationBlockedRequest);
} catch (e) {
    print('Exception when calling MessagingApi->setConversationBlocked: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**|  | 
 **setConversationBlockedRequest** | [**SetConversationBlockedRequest**](SetConversationBlockedRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setListingPrescreen**
> List<PrescreenQuestion> setListingPrescreen(orgId, listingId, prescreenQuestion)

Replace the questions a seeker answers before the first message

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final prescreenQuestion = [List<PrescreenQuestion>()]; // List<PrescreenQuestion> | 

try {
    final result = api_instance.setListingPrescreen(orgId, listingId, prescreenQuestion);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->setListingPrescreen: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 
 **prescreenQuestion** | [**List<PrescreenQuestion>**](PrescreenQuestion.md)|  | 

### Return type

[**List<PrescreenQuestion>**](PrescreenQuestion.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startConversation**
> SentMessage startConversation(startConversation)

Contact the landlord of a published listing (reuses an existing conversation)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final startConversation = StartConversation(); // StartConversation | 

try {
    final result = api_instance.startConversation(startConversation);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->startConversation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **startConversation** | [**StartConversation**](StartConversation.md)|  | 

### Return type

[**SentMessage**](SentMessage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateReplyTemplate**
> ReplyTemplate updateReplyTemplate(orgId, templateId, replyTemplateInput)

Update a reply template

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MessagingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final templateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final replyTemplateInput = ReplyTemplateInput(); // ReplyTemplateInput | 

try {
    final result = api_instance.updateReplyTemplate(orgId, templateId, replyTemplateInput);
    print(result);
} catch (e) {
    print('Exception when calling MessagingApi->updateReplyTemplate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **templateId** | **String**|  | 
 **replyTemplateInput** | [**ReplyTemplateInput**](ReplyTemplateInput.md)|  | 

### Return type

[**ReplyTemplate**](ReplyTemplate.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

