//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MessagingApi {
  MessagingApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Check the uploaded file (type, size, malware) so it can be sent
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] attachmentId (required):
  Future<Response> completeAttachmentUploadWithHttpInfo(String attachmentId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/attachments/{attachmentId}/complete'
      .replaceAll('{attachmentId}', attachmentId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Check the uploaded file (type, size, malware) so it can be sent
  ///
  /// Parameters:
  ///
  /// * [String] attachmentId (required):
  Future<Attachment?> completeAttachmentUpload(String attachmentId,) async {
    final response = await completeAttachmentUploadWithHttpInfo(attachmentId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Attachment',) as Attachment;
    
    }
    return null;
  }

  /// Subscription token for the conversation's realtime channel
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  Future<Response> conversationRealtimeTokenWithHttpInfo(String conversationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations/{conversationId}/realtime-token'
      .replaceAll('{conversationId}', conversationId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Subscription token for the conversation's realtime channel
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  Future<SubscriptionToken?> conversationRealtimeToken(String conversationId,) async {
    final response = await conversationRealtimeTokenWithHttpInfo(conversationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SubscriptionToken',) as SubscriptionToken;
    
    }
    return null;
  }

  /// Reserve an attachment and get a presigned upload URL (PUT the file there, then complete)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [CreateAttachmentUploadRequest] createAttachmentUploadRequest (required):
  Future<Response> createAttachmentUploadWithHttpInfo(String conversationId, CreateAttachmentUploadRequest createAttachmentUploadRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations/{conversationId}/attachments'
      .replaceAll('{conversationId}', conversationId);

    // ignore: prefer_final_locals
    Object? postBody = createAttachmentUploadRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Reserve an attachment and get a presigned upload URL (PUT the file there, then complete)
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [CreateAttachmentUploadRequest] createAttachmentUploadRequest (required):
  Future<AttachmentUpload?> createAttachmentUpload(String conversationId, CreateAttachmentUploadRequest createAttachmentUploadRequest,) async {
    final response = await createAttachmentUploadWithHttpInfo(conversationId, createAttachmentUploadRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AttachmentUpload',) as AttachmentUpload;
    
    }
    return null;
  }

  /// Create a reply template
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [ReplyTemplateInput] replyTemplateInput (required):
  Future<Response> createReplyTemplateWithHttpInfo(String orgId, ReplyTemplateInput replyTemplateInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/reply-templates'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = replyTemplateInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a reply template
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [ReplyTemplateInput] replyTemplateInput (required):
  Future<ReplyTemplate?> createReplyTemplate(String orgId, ReplyTemplateInput replyTemplateInput,) async {
    final response = await createReplyTemplateWithHttpInfo(orgId, replyTemplateInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ReplyTemplate',) as ReplyTemplate;
    
    }
    return null;
  }

  /// Delete a reply template
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] templateId (required):
  Future<Response> deleteReplyTemplateWithHttpInfo(String orgId, String templateId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/reply-templates/{templateId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{templateId}', templateId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete a reply template
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] templateId (required):
  Future<void> deleteReplyTemplate(String orgId, String templateId,) async {
    final response = await deleteReplyTemplateWithHttpInfo(orgId, templateId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Conversation with read receipts and pre-screening answers
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  Future<Response> getConversationWithHttpInfo(String conversationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations/{conversationId}'
      .replaceAll('{conversationId}', conversationId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Conversation with read receipts and pre-screening answers
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  Future<ConversationDetail?> getConversation(String conversationId,) async {
    final response = await getConversationWithHttpInfo(conversationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ConversationDetail',) as ConversationDetail;
    
    }
    return null;
  }

  /// Public key for browser push subscriptions (VAPID)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getPushConfigWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/push/config';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Public key for browser push subscriptions (VAPID)
  Future<GetPushConfig200Response?> getPushConfig() async {
    final response = await getPushConfigWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'GetPushConfig200Response',) as GetPushConfig200Response;
    
    }
    return null;
  }

  /// My conversations (as a seeker and for my organizations), newest first
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId:
  ///   Only this organization's inbox.
  ///
  /// * [String] as_:
  ///   seeker = only conversations I started.
  Future<Response> listConversationsWithHttpInfo({ String? orgId, String? as_, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (orgId != null) {
      queryParams.addAll(_queryParams('', 'org_id', orgId));
    }
    if (as_ != null) {
      queryParams.addAll(_queryParams('', 'as', as_));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// My conversations (as a seeker and for my organizations), newest first
  ///
  /// Parameters:
  ///
  /// * [String] orgId:
  ///   Only this organization's inbox.
  ///
  /// * [String] as_:
  ///   seeker = only conversations I started.
  Future<List<Conversation>?> listConversations({ String? orgId, String? as_, }) async {
    final response = await listConversationsWithHttpInfo( orgId: orgId, as_: as_, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Conversation>') as List)
        .cast<Conversation>()
        .toList(growable: false);

    }
    return null;
  }

  /// Messages, newest first
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [DateTime] before:
  ///   Return messages older than this time.
  ///
  /// * [int] limit:
  Future<Response> listMessagesWithHttpInfo(String conversationId, { DateTime? before, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations/{conversationId}/messages'
      .replaceAll('{conversationId}', conversationId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (before != null) {
      queryParams.addAll(_queryParams('', 'before', before));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Messages, newest first
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [DateTime] before:
  ///   Return messages older than this time.
  ///
  /// * [int] limit:
  Future<List<Message>?> listMessages(String conversationId, { DateTime? before, int? limit, }) async {
    final response = await listMessagesWithHttpInfo(conversationId,  before: before, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Message>') as List)
        .cast<Message>()
        .toList(growable: false);

    }
    return null;
  }

  /// Reply templates of the organization
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> listReplyTemplatesWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/reply-templates'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Reply templates of the organization
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<List<ReplyTemplate>?> listReplyTemplates(String orgId,) async {
    final response = await listReplyTemplatesWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<ReplyTemplate>') as List)
        .cast<ReplyTemplate>()
        .toList(growable: false);

    }
    return null;
  }

  /// Mark the conversation read up to now (read receipt)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  Future<Response> markConversationReadWithHttpInfo(String conversationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations/{conversationId}/read'
      .replaceAll('{conversationId}', conversationId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Mark the conversation read up to now (read receipt)
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  Future<void> markConversationRead(String conversationId,) async {
    final response = await markConversationReadWithHttpInfo(conversationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Connection token for Centrifugo; the connection joins the caller's user channel
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> realtimeTokenWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/realtime/token';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Connection token for Centrifugo; the connection joins the caller's user channel
  Future<RealtimeToken?> realtimeToken() async {
    final response = await realtimeTokenWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RealtimeToken',) as RealtimeToken;
    
    }
    return null;
  }

  /// Report the conversation or one message to the moderators
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [ReportInput] reportInput (required):
  Future<Response> reportConversationWithHttpInfo(String conversationId, ReportInput reportInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations/{conversationId}/reports'
      .replaceAll('{conversationId}', conversationId);

    // ignore: prefer_final_locals
    Object? postBody = reportInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Report the conversation or one message to the moderators
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [ReportInput] reportInput (required):
  Future<ReportConversation201Response?> reportConversation(String conversationId, ReportInput reportInput,) async {
    final response = await reportConversationWithHttpInfo(conversationId, reportInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ReportConversation201Response',) as ReportConversation201Response;
    
    }
    return null;
  }

  /// Send a message. Contact details are masked and flagged, never blocked.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [MessageInput] messageInput (required):
  Future<Response> sendMessageWithHttpInfo(String conversationId, MessageInput messageInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations/{conversationId}/messages'
      .replaceAll('{conversationId}', conversationId);

    // ignore: prefer_final_locals
    Object? postBody = messageInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Send a message. Contact details are masked and flagged, never blocked.
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [MessageInput] messageInput (required):
  Future<SentMessage?> sendMessage(String conversationId, MessageInput messageInput,) async {
    final response = await sendMessageWithHttpInfo(conversationId, messageInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SentMessage',) as SentMessage;
    
    }
    return null;
  }

  /// Block or unblock the conversation
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [SetConversationBlockedRequest] setConversationBlockedRequest (required):
  Future<Response> setConversationBlockedWithHttpInfo(String conversationId, SetConversationBlockedRequest setConversationBlockedRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations/{conversationId}/block'
      .replaceAll('{conversationId}', conversationId);

    // ignore: prefer_final_locals
    Object? postBody = setConversationBlockedRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Block or unblock the conversation
  ///
  /// Parameters:
  ///
  /// * [String] conversationId (required):
  ///
  /// * [SetConversationBlockedRequest] setConversationBlockedRequest (required):
  Future<void> setConversationBlocked(String conversationId, SetConversationBlockedRequest setConversationBlockedRequest,) async {
    final response = await setConversationBlockedWithHttpInfo(conversationId, setConversationBlockedRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Replace the questions a seeker answers before the first message
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [List<PrescreenQuestion>] prescreenQuestion (required):
  Future<Response> setListingPrescreenWithHttpInfo(String orgId, String listingId, List<PrescreenQuestion> prescreenQuestion,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/prescreen'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

    // ignore: prefer_final_locals
    Object? postBody = prescreenQuestion;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Replace the questions a seeker answers before the first message
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [List<PrescreenQuestion>] prescreenQuestion (required):
  Future<List<PrescreenQuestion>?> setListingPrescreen(String orgId, String listingId, List<PrescreenQuestion> prescreenQuestion,) async {
    final response = await setListingPrescreenWithHttpInfo(orgId, listingId, prescreenQuestion,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PrescreenQuestion>') as List)
        .cast<PrescreenQuestion>()
        .toList(growable: false);

    }
    return null;
  }

  /// Contact the landlord of a published listing (reuses an existing conversation)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [StartConversation] startConversation (required):
  Future<Response> startConversationWithHttpInfo(StartConversation startConversation,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/conversations';

    // ignore: prefer_final_locals
    Object? postBody = startConversation;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Contact the landlord of a published listing (reuses an existing conversation)
  ///
  /// Parameters:
  ///
  /// * [StartConversation] startConversation (required):
  Future<SentMessage?> startConversation(StartConversation startConversation,) async {
    final response = await startConversationWithHttpInfo(startConversation,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SentMessage',) as SentMessage;
    
    }
    return null;
  }

  /// Update a reply template
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] templateId (required):
  ///
  /// * [ReplyTemplateInput] replyTemplateInput (required):
  Future<Response> updateReplyTemplateWithHttpInfo(String orgId, String templateId, ReplyTemplateInput replyTemplateInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/reply-templates/{templateId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{templateId}', templateId);

    // ignore: prefer_final_locals
    Object? postBody = replyTemplateInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Update a reply template
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] templateId (required):
  ///
  /// * [ReplyTemplateInput] replyTemplateInput (required):
  Future<ReplyTemplate?> updateReplyTemplate(String orgId, String templateId, ReplyTemplateInput replyTemplateInput,) async {
    final response = await updateReplyTemplateWithHttpInfo(orgId, templateId, replyTemplateInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ReplyTemplate',) as ReplyTemplate;
    
    }
    return null;
  }
}
