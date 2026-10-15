//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class PortfolioApi {
  PortfolioApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a group
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [PortfolioGroupInput] portfolioGroupInput (required):
  Future<Response> createPortfolioGroupWithHttpInfo(String orgId, PortfolioGroupInput portfolioGroupInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/groups'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = portfolioGroupInput;

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

  /// Create a group
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [PortfolioGroupInput] portfolioGroupInput (required):
  Future<PortfolioGroup?> createPortfolioGroup(String orgId, PortfolioGroupInput portfolioGroupInput,) async {
    final response = await createPortfolioGroupWithHttpInfo(orgId, portfolioGroupInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PortfolioGroup',) as PortfolioGroup;
    
    }
    return null;
  }

  /// Ask the AI to summarize the portfolio (aggregates only, no personal data)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> createPortfolioSummaryWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/summary'
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

  /// Ask the AI to summarize the portfolio (aggregates only, no personal data)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<PortfolioSummary?> createPortfolioSummary(String orgId,) async {
    final response = await createPortfolioSummaryWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PortfolioSummary',) as PortfolioSummary;
    
    }
    return null;
  }

  /// Delete a group (and its rules)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] portfolioGroupId (required):
  Future<Response> deletePortfolioGroupWithHttpInfo(String orgId, String portfolioGroupId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/groups/{portfolioGroupId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{portfolioGroupId}', portfolioGroupId);

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

  /// Delete a group (and its rules)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] portfolioGroupId (required):
  Future<void> deletePortfolioGroup(String orgId, String portfolioGroupId,) async {
    final response = await deletePortfolioGroupWithHttpInfo(orgId, portfolioGroupId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Delete a rule
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] ruleId (required):
  Future<Response> deletePortfolioRuleWithHttpInfo(String orgId, String ruleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/rules/{ruleId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{ruleId}', ruleId);

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

  /// Delete a rule
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] ruleId (required):
  Future<void> deletePortfolioRule(String orgId, String ruleId,) async {
    final response = await deletePortfolioRuleWithHttpInfo(orgId, ruleId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Risk of a lease with its factors (tenants see only the payment factors)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> getLeaseRiskWithHttpInfo(String leaseId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/leases/{leaseId}/risk'
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

  /// Risk of a lease with its factors (tenants see only the payment factors)
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<LeaseRisk?> getLeaseRisk(String leaseId,) async {
    final response = await getLeaseRiskWithHttpInfo(leaseId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseRisk',) as LeaseRisk;
    
    }
    return null;
  }

  /// Portfolio dashboard across municipalities (risk, concentration, income, attention, trend)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] municipality:
  ///   Admin path of a municipality.
  ///
  /// * [String] region:
  ///   Admin path of a region.
  ///
  /// * [String] groupId:
  Future<Response> getPortfolioWithHttpInfo(String orgId, { String? municipality, String? region, String? groupId, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (municipality != null) {
      queryParams.addAll(_queryParams('', 'municipality', municipality));
    }
    if (region != null) {
      queryParams.addAll(_queryParams('', 'region', region));
    }
    if (groupId != null) {
      queryParams.addAll(_queryParams('', 'group_id', groupId));
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

  /// Portfolio dashboard across municipalities (risk, concentration, income, attention, trend)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] municipality:
  ///   Admin path of a municipality.
  ///
  /// * [String] region:
  ///   Admin path of a region.
  ///
  /// * [String] groupId:
  Future<PortfolioDashboard?> getPortfolio(String orgId, { String? municipality, String? region, String? groupId, }) async {
    final response = await getPortfolioWithHttpInfo(orgId,  municipality: municipality, region: region, groupId: groupId, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PortfolioDashboard',) as PortfolioDashboard;
    
    }
    return null;
  }

  /// The latest AI summary of the portfolio (a suggestion)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> getPortfolioSummaryWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/summary'
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

  /// The latest AI summary of the portfolio (a suggestion)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<GetPortfolioSummary200Response?> getPortfolioSummary(String orgId,) async {
    final response = await getPortfolioSummaryWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'GetPortfolioSummary200Response',) as GetPortfolioSummary200Response;
    
    }
    return null;
  }

  /// Rent roll of all units and running leases (JSON, CSV or XLSX)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] municipality:
  ///   Admin path of a municipality.
  ///
  /// * [String] region:
  ///   Admin path of a region.
  ///
  /// * [String] groupId:
  ///
  /// * [String] format:
  Future<Response> getRentRollWithHttpInfo(String orgId, { String? municipality, String? region, String? groupId, String? format, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/rent-roll'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (municipality != null) {
      queryParams.addAll(_queryParams('', 'municipality', municipality));
    }
    if (region != null) {
      queryParams.addAll(_queryParams('', 'region', region));
    }
    if (groupId != null) {
      queryParams.addAll(_queryParams('', 'group_id', groupId));
    }
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

  /// Rent roll of all units and running leases (JSON, CSV or XLSX)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] municipality:
  ///   Admin path of a municipality.
  ///
  /// * [String] region:
  ///   Admin path of a region.
  ///
  /// * [String] groupId:
  ///
  /// * [String] format:
  Future<RentRoll?> getRentRoll(String orgId, { String? municipality, String? region, String? groupId, String? format, }) async {
    final response = await getRentRollWithHttpInfo(orgId,  municipality: municipality, region: region, groupId: groupId, format: format, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentRoll',) as RentRoll;
    
    }
    return null;
  }

  /// Factor weights of the lease risk score
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> getRiskWeightsWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/risk-weights'
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

  /// Factor weights of the lease risk score
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<RiskWeights?> getRiskWeights(String orgId,) async {
    final response = await getRiskWeightsWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RiskWeights',) as RiskWeights;
    
    }
    return null;
  }

  /// Groups (tags) of properties and leases
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> listPortfolioGroupsWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/groups'
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

  /// Groups (tags) of properties and leases
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<PortfolioGroups?> listPortfolioGroups(String orgId,) async {
    final response = await listPortfolioGroupsWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PortfolioGroups',) as PortfolioGroups;
    
    }
    return null;
  }

  /// Rules per municipality or group (overrides of the jurisdiction defaults)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> listPortfolioRulesWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/rules'
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

  /// Rules per municipality or group (overrides of the jurisdiction defaults)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<PortfolioRuleList?> listPortfolioRules(String orgId,) async {
    final response = await listPortfolioRulesWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PortfolioRuleList',) as PortfolioRuleList;
    
    }
    return null;
  }

  /// Rules a new lease at a place would get (lease form defaults)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId:
  ///
  /// * [int] ruianId:
  ///
  /// * [String] address:
  Future<Response> resolvePortfolioRulesWithHttpInfo(String orgId, { String? listingId, int? ruianId, String? address, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/rules/resolve'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (listingId != null) {
      queryParams.addAll(_queryParams('', 'listing_id', listingId));
    }
    if (ruianId != null) {
      queryParams.addAll(_queryParams('', 'ruian_id', ruianId));
    }
    if (address != null) {
      queryParams.addAll(_queryParams('', 'address', address));
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

  /// Rules a new lease at a place would get (lease form defaults)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId:
  ///
  /// * [int] ruianId:
  ///
  /// * [String] address:
  Future<ResolvedRules?> resolvePortfolioRules(String orgId, { String? listingId, int? ruianId, String? address, }) async {
    final response = await resolvePortfolioRulesWithHttpInfo(orgId,  listingId: listingId, ruianId: ruianId, address: address, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ResolvedRules',) as ResolvedRules;
    
    }
    return null;
  }

  /// Set the rules of a municipality or a group (applies to new leases)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [PortfolioRuleInput] portfolioRuleInput (required):
  Future<Response> savePortfolioRuleWithHttpInfo(String orgId, PortfolioRuleInput portfolioRuleInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/rules'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = portfolioRuleInput;

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

  /// Set the rules of a municipality or a group (applies to new leases)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [PortfolioRuleInput] portfolioRuleInput (required):
  Future<ReportConversation201Response?> savePortfolioRule(String orgId, PortfolioRuleInput portfolioRuleInput,) async {
    final response = await savePortfolioRuleWithHttpInfo(orgId, portfolioRuleInput,);
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

  /// Set factor weights (0 switches a factor off); leases are rescored
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [SetRiskWeightsRequest] setRiskWeightsRequest (required):
  Future<Response> setRiskWeightsWithHttpInfo(String orgId, SetRiskWeightsRequest setRiskWeightsRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/risk-weights'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = setRiskWeightsRequest;

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

  /// Set factor weights (0 switches a factor off); leases are rescored
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [SetRiskWeightsRequest] setRiskWeightsRequest (required):
  Future<RiskWeights?> setRiskWeights(String orgId, SetRiskWeightsRequest setRiskWeightsRequest,) async {
    final response = await setRiskWeightsWithHttpInfo(orgId, setRiskWeightsRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RiskWeights',) as RiskWeights;
    
    }
    return null;
  }

  /// Rename a group and replace its members
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] portfolioGroupId (required):
  ///
  /// * [PortfolioGroupInput] portfolioGroupInput (required):
  Future<Response> updatePortfolioGroupWithHttpInfo(String orgId, String portfolioGroupId, PortfolioGroupInput portfolioGroupInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/portfolio/groups/{portfolioGroupId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{portfolioGroupId}', portfolioGroupId);

    // ignore: prefer_final_locals
    Object? postBody = portfolioGroupInput;

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

  /// Rename a group and replace its members
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] portfolioGroupId (required):
  ///
  /// * [PortfolioGroupInput] portfolioGroupInput (required):
  Future<PortfolioGroup?> updatePortfolioGroup(String orgId, String portfolioGroupId, PortfolioGroupInput portfolioGroupInput,) async {
    final response = await updatePortfolioGroupWithHttpInfo(orgId, portfolioGroupId, portfolioGroupInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PortfolioGroup',) as PortfolioGroup;
    
    }
    return null;
  }
}
