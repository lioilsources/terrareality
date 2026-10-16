//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class SearchApi {
  SearchApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Natural-language search – turns a message into filters and a map area, then searches
  ///
  /// Errors: 400 `invalid_query`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ChatRequest] chatRequest (required):
  Future<Response> chatSearchWithHttpInfo(ChatRequest chatRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/search/chat';

    // ignore: prefer_final_locals
    Object? postBody = chatRequest;

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

  /// Natural-language search – turns a message into filters and a map area, then searches
  ///
  /// Errors: 400 `invalid_query`.
  ///
  /// Parameters:
  ///
  /// * [ChatRequest] chatRequest (required):
  Future<ChatResponse?> chatSearch(ChatRequest chatRequest,) async {
    final response = await chatSearchWithHttpInfo(chatRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ChatResponse',) as ChatResponse;
    
    }
    return null;
  }

  /// Save a search; new matching listings are e-mailed daily when notify is on
  ///
  /// Errors: 400 `invalid_query`, 400 `unknown_attribute`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SavedSearchInput] savedSearchInput (required):
  Future<Response> createSavedSearchWithHttpInfo(SavedSearchInput savedSearchInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/saved-searches';

    // ignore: prefer_final_locals
    Object? postBody = savedSearchInput;

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

  /// Save a search; new matching listings are e-mailed daily when notify is on
  ///
  /// Errors: 400 `invalid_query`, 400 `unknown_attribute`.
  ///
  /// Parameters:
  ///
  /// * [SavedSearchInput] savedSearchInput (required):
  Future<SavedSearch?> createSavedSearch(SavedSearchInput savedSearchInput,) async {
    final response = await createSavedSearchWithHttpInfo(savedSearchInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SavedSearch',) as SavedSearch;
    
    }
    return null;
  }

  /// Delete a saved search
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] savedSearchId (required):
  Future<Response> deleteSavedSearchWithHttpInfo(String savedSearchId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/saved-searches/{savedSearchId}'
      .replaceAll('{savedSearchId}', savedSearchId);

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

  /// Delete a saved search
  ///
  /// Parameters:
  ///
  /// * [String] savedSearchId (required):
  Future<void> deleteSavedSearch(String savedSearchId,) async {
    final response = await deleteSavedSearchWithHttpInfo(savedSearchId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Published listing (approved version only)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] listingId (required):
  Future<Response> getPublicListingWithHttpInfo(String listingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/listings/{listingId}'
      .replaceAll('{listingId}', listingId);

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

  /// Published listing (approved version only)
  ///
  /// Parameters:
  ///
  /// * [String] listingId (required):
  Future<PublicListing?> getPublicListing(String listingId,) async {
    final response = await getPublicListingWithHttpInfo(listingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PublicListing',) as PublicListing;
    
    }
    return null;
  }

  /// Similar listings (embeddings when available, otherwise kind, price and distance)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] listingId (required):
  Future<Response> getSimilarListingsWithHttpInfo(String listingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/listings/{listingId}/similar'
      .replaceAll('{listingId}', listingId);

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

  /// Similar listings (embeddings when available, otherwise kind, price and distance)
  ///
  /// Parameters:
  ///
  /// * [String] listingId (required):
  Future<List<ListingCard>?> getSimilarListings(String listingId,) async {
    final response = await getSimilarListingsWithHttpInfo(listingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<ListingCard>') as List)
        .cast<ListingCard>()
        .toList(growable: false);

    }
    return null;
  }

  /// Child administrative units with simplified outlines (regions when parent is empty)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] parent:
  Future<Response> listAreasWithHttpInfo({ String? parent, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/areas';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (parent != null) {
      queryParams.addAll(_queryParams('', 'parent', parent));
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

  /// Child administrative units with simplified outlines (regions when parent is empty)
  ///
  /// Parameters:
  ///
  /// * [String] parent:
  Future<List<Area>?> listAreas({ String? parent, }) async {
    final response = await listAreasWithHttpInfo( parent: parent, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Area>') as List)
        .cast<Area>()
        .toList(growable: false);

    }
    return null;
  }

  /// My saved searches
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listSavedSearchesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/me/saved-searches';

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

  /// My saved searches
  Future<List<SavedSearch>?> listSavedSearches() async {
    final response = await listSavedSearchesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<SavedSearch>') as List)
        .cast<SavedSearch>()
        .toList(growable: false);

    }
    return null;
  }

  /// Municipalities with at least one listing (static site pages)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UnitKind] kind:
  Future<Response> listSeoMunicipalitiesWithHttpInfo({ UnitKind? kind, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/seo/municipalities';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (kind != null) {
      queryParams.addAll(_queryParams('', 'kind', kind));
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

  /// Municipalities with at least one listing (static site pages)
  ///
  /// Parameters:
  ///
  /// * [UnitKind] kind:
  Future<List<MunicipalityStat>?> listSeoMunicipalities({ UnitKind? kind, }) async {
    final response = await listSeoMunicipalitiesWithHttpInfo( kind: kind, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<MunicipalityStat>') as List)
        .cast<MunicipalityStat>()
        .toList(growable: false);

    }
    return null;
  }

  /// Report a published listing to the moderators (DSA notice, art. 16)
  ///
  /// Open to signed-in users and anonymous visitors. Anonymous reporters give an e-mail address for the acknowledgement and the statement of reasons; signed-in reporters use their account e-mail. Staff decide every report (ADR 0003). Rate-limited per user or client IP.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] listingId (required):
  ///
  /// * [ListingReportInput] listingReportInput (required):
  Future<Response> reportListingWithHttpInfo(String listingId, ListingReportInput listingReportInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/listings/{listingId}/reports'
      .replaceAll('{listingId}', listingId);

    // ignore: prefer_final_locals
    Object? postBody = listingReportInput;

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

  /// Report a published listing to the moderators (DSA notice, art. 16)
  ///
  /// Open to signed-in users and anonymous visitors. Anonymous reporters give an e-mail address for the acknowledgement and the statement of reasons; signed-in reporters use their account e-mail. Staff decide every report (ADR 0003). Rate-limited per user or client IP.
  ///
  /// Parameters:
  ///
  /// * [String] listingId (required):
  ///
  /// * [ListingReportInput] listingReportInput (required):
  Future<ListingReportCreated?> reportListing(String listingId, ListingReportInput listingReportInput,) async {
    final response = await reportListingWithHttpInfo(listingId, listingReportInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ListingReportCreated',) as ListingReportCreated;
    
    }
    return null;
  }

  /// Faceted search over published listings with map aggregates
  ///
  /// Errors: 400 `invalid_query` (detail names the problem), 400 `unknown_attribute`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SearchQuery] searchQuery (required):
  Future<Response> searchWithHttpInfo(SearchQuery searchQuery,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/search';

    // ignore: prefer_final_locals
    Object? postBody = searchQuery;

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

  /// Faceted search over published listings with map aggregates
  ///
  /// Errors: 400 `invalid_query` (detail names the problem), 400 `unknown_attribute`.
  ///
  /// Parameters:
  ///
  /// * [SearchQuery] searchQuery (required):
  Future<SearchResult?> search(SearchQuery searchQuery,) async {
    final response = await searchWithHttpInfo(searchQuery,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SearchResult',) as SearchResult;
    
    }
    return null;
  }
}
