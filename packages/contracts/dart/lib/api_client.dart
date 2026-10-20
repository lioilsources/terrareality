//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiClient {
  ApiClient({this.basePath = 'http://localhost:8080', this.authentication,});

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
     _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType,
  ) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty ? '?${urlEncodedQueryParams.join('&')}' : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (
        body is MultipartFile && (contentType == null ||
        !contentType.toLowerCase().startsWith('multipart/form-data'))
      ) {
        final request = StreamedRequest(method, uri);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
          request.sink.add,
          onDone: request.sink.close,
          // ignore: avoid_types_on_closure_parameters
          onError: (Object error, StackTrace trace) => request.sink.close(),
          cancelOnError: true,
        );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request = MultipartRequest(method, uri);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
        ? formParams
        : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      switch(method) {
        case 'POST': return await _client.post(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'PUT': return await _client.put(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'DELETE': return await _client.delete(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'PATCH': return await _client.patch(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'HEAD': return await _client.head(uri, headers: nullableHeaderParams,);
        case 'GET': return await _client.get(uri, headers: nullableHeaderParams,);
      }
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }

    throw ApiException(
      HttpStatus.badRequest,
      'Invalid HTTP operation: $method $path',
    );
  }

  Future<dynamic> deserializeAsync(String value, String targetType, {bool growable = false,}) async =>
    // ignore: deprecated_member_use_from_same_package
    deserialize(value, targetType, growable: growable);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(String value, String targetType, {bool growable = false,}) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType = targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
      ? value
      : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(dynamic value, String targetType, {bool growable = false,}) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'AddressSuggestion':
          return AddressSuggestion.fromJson(value);
        case 'AdminUser':
          return AdminUser.fromJson(value);
        case 'AdminUserDetail':
          return AdminUserDetail.fromJson(value);
        case 'AdminUserPage':
          return AdminUserPage.fromJson(value);
        case 'Applicant':
          return Applicant.fromJson(value);
        case 'ApplicantPerson':
          return ApplicantPerson.fromJson(value);
        case 'Application':
          return Application.fromJson(value);
        case 'ApplicationConsent':
          return ApplicationConsent.fromJson(value);
        case 'ApplicationDetail':
          return ApplicationDetail.fromJson(value);
        case 'ApplicationInput':
          return ApplicationInput.fromJson(value);
        case 'ApplicationStatus':
          return ApplicationStatusTypeTransformer().decode(value);
        case 'ApplicationSummary':
          return ApplicationSummary.fromJson(value);
        case 'Area':
          return Area.fromJson(value);
        case 'AreaAggregate':
          return AreaAggregate.fromJson(value);
        case 'Attachment':
          return Attachment.fromJson(value);
        case 'AttachmentUpload':
          return AttachmentUpload.fromJson(value);
        case 'AttrFilter':
          return AttrFilter.fromJson(value);
        case 'AttributeDef':
          return AttributeDef.fromJson(value);
        case 'AttributeGroup':
          return AttributeGroup.fromJson(value);
        case 'AttributeOption':
          return AttributeOption.fromJson(value);
        case 'AttributeSchema':
          return AttributeSchema.fromJson(value);
        case 'AttributeSuggestion':
          return AttributeSuggestion.fromJson(value);
        case 'AttributeSuggestionDecision':
          return AttributeSuggestionDecision.fromJson(value);
        case 'AttributeSuggestionList':
          return AttributeSuggestionList.fromJson(value);
        case 'AttributeSuggestionOptionsInner':
          return AttributeSuggestionOptionsInner.fromJson(value);
        case 'AuditEvent':
          return AuditEvent.fromJson(value);
        case 'AuditPage':
          return AuditPage.fromJson(value);
        case 'AuthProvider':
          return AuthProvider.fromJson(value);
        case 'AuthResult':
          return AuthResult.fromJson(value);
        case 'BackofficeDecideModerationRequest':
          return BackofficeDecideModerationRequest.fromJson(value);
        case 'BackofficeMetrics':
          return BackofficeMetrics.fromJson(value);
        case 'BankConnection':
          return BankConnection.fromJson(value);
        case 'BankLink':
          return BankLink.fromJson(value);
        case 'BankOverview':
          return BankOverview.fromJson(value);
        case 'BankTransaction':
          return BankTransaction.fromJson(value);
        case 'BookViewingRequest':
          return BookViewingRequest.fromJson(value);
        case 'ChangeListingStatusRequest':
          return ChangeListingStatusRequest.fromJson(value);
        case 'ChangePasswordRequest':
          return ChangePasswordRequest.fromJson(value);
        case 'ChatRequest':
          return ChatRequest.fromJson(value);
        case 'ChatResponse':
          return ChatResponse.fromJson(value);
        case 'ClientKind':
          return ClientKindTypeTransformer().decode(value);
        case 'CodeRequest':
          return CodeRequest.fromJson(value);
        case 'CompleteIncomeUploadRequest':
          return CompleteIncomeUploadRequest.fromJson(value);
        case 'ConfirmLeaseSettlement200Response':
          return ConfirmLeaseSettlement200Response.fromJson(value);
        case 'ConnectBankRequest':
          return ConnectBankRequest.fromJson(value);
        case 'Consent':
          return Consent.fromJson(value);
        case 'ConsentInput':
          return ConsentInput.fromJson(value);
        case 'ConsentKind':
          return ConsentKindTypeTransformer().decode(value);
        case 'ContractTemplate':
          return ContractTemplate.fromJson(value);
        case 'ContractTemplateList':
          return ContractTemplateList.fromJson(value);
        case 'Conversation':
          return Conversation.fromJson(value);
        case 'ConversationDetail':
          return ConversationDetail.fromJson(value);
        case 'ConversationRole':
          return ConversationRoleTypeTransformer().decode(value);
        case 'CreateAttachmentUploadRequest':
          return CreateAttachmentUploadRequest.fromJson(value);
        case 'CreateContractScanUploadRequest':
          return CreateContractScanUploadRequest.fromJson(value);
        case 'CreateGroupRequest':
          return CreateGroupRequest.fromJson(value);
        case 'CreateIncomeUpload201Response':
          return CreateIncomeUpload201Response.fromJson(value);
        case 'CreateIncomeUploadRequest':
          return CreateIncomeUploadRequest.fromJson(value);
        case 'CreateViewingSlotRequest':
          return CreateViewingSlotRequest.fromJson(value);
        case 'DecideApplicationRequest':
          return DecideApplicationRequest.fromJson(value);
        case 'DownloadLink':
          return DownloadLink.fromJson(value);
        case 'FacetCount':
          return FacetCount.fromJson(value);
        case 'FeatureFlag':
          return FeatureFlag.fromJson(value);
        case 'FeatureFlagInput':
          return FeatureFlagInput.fromJson(value);
        case 'FeatureFlagList':
          return FeatureFlagList.fromJson(value);
        case 'FieldError':
          return FieldError.fromJson(value);
        case 'FilterProposal':
          return FilterProposal.fromJson(value);
        case 'GdprRequest':
          return GdprRequest.fromJson(value);
        case 'GetPortfolioSummary200Response':
          return GetPortfolioSummary200Response.fromJson(value);
        case 'GetPushConfig200Response':
          return GetPushConfig200Response.fromJson(value);
        case 'GiveLeaseNotice200Response':
          return GiveLeaseNotice200Response.fromJson(value);
        case 'GiveLeaseNoticeRequest':
          return GiveLeaseNoticeRequest.fromJson(value);
        case 'Group':
          return Group.fromJson(value);
        case 'GroupMember':
          return GroupMember.fromJson(value);
        case 'GroupMessage':
          return GroupMessage.fromJson(value);
        case 'GroupSummary':
          return GroupSummary.fromJson(value);
        case 'Health':
          return Health.fromJson(value);
        case 'HealthCheck':
          return HealthCheck.fromJson(value);
        case 'I18nText':
          return I18nText.fromJson(value);
        case 'ImpersonateRequest':
          return ImpersonateRequest.fromJson(value);
        case 'Invitation':
          return Invitation.fromJson(value);
        case 'InvitationInput':
          return InvitationInput.fromJson(value);
        case 'InvitationPreview':
          return InvitationPreview.fromJson(value);
        case 'InvitationTokenInput':
          return InvitationTokenInput.fromJson(value);
        case 'InviteLeasePartyRequest':
          return InviteLeasePartyRequest.fromJson(value);
        case 'InviteToGroupRequest':
          return InviteToGroupRequest.fromJson(value);
        case 'Invoice':
          return Invoice.fromJson(value);
        case 'InvoiceList':
          return InvoiceList.fromJson(value);
        case 'Jurisdiction':
          return Jurisdiction.fromJson(value);
        case 'LandlordNoticeReason':
          return LandlordNoticeReasonTypeTransformer().decode(value);
        case 'LeaseDetail':
          return LeaseDetail.fromJson(value);
        case 'LeaseDocument':
          return LeaseDocument.fromJson(value);
        case 'LeaseEvent':
          return LeaseEvent.fromJson(value);
        case 'LeaseEventLog':
          return LeaseEventLog.fromJson(value);
        case 'LeaseImportInput':
          return LeaseImportInput.fromJson(value);
        case 'LeaseImportPartyInput':
          return LeaseImportPartyInput.fromJson(value);
        case 'LeaseInput':
          return LeaseInput.fromJson(value);
        case 'LeaseOrigin':
          return LeaseOriginTypeTransformer().decode(value);
        case 'LeaseParty':
          return LeaseParty.fromJson(value);
        case 'LeasePartyInput':
          return LeasePartyInput.fromJson(value);
        case 'LeaseRisk':
          return LeaseRisk.fromJson(value);
        case 'LeaseState':
          return LeaseStateTypeTransformer().decode(value);
        case 'LeaseSummary':
          return LeaseSummary.fromJson(value);
        case 'LeaseTemplate':
          return LeaseTemplateTypeTransformer().decode(value);
        case 'LedgerEntry':
          return LedgerEntry.fromJson(value);
        case 'Listing':
          return Listing.fromJson(value);
        case 'ListingAddress':
          return ListingAddress.fromJson(value);
        case 'ListingCard':
          return ListingCard.fromJson(value);
        case 'ListingCreate':
          return ListingCreate.fromJson(value);
        case 'ListingReportCreated':
          return ListingReportCreated.fromJson(value);
        case 'ListingReportInput':
          return ListingReportInput.fromJson(value);
        case 'ListingReportReason':
          return ListingReportReasonTypeTransformer().decode(value);
        case 'ListingStatus':
          return ListingStatusTypeTransformer().decode(value);
        case 'ListingSummary':
          return ListingSummary.fromJson(value);
        case 'ListingUnit':
          return ListingUnit.fromJson(value);
        case 'ListingUpdate':
          return ListingUpdate.fromJson(value);
        case 'ListingVersionInfo':
          return ListingVersionInfo.fromJson(value);
        case 'LoginRequest':
          return LoginRequest.fromJson(value);
        case 'MagicLinkRequest':
          return MagicLinkRequest.fromJson(value);
        case 'MapPoint':
          return MapPoint.fromJson(value);
        case 'MarkNotificationsReadRequest':
          return MarkNotificationsReadRequest.fromJson(value);
        case 'MarkSharePaidRequest':
          return MarkSharePaidRequest.fromJson(value);
        case 'MatchBankTransactionRequest':
          return MatchBankTransactionRequest.fromJson(value);
        case 'Me':
          return Me.fromJson(value);
        case 'Media':
          return Media.fromJson(value);
        case 'MediaUpdate':
          return MediaUpdate.fromJson(value);
        case 'MediaUpload':
          return MediaUpload.fromJson(value);
        case 'MediaUploadRequest':
          return MediaUploadRequest.fromJson(value);
        case 'Member':
          return Member.fromJson(value);
        case 'Message':
          return Message.fromJson(value);
        case 'MessageFlag':
          return MessageFlagTypeTransformer().decode(value);
        case 'MessageInput':
          return MessageInput.fromJson(value);
        case 'MfaRequest':
          return MfaRequest.fromJson(value);
        case 'ModerationCase':
          return ModerationCase.fromJson(value);
        case 'ModerationCaseDetail':
          return ModerationCaseDetail.fromJson(value);
        case 'ModerationSuggestion':
          return ModerationSuggestion.fromJson(value);
        case 'ModerationVerdict':
          return ModerationVerdictTypeTransformer().decode(value);
        case 'Money':
          return Money.fromJson(value);
        case 'MunicipalityStat':
          return MunicipalityStat.fromJson(value);
        case 'Notification':
          return Notification.fromJson(value);
        case 'NotificationList':
          return NotificationList.fromJson(value);
        case 'NotificationPreferences':
          return NotificationPreferences.fromJson(value);
        case 'ObligationShare':
          return ObligationShare.fromJson(value);
        case 'OidcCallbackRequest':
          return OidcCallbackRequest.fromJson(value);
        case 'OidcStart':
          return OidcStart.fromJson(value);
        case 'OidcStartRequest':
          return OidcStartRequest.fromJson(value);
        case 'Order':
          return Order.fromJson(value);
        case 'OrderList':
          return OrderList.fromJson(value);
        case 'OrderStatus':
          return OrderStatusTypeTransformer().decode(value);
        case 'OrgInput':
          return OrgInput.fromJson(value);
        case 'OrgMembership':
          return OrgMembership.fromJson(value);
        case 'Organization':
          return Organization.fromJson(value);
        case 'Passport':
          return Passport.fromJson(value);
        case 'PasswordResetRequest':
          return PasswordResetRequest.fromJson(value);
        case 'PaymentLink':
          return PaymentLink.fromJson(value);
        case 'PhoneRequest':
          return PhoneRequest.fromJson(value);
        case 'PhotoVariants':
          return PhotoVariants.fromJson(value);
        case 'Place':
          return Place.fromJson(value);
        case 'PortfolioAttention':
          return PortfolioAttention.fromJson(value);
        case 'PortfolioCity':
          return PortfolioCity.fromJson(value);
        case 'PortfolioDashboard':
          return PortfolioDashboard.fromJson(value);
        case 'PortfolioDashboardConcentration':
          return PortfolioDashboardConcentration.fromJson(value);
        case 'PortfolioDashboardTrendInner':
          return PortfolioDashboardTrendInner.fromJson(value);
        case 'PortfolioGroup':
          return PortfolioGroup.fromJson(value);
        case 'PortfolioGroupInput':
          return PortfolioGroupInput.fromJson(value);
        case 'PortfolioGroups':
          return PortfolioGroups.fromJson(value);
        case 'PortfolioGroupsPropertiesInner':
          return PortfolioGroupsPropertiesInner.fromJson(value);
        case 'PortfolioRule':
          return PortfolioRule.fromJson(value);
        case 'PortfolioRuleInput':
          return PortfolioRuleInput.fromJson(value);
        case 'PortfolioRuleList':
          return PortfolioRuleList.fromJson(value);
        case 'PortfolioRuleListMunicipalitiesInner':
          return PortfolioRuleListMunicipalitiesInner.fromJson(value);
        case 'PortfolioRules':
          return PortfolioRules.fromJson(value);
        case 'PortfolioShare':
          return PortfolioShare.fromJson(value);
        case 'PortfolioSummary':
          return PortfolioSummary.fromJson(value);
        case 'PrescreenAnswer':
          return PrescreenAnswer.fromJson(value);
        case 'PrescreenAnswerQuestion':
          return PrescreenAnswerQuestion.fromJson(value);
        case 'PrescreenQuestion':
          return PrescreenQuestion.fromJson(value);
        case 'PrescreenQuestionText':
          return PrescreenQuestionText.fromJson(value);
        case 'PrivacyFlag':
          return PrivacyFlag.fromJson(value);
        case 'Problem':
          return Problem.fromJson(value);
        case 'PromoCheckout':
          return PromoCheckout.fromJson(value);
        case 'PromoCheckoutInput':
          return PromoCheckoutInput.fromJson(value);
        case 'PromoProduct':
          return PromoProduct.fromJson(value);
        case 'PromoProductInput':
          return PromoProductInput.fromJson(value);
        case 'PromoProductKind':
          return PromoProductKindTypeTransformer().decode(value);
        case 'PromoProductList':
          return PromoProductList.fromJson(value);
        case 'PromoProductPatch':
          return PromoProductPatch.fromJson(value);
        case 'Promotion':
          return Promotion.fromJson(value);
        case 'PromotionList':
          return PromotionList.fromJson(value);
        case 'ProposalDecision':
          return ProposalDecision.fromJson(value);
        case 'PublicListing':
          return PublicListing.fromJson(value);
        case 'PublicListingLocation':
          return PublicListingLocation.fromJson(value);
        case 'PublicListingUnit':
          return PublicListingUnit.fromJson(value);
        case 'PushDevice':
          return PushDevice.fromJson(value);
        case 'PushDeviceInput':
          return PushDeviceInput.fromJson(value);
        case 'PushDeviceInputKeys':
          return PushDeviceInputKeys.fromJson(value);
        case 'RealtimeToken':
          return RealtimeToken.fromJson(value);
        case 'RecoveryCodes':
          return RecoveryCodes.fromJson(value);
        case 'RegisterRequest':
          return RegisterRequest.fromJson(value);
        case 'RejectReason':
          return RejectReasonTypeTransformer().decode(value);
        case 'RentRoll':
          return RentRoll.fromJson(value);
        case 'RentRollRow':
          return RentRollRow.fromJson(value);
        case 'RentRollTotals':
          return RentRollTotals.fromJson(value);
        case 'ReplyTemplate':
          return ReplyTemplate.fromJson(value);
        case 'ReplyTemplateInput':
          return ReplyTemplateInput.fromJson(value);
        case 'ReportConversation201Response':
          return ReportConversation201Response.fromJson(value);
        case 'ReportInput':
          return ReportInput.fromJson(value);
        case 'RequestLeaseChangesRequest':
          return RequestLeaseChangesRequest.fromJson(value);
        case 'RequestSuggestionRequest':
          return RequestSuggestionRequest.fromJson(value);
        case 'ResolvedRules':
          return ResolvedRules.fromJson(value);
        case 'ReviewDecision':
          return ReviewDecision.fromJson(value);
        case 'ReviewDetail':
          return ReviewDetail.fromJson(value);
        case 'ReviewItem':
          return ReviewItem.fromJson(value);
        case 'RevolutAccount':
          return RevolutAccount.fromJson(value);
        case 'RevolutAccountInput':
          return RevolutAccountInput.fromJson(value);
        case 'RevolutMode':
          return RevolutModeTypeTransformer().decode(value);
        case 'RiskBand':
          return RiskBandTypeTransformer().decode(value);
        case 'RiskFactor':
          return RiskFactor.fromJson(value);
        case 'RiskWeights':
          return RiskWeights.fromJson(value);
        case 'Role':
          return RoleTypeTransformer().decode(value);
        case 'RoleInput':
          return RoleInput.fromJson(value);
        case 'RoommateMatch':
          return RoommateMatch.fromJson(value);
        case 'RoommateProfile':
          return RoommateProfile.fromJson(value);
        case 'SavedSearch':
          return SavedSearch.fromJson(value);
        case 'SavedSearchInput':
          return SavedSearchInput.fromJson(value);
        case 'SearchQuery':
          return SearchQuery.fromJson(value);
        case 'SearchResult':
          return SearchResult.fromJson(value);
        case 'SendGroupMessageRequest':
          return SendGroupMessageRequest.fromJson(value);
        case 'SentMessage':
          return SentMessage.fromJson(value);
        case 'SessionInfo':
          return SessionInfo.fromJson(value);
        case 'SessionToken':
          return SessionToken.fromJson(value);
        case 'SetConversationBlockedRequest':
          return SetConversationBlockedRequest.fromJson(value);
        case 'SetRiskWeightsRequest':
          return SetRiskWeightsRequest.fromJson(value);
        case 'SignLease200Response':
          return SignLease200Response.fromJson(value);
        case 'SignLeaseRequest':
          return SignLeaseRequest.fromJson(value);
        case 'SignProvider':
          return SignProvider.fromJson(value);
        case 'StartConversation':
          return StartConversation.fromJson(value);
        case 'SubscriptionToken':
          return SubscriptionToken.fromJson(value);
        case 'Suggestion':
          return Suggestion.fromJson(value);
        case 'SuggestionDecision':
          return SuggestionDecision.fromJson(value);
        case 'SyncBank200Response':
          return SyncBank200Response.fromJson(value);
        case 'TokenRequest':
          return TokenRequest.fromJson(value);
        case 'TotpSetup':
          return TotpSetup.fromJson(value);
        case 'TranscriptMessage':
          return TranscriptMessage.fromJson(value);
        case 'UnitKind':
          return UnitKindTypeTransformer().decode(value);
        case 'UpdateMeRequest':
          return UpdateMeRequest.fromJson(value);
        case 'UserLocale':
          return UserLocaleTypeTransformer().decode(value);
        case 'UserRef':
          return UserRef.fromJson(value);
        case 'VerificationLevel':
          return VerificationLevelTypeTransformer().decode(value);
        case 'VerifiedIdentity':
          return VerifiedIdentity.fromJson(value);
        case 'Version':
          return Version.fromJson(value);
        case 'Viewing':
          return Viewing.fromJson(value);
        case 'ViewingSlot':
          return ViewingSlot.fromJson(value);
        case 'ViewingSlotBookingsInner':
          return ViewingSlotBookingsInner.fromJson(value);
        default:
          dynamic match;
          if (value is List && (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toList(growable: growable);
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toSet();
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,)),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(HttpStatus.internalServerError, 'Exception during deserialization.', error, trace,);
    }
    throw ApiException(HttpStatus.internalServerError, 'Could not find a suitable class for deserialization',);
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : ApiClient.fromJson(
        json.decode(message.json),
        targetType,
        growable: message.growable,
      );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async => value == null ? '' : json.encode(value);
