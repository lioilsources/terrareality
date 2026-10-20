//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class LeasingApi {
  LeasingApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Check the uploaded scan and attach it as the lease's contract scan
  ///
  /// Errors: 404 `upload_not_found`, 409 `lease_not_imported`, 422 `attachment_missing`, `attachment_type`, `attachment_size`, `attachment_infected`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  ///
  /// * [CompleteIncomeUploadRequest] completeIncomeUploadRequest (required):
  Future<Response> completeContractScanUploadWithHttpInfo(String orgId, String leaseId, CompleteIncomeUploadRequest completeIncomeUploadRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/leases/{leaseId}/contract-scan/complete'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody = completeIncomeUploadRequest;

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

  /// Check the uploaded scan and attach it as the lease's contract scan
  ///
  /// Errors: 404 `upload_not_found`, 409 `lease_not_imported`, 422 `attachment_missing`, `attachment_type`, `attachment_size`, `attachment_infected`.
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  ///
  /// * [CompleteIncomeUploadRequest] completeIncomeUploadRequest (required):
  Future<LeaseDetail?> completeContractScanUpload(String orgId, String leaseId, CompleteIncomeUploadRequest completeIncomeUploadRequest,) async {
    final response = await completeContractScanUploadWithHttpInfo(orgId, leaseId, completeIncomeUploadRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseDetail',) as LeaseDetail;
    
    }
    return null;
  }

  /// Confirm the deposit settlement after the lease ended (all parties settle the lease)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> confirmLeaseSettlementWithHttpInfo(String leaseId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/leases/{leaseId}/settlement'
      .replaceAll('{leaseId}', leaseId);

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

  /// Confirm the deposit settlement after the lease ended (all parties settle the lease)
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<ConfirmLeaseSettlement200Response?> confirmLeaseSettlement(String leaseId,) async {
    final response = await confirmLeaseSettlementWithHttpInfo(leaseId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ConfirmLeaseSettlement200Response',) as ConfirmLeaseSettlement200Response;
    
    }
    return null;
  }

  /// Link the landlord's account (open banking AIS, read only)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [ConnectBankRequest] connectBankRequest (required):
  Future<Response> connectBankWithHttpInfo(String orgId, ConnectBankRequest connectBankRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/bank/connections'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = connectBankRequest;

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

  /// Link the landlord's account (open banking AIS, read only)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [ConnectBankRequest] connectBankRequest (required):
  Future<BankLink?> connectBank(String orgId, ConnectBankRequest connectBankRequest,) async {
    final response = await connectBankWithHttpInfo(orgId, connectBankRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BankLink',) as BankLink;
    
    }
    return null;
  }

  /// Reserve an upload for the scan of an imported lease's paper contract (PUT the file, then complete)
  ///
  /// Errors: 409 `lease_not_imported`, 422 `attachment_type`, 422 `attachment_size`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  ///
  /// * [CreateContractScanUploadRequest] createContractScanUploadRequest (required):
  Future<Response> createContractScanUploadWithHttpInfo(String orgId, String leaseId, CreateContractScanUploadRequest createContractScanUploadRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/leases/{leaseId}/contract-scan'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody = createContractScanUploadRequest;

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

  /// Reserve an upload for the scan of an imported lease's paper contract (PUT the file, then complete)
  ///
  /// Errors: 409 `lease_not_imported`, 422 `attachment_type`, 422 `attachment_size`.
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  ///
  /// * [CreateContractScanUploadRequest] createContractScanUploadRequest (required):
  Future<CreateIncomeUpload201Response?> createContractScanUpload(String orgId, String leaseId, CreateContractScanUploadRequest createContractScanUploadRequest,) async {
    final response = await createContractScanUploadWithHttpInfo(orgId, leaseId, createContractScanUploadRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CreateIncomeUpload201Response',) as CreateIncomeUpload201Response;
    
    }
    return null;
  }

  /// Draft a lease (from an accepted application, or with explicit parties)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [LeaseInput] leaseInput (required):
  Future<Response> createLeaseWithHttpInfo(String orgId, LeaseInput leaseInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/leases'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = leaseInput;

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

  /// Draft a lease (from an accepted application, or with explicit parties)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [LeaseInput] leaseInput (required):
  Future<LeaseDetail?> createLease(String orgId, LeaseInput leaseInput,) async {
    final response = await createLeaseWithHttpInfo(orgId, leaseInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseDetail',) as LeaseDetail;
    
    }
    return null;
  }

  /// Complete linking after returning from the bank
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] connectionId (required):
  Future<Response> finishBankConnectionWithHttpInfo(String orgId, String connectionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/bank/connections/{connectionId}/finish'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{connectionId}', connectionId);

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

  /// Complete linking after returning from the bank
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] connectionId (required):
  Future<BankConnection?> finishBankConnection(String orgId, String connectionId,) async {
    final response = await finishBankConnectionWithHttpInfo(orgId, connectionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BankConnection',) as BankConnection;
    
    }
    return null;
  }

  /// Linked accounts and recent incoming transactions with their match status
  ///
  /// Transactions are paged newest first; `transactions_next_before` is the cursor of the next page.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] status:
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<Response> getBankOverviewWithHttpInfo(String orgId, { String? status, String? before, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/bank'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
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

  /// Linked accounts and recent incoming transactions with their match status
  ///
  /// Transactions are paged newest first; `transactions_next_before` is the cursor of the next page.
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] status:
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<BankOverview?> getBankOverview(String orgId, { String? status, String? before, int? limit, }) async {
    final response = await getBankOverviewWithHttpInfo(orgId,  status: status, before: before, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BankOverview',) as BankOverview;
    
    }
    return null;
  }

  /// Lease with parties, documents, signatures and the current debt
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> getLeaseWithHttpInfo(String leaseId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/leases/{leaseId}'
      .replaceAll('{leaseId}', leaseId);

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

  /// Lease with parties, documents, signatures and the current debt
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<LeaseDetail?> getLease(String leaseId,) async {
    final response = await getLeaseWithHttpInfo(leaseId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseDetail',) as LeaseDetail;
    
    }
    return null;
  }

  /// Hash-chained event log with its verification (export for disputes)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> getLeaseEventsWithHttpInfo(String leaseId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/leases/{leaseId}/events'
      .replaceAll('{leaseId}', leaseId);

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

  /// Hash-chained event log with its verification (export for disputes)
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<LeaseEventLog?> getLeaseEvents(String leaseId,) async {
    final response = await getLeaseEventsWithHttpInfo(leaseId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseEventLog',) as LeaseEventLog;
    
    }
    return null;
  }

  /// Double-entry ledger of the lease (JSON, or CSV with format=csv)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] format:
  Future<Response> getLeaseLedgerWithHttpInfo(String leaseId, { String? format, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/leases/{leaseId}/ledger'
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (format != null) {
      queryParams.addAll(_queryParams('', 'format', format));
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

  /// Double-entry ledger of the lease (JSON, or CSV with format=csv)
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] format:
  Future<List<LedgerEntry>?> getLeaseLedger(String leaseId, { String? format, }) async {
    final response = await getLeaseLedgerWithHttpInfo(leaseId,  format: format, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LedgerEntry>') as List)
        .cast<LedgerEntry>()
        .toList(growable: false);

    }
    return null;
  }

  /// QR payment (QR Platba / SPAYD) of one open share as a PNG image
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shareId (required):
  Future<Response> getShareQRWithHttpInfo(String shareId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/obligation-shares/{shareId}/qr'
      .replaceAll('{shareId}', shareId);

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

  /// QR payment (QR Platba / SPAYD) of one open share as a PNG image
  ///
  /// Parameters:
  ///
  /// * [String] shareId (required):
  Future<MultipartFile?> getShareQR(String shareId,) async {
    final response = await getShareQRWithHttpInfo(shareId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MultipartFile',) as MultipartFile;
    
    }
    return null;
  }

  /// Give notice; the lease ends after the notice period
  ///
  /// A tenant or co-tenant gives notice without a reason. The landlord (organization member with the leases permission) must state a statutory `reason`; the notice period is then at least three months. `delivered_on` lies between 30 days ago and 7 days from today. Errors: 403 `notice_not_allowed` (guarantor, subtenant), 422 `invalid_delivered_on`, 422 `landlord_notice_reason_required` (landlord without a reason, or other_serious_reason without an explanation), 422 `notice_reason_not_applicable` (flat_needed_for_landlord_or_relative on a fixed-term lease), 409 `lease_not_active`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [GiveLeaseNoticeRequest] giveLeaseNoticeRequest (required):
  Future<Response> giveLeaseNoticeWithHttpInfo(String leaseId, GiveLeaseNoticeRequest giveLeaseNoticeRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/leases/{leaseId}/notice'
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody = giveLeaseNoticeRequest;

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

  /// Give notice; the lease ends after the notice period
  ///
  /// A tenant or co-tenant gives notice without a reason. The landlord (organization member with the leases permission) must state a statutory `reason`; the notice period is then at least three months. `delivered_on` lies between 30 days ago and 7 days from today. Errors: 403 `notice_not_allowed` (guarantor, subtenant), 422 `invalid_delivered_on`, 422 `landlord_notice_reason_required` (landlord without a reason, or other_serious_reason without an explanation), 422 `notice_reason_not_applicable` (flat_needed_for_landlord_or_relative on a fixed-term lease), 409 `lease_not_active`. 
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [GiveLeaseNoticeRequest] giveLeaseNoticeRequest (required):
  Future<GiveLeaseNotice200Response?> giveLeaseNotice(String leaseId, GiveLeaseNoticeRequest giveLeaseNoticeRequest,) async {
    final response = await giveLeaseNoticeWithHttpInfo(leaseId, giveLeaseNoticeRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'GiveLeaseNotice200Response',) as GiveLeaseNotice200Response;
    
    }
    return null;
  }

  /// Import an existing lease signed on paper (no signing round; payments tracked from the cutover)
  ///
  /// Creates the lease directly as `active` (or `signed` when it starts later; the lifecycle activates it on the start date) with `origin` = imported. No document is rendered and nobody signs: the event log records that the lease was signed outside the platform. The payment schedule starts at `cutover_on` (default: the first day of next month, or the start date when later); it may lie at most 31 days in the past and 12 months ahead, never before the start or after the end. Each party's `opening_balance` (owed at the cutover) becomes one opening-balance obligation due on the cutover day. With `deposit_held` the deposit is recorded as held and not scheduled. With `variable_symbol` payments, QR codes and bank matching use the tenants' existing symbol instead of `code`. Tenants get no e-mails or pushes until invited (inviteLeaseParty) and signed in. Errors: 422 `address_required`, `tenant_required`, `party_incomplete`, `invalid_email`, `invalid_template`, `end_required`, `end_not_allowed`, `invalid_term`, `deposit_too_high`, `invalid_iban`, `shares_total`, `joint_needs_two`, `lease_ended`, `cutover_before_start`, `cutover_too_old`, `cutover_too_far`, `cutover_after_end`, `invalid_variable_symbol`, `invalid_opening_balance`, `opening_balance_guarantor`; 409 `variable_symbol_taken` (another lease of the organization uses the symbol). 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [LeaseImportInput] leaseImportInput (required):
  Future<Response> importLeaseWithHttpInfo(String orgId, LeaseImportInput leaseImportInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/leases/import'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = leaseImportInput;

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

  /// Import an existing lease signed on paper (no signing round; payments tracked from the cutover)
  ///
  /// Creates the lease directly as `active` (or `signed` when it starts later; the lifecycle activates it on the start date) with `origin` = imported. No document is rendered and nobody signs: the event log records that the lease was signed outside the platform. The payment schedule starts at `cutover_on` (default: the first day of next month, or the start date when later); it may lie at most 31 days in the past and 12 months ahead, never before the start or after the end. Each party's `opening_balance` (owed at the cutover) becomes one opening-balance obligation due on the cutover day. With `deposit_held` the deposit is recorded as held and not scheduled. With `variable_symbol` payments, QR codes and bank matching use the tenants' existing symbol instead of `code`. Tenants get no e-mails or pushes until invited (inviteLeaseParty) and signed in. Errors: 422 `address_required`, `tenant_required`, `party_incomplete`, `invalid_email`, `invalid_template`, `end_required`, `end_not_allowed`, `invalid_term`, `deposit_too_high`, `invalid_iban`, `shares_total`, `joint_needs_two`, `lease_ended`, `cutover_before_start`, `cutover_too_old`, `cutover_too_far`, `cutover_after_end`, `invalid_variable_symbol`, `invalid_opening_balance`, `opening_balance_guarantor`; 409 `variable_symbol_taken` (another lease of the organization uses the symbol). 
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [LeaseImportInput] leaseImportInput (required):
  Future<LeaseDetail?> importLease(String orgId, LeaseImportInput leaseImportInput,) async {
    final response = await importLeaseWithHttpInfo(orgId, leaseImportInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseDetail',) as LeaseDetail;
    
    }
    return null;
  }

  /// Invite a tenant of an imported lease to the tenant portal (e-mail with a link)
  ///
  /// Stores the e-mail (optional when the party has one) and sends the invitation. The tenant is linked once they sign in with this verified address; only then do they get payment reminders. Errors: 409 `lease_not_imported`, 409 `lease_not_active`, 409 `party_linked` (already uses the portal), 404 `party_not_found`, 422 `invalid_email`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] partyId (required):
  ///
  /// * [InviteLeasePartyRequest] inviteLeasePartyRequest:
  Future<Response> inviteLeasePartyWithHttpInfo(String orgId, String leaseId, String partyId, { InviteLeasePartyRequest? inviteLeasePartyRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/leases/{leaseId}/parties/{partyId}/invite'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{leaseId}', leaseId)
      .replaceAll('{partyId}', partyId);

    // ignore: prefer_final_locals
    Object? postBody = inviteLeasePartyRequest;

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

  /// Invite a tenant of an imported lease to the tenant portal (e-mail with a link)
  ///
  /// Stores the e-mail (optional when the party has one) and sends the invitation. The tenant is linked once they sign in with this verified address; only then do they get payment reminders. Errors: 409 `lease_not_imported`, 409 `lease_not_active`, 409 `party_linked` (already uses the portal), 404 `party_not_found`, 422 `invalid_email`. 
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] partyId (required):
  ///
  /// * [InviteLeasePartyRequest] inviteLeasePartyRequest:
  Future<LeaseDetail?> inviteLeaseParty(String orgId, String leaseId, String partyId, { InviteLeasePartyRequest? inviteLeasePartyRequest, }) async {
    final response = await inviteLeasePartyWithHttpInfo(orgId, leaseId, partyId,  inviteLeasePartyRequest: inviteLeasePartyRequest, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseDetail',) as LeaseDetail;
    
    }
    return null;
  }

  /// Payment schedule split between parties, with QR payments (SPAYD) for open shares
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listLeaseObligationsWithHttpInfo(String leaseId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/leases/{leaseId}/obligations'
      .replaceAll('{leaseId}', leaseId);

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

  /// Payment schedule split between parties, with QR payments (SPAYD) for open shares
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<ObligationShare>?> listLeaseObligations(String leaseId,) async {
    final response = await listLeaseObligationsWithHttpInfo(leaseId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<ObligationShare>') as List)
        .cast<ObligationShare>()
        .toList(growable: false);

    }
    return null;
  }

  /// Leases where I am a tenant
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyLeasesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/leases';

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

  /// Leases where I am a tenant
  Future<List<LeaseSummary>?> listMyLeases() async {
    final response = await listMyLeasesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LeaseSummary>') as List)
        .cast<LeaseSummary>()
        .toList(growable: false);

    }
    return null;
  }

  /// Leases of the organization
  ///
  /// Paged newest first: a full page (as many items as `limit`) may have more; pass the last item's id as `before`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<Response> listOrgLeasesWithHttpInfo(String orgId, { String? before, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/leases'
      .replaceAll('{orgId}', orgId);

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

  /// Leases of the organization
  ///
  /// Paged newest first: a full page (as many items as `limit`) may have more; pass the last item's id as `before`.
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<List<LeaseSummary>?> listOrgLeases(String orgId, { String? before, int? limit, }) async {
    final response = await listOrgLeasesWithHttpInfo(orgId,  before: before, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LeaseSummary>') as List)
        .cast<LeaseSummary>()
        .toList(growable: false);

    }
    return null;
  }

  /// The landlord confirms a payment arrived (\"přišlo\")
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] shareId (required):
  ///
  /// * [MarkSharePaidRequest] markSharePaidRequest:
  Future<Response> markSharePaidWithHttpInfo(String orgId, String shareId, { MarkSharePaidRequest? markSharePaidRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/obligation-shares/{shareId}/paid'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{shareId}', shareId);

    // ignore: prefer_final_locals
    Object? postBody = markSharePaidRequest;

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

  /// The landlord confirms a payment arrived (\"přišlo\")
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] shareId (required):
  ///
  /// * [MarkSharePaidRequest] markSharePaidRequest:
  Future<void> markSharePaid(String orgId, String shareId, { MarkSharePaidRequest? markSharePaidRequest, }) async {
    final response = await markSharePaidWithHttpInfo(orgId, shareId,  markSharePaidRequest: markSharePaidRequest, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Confirm a suggested match or match manually; or ignore the transaction
  ///
  /// Errors: 422 `currency_mismatch` (the transaction and the share have different currencies), 409 `already_matched`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] transactionId (required):
  ///
  /// * [MatchBankTransactionRequest] matchBankTransactionRequest (required):
  Future<Response> matchBankTransactionWithHttpInfo(String orgId, String transactionId, MatchBankTransactionRequest matchBankTransactionRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/bank/transactions/{transactionId}/match'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{transactionId}', transactionId);

    // ignore: prefer_final_locals
    Object? postBody = matchBankTransactionRequest;

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

  /// Confirm a suggested match or match manually; or ignore the transaction
  ///
  /// Errors: 422 `currency_mismatch` (the transaction and the share have different currencies), 409 `already_matched`.
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] transactionId (required):
  ///
  /// * [MatchBankTransactionRequest] matchBankTransactionRequest (required):
  Future<void> matchBankTransaction(String orgId, String transactionId, MatchBankTransactionRequest matchBankTransactionRequest,) async {
    final response = await matchBankTransactionWithHttpInfo(orgId, transactionId, matchBankTransactionRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Render the lease document and ask all parties to sign
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  Future<Response> proposeLeaseWithHttpInfo(String orgId, String leaseId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/leases/{leaseId}/propose'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{leaseId}', leaseId);

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

  /// Render the lease document and ask all parties to sign
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  Future<LeaseDetail?> proposeLease(String orgId, String leaseId,) async {
    final response = await proposeLeaseWithHttpInfo(orgId, leaseId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseDetail',) as LeaseDetail;
    
    }
    return null;
  }

  /// Tenant asks the landlord to change the proposal
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [RequestLeaseChangesRequest] requestLeaseChangesRequest (required):
  Future<Response> requestLeaseChangesWithHttpInfo(String leaseId, RequestLeaseChangesRequest requestLeaseChangesRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/leases/{leaseId}/request-changes'
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody = requestLeaseChangesRequest;

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

  /// Tenant asks the landlord to change the proposal
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [RequestLeaseChangesRequest] requestLeaseChangesRequest (required):
  Future<void> requestLeaseChanges(String leaseId, RequestLeaseChangesRequest requestLeaseChangesRequest,) async {
    final response = await requestLeaseChangesWithHttpInfo(leaseId, requestLeaseChangesRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Sign the proposed document as my party (mock now; Bank iD SIGN when contracted)
  ///
  /// `provider` must be one of the lease detail's `sign_providers`. Errors: 422 `invalid_provider` (not enabled on this server), 409 `document_changed` (a new version was proposed meanwhile: reload and sign the new document), 409 `lease_not_proposed`, 409 `already_signed`, 403 `not_a_party`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [SignLeaseRequest] signLeaseRequest (required):
  Future<Response> signLeaseWithHttpInfo(String leaseId, SignLeaseRequest signLeaseRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/leases/{leaseId}/sign'
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody = signLeaseRequest;

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

  /// Sign the proposed document as my party (mock now; Bank iD SIGN when contracted)
  ///
  /// `provider` must be one of the lease detail's `sign_providers`. Errors: 422 `invalid_provider` (not enabled on this server), 409 `document_changed` (a new version was proposed meanwhile: reload and sign the new document), 409 `lease_not_proposed`, 409 `already_signed`, 403 `not_a_party`. 
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [SignLeaseRequest] signLeaseRequest (required):
  Future<SignLease200Response?> signLease(String leaseId, SignLeaseRequest signLeaseRequest,) async {
    final response = await signLeaseWithHttpInfo(leaseId, signLeaseRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SignLease200Response',) as SignLease200Response;
    
    }
    return null;
  }

  /// Fetch and match new transactions now
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> syncBankWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/bank/sync'
      .replaceAll('{orgId}', orgId);

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

  /// Fetch and match new transactions now
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<SyncBank200Response?> syncBank(String orgId,) async {
    final response = await syncBankWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SyncBank200Response',) as SyncBank200Response;
    
    }
    return null;
  }

  /// Edit a draft or a lease in negotiation
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  ///
  /// * [LeaseInput] leaseInput (required):
  Future<Response> updateLeaseWithHttpInfo(String orgId, String leaseId, LeaseInput leaseInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/leases/{leaseId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody = leaseInput;

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

  /// Edit a draft or a lease in negotiation
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] leaseId (required):
  ///
  /// * [LeaseInput] leaseInput (required):
  Future<LeaseDetail?> updateLease(String orgId, String leaseId, LeaseInput leaseInput,) async {
    final response = await updateLeaseWithHttpInfo(orgId, leaseId, leaseInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseDetail',) as LeaseDetail;
    
    }
    return null;
  }
}
