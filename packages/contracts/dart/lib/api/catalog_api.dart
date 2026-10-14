//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class CatalogApi {
  CatalogApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Pause, resume, mark as rented or archive
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [ChangeListingStatusRequest] changeListingStatusRequest (required):
  Future<Response> changeListingStatusWithHttpInfo(String orgId, String listingId, ChangeListingStatusRequest changeListingStatusRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/status'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

    // ignore: prefer_final_locals
    Object? postBody = changeListingStatusRequest;

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

  /// Pause, resume, mark as rented or archive
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [ChangeListingStatusRequest] changeListingStatusRequest (required):
  Future<Listing?> changeListingStatus(String orgId, String listingId, ChangeListingStatusRequest changeListingStatusRequest,) async {
    final response = await changeListingStatusWithHttpInfo(orgId, listingId, changeListingStatusRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Listing',) as Listing;
    
    }
    return null;
  }

  /// Start processing (EXIF strip, malware scan, vision) after the upload
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] mediaId (required):
  Future<Response> completeMediaUploadWithHttpInfo(String orgId, String mediaId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/media/{mediaId}/complete'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{mediaId}', mediaId);

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

  /// Start processing (EXIF strip, malware scan, vision) after the upload
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] mediaId (required):
  Future<Media?> completeMediaUpload(String orgId, String mediaId,) async {
    final response = await completeMediaUploadWithHttpInfo(orgId, mediaId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Media',) as Media;
    
    }
    return null;
  }

  /// Wizard step 1 – address and unit; creates a draft listing
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [ListingCreate] listingCreate (required):
  Future<Response> createListingWithHttpInfo(String orgId, ListingCreate listingCreate,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = listingCreate;

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

  /// Wizard step 1 – address and unit; creates a draft listing
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [ListingCreate] listingCreate (required):
  Future<Listing?> createListing(String orgId, ListingCreate listingCreate,) async {
    final response = await createListingWithHttpInfo(orgId, listingCreate,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Listing',) as Listing;
    
    }
    return null;
  }

  /// Reserve a photo and get a presigned upload URL (PUT the file there, then complete)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [MediaUploadRequest] mediaUploadRequest (required):
  Future<Response> createMediaUploadWithHttpInfo(String orgId, String listingId, MediaUploadRequest mediaUploadRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/media'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

    // ignore: prefer_final_locals
    Object? postBody = mediaUploadRequest;

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

  /// Reserve a photo and get a presigned upload URL (PUT the file there, then complete)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [MediaUploadRequest] mediaUploadRequest (required):
  Future<MediaUpload?> createMediaUpload(String orgId, String listingId, MediaUploadRequest mediaUploadRequest,) async {
    final response = await createMediaUploadWithHttpInfo(orgId, listingId, mediaUploadRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MediaUpload',) as MediaUpload;
    
    }
    return null;
  }

  /// Accept (all or selected attributes) or reject an AI suggestion
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] suggestionId (required):
  ///
  /// * [SuggestionDecision] suggestionDecision (required):
  Future<Response> decideSuggestionWithHttpInfo(String orgId, String suggestionId, SuggestionDecision suggestionDecision,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/suggestions/{suggestionId}/decision'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{suggestionId}', suggestionId);

    // ignore: prefer_final_locals
    Object? postBody = suggestionDecision;

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

  /// Accept (all or selected attributes) or reject an AI suggestion
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] suggestionId (required):
  ///
  /// * [SuggestionDecision] suggestionDecision (required):
  Future<Suggestion?> decideSuggestion(String orgId, String suggestionId, SuggestionDecision suggestionDecision,) async {
    final response = await decideSuggestionWithHttpInfo(orgId, suggestionId, suggestionDecision,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Suggestion',) as Suggestion;
    
    }
    return null;
  }

  /// Remove a photo
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] mediaId (required):
  Future<Response> deleteMediaWithHttpInfo(String orgId, String mediaId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/media/{mediaId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{mediaId}', mediaId);

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

  /// Remove a photo
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] mediaId (required):
  Future<void> deleteMedia(String orgId, String mediaId,) async {
    final response = await deleteMediaWithHttpInfo(orgId, mediaId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Copy the listing onto a new unit in the same building (without photos)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Response> duplicateListingWithHttpInfo(String orgId, String listingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/duplicate'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

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

  /// Copy the listing onto a new unit in the same building (without photos)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Listing?> duplicateListing(String orgId, String listingId,) async {
    final response = await duplicateListingWithHttpInfo(orgId, listingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Listing',) as Listing;
    
    }
    return null;
  }

  /// Listing attribute schema (catalog plus approved options)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAttributeSchemaWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/attributes';

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

  /// Listing attribute schema (catalog plus approved options)
  Future<AttributeSchema?> getAttributeSchema() async {
    final response = await getAttributeSchemaWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AttributeSchema',) as AttributeSchema;
    
    }
    return null;
  }

  /// Listing with unit, address, photos, AI suggestions and versions
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Response> getListingWithHttpInfo(String orgId, String listingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}'
      .replaceAll('{orgId}', orgId)
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

  /// Listing with unit, address, photos, AI suggestions and versions
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Listing?> getListing(String orgId, String listingId,) async {
    final response = await getListingWithHttpInfo(orgId, listingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Listing',) as Listing;
    
    }
    return null;
  }

  /// Listings of an organization
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [ListingStatus] status:
  Future<Response> listListingsWithHttpInfo(String orgId, { ListingStatus? status, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
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

  /// Listings of an organization
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [ListingStatus] status:
  Future<List<ListingSummary>?> listListings(String orgId, { ListingStatus? status, }) async {
    final response = await listListingsWithHttpInfo(orgId,  status: status, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<ListingSummary>') as List)
        .cast<ListingSummary>()
        .toList(growable: false);

    }
    return null;
  }

  /// Ask the AI for attribute or text suggestions (generated in the background)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [RequestSuggestionRequest] requestSuggestionRequest (required):
  Future<Response> requestSuggestionWithHttpInfo(String orgId, String listingId, RequestSuggestionRequest requestSuggestionRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/suggestions'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

    // ignore: prefer_final_locals
    Object? postBody = requestSuggestionRequest;

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

  /// Ask the AI for attribute or text suggestions (generated in the background)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [RequestSuggestionRequest] requestSuggestionRequest (required):
  Future<Suggestion?> requestSuggestion(String orgId, String listingId, RequestSuggestionRequest requestSuggestionRequest,) async {
    final response = await requestSuggestionWithHttpInfo(orgId, listingId, requestSuggestionRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Suggestion',) as Suggestion;
    
    }
    return null;
  }

  /// Autocomplete Czech addresses (RÚIAN)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q (required):
  ///
  /// * [int] limit:
  Future<Response> searchAddressesWithHttpInfo(String q, { int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/addresses/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'q', q));
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

  /// Autocomplete Czech addresses (RÚIAN)
  ///
  /// Parameters:
  ///
  /// * [String] q (required):
  ///
  /// * [int] limit:
  Future<List<AddressSuggestion>?> searchAddresses(String q, { int? limit, }) async {
    final response = await searchAddressesWithHttpInfo(q,  limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AddressSuggestion>') as List)
        .cast<AddressSuggestion>()
        .toList(growable: false);

    }
    return null;
  }

  /// Send the working copy to moderation as a new version
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Response> submitListingWithHttpInfo(String orgId, String listingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/submit'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

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

  /// Send the working copy to moderation as a new version
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Listing?> submitListing(String orgId, String listingId,) async {
    final response = await submitListingWithHttpInfo(orgId, listingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Listing',) as Listing;
    
    }
    return null;
  }

  /// Save the working copy (withdraws a pending review)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [ListingUpdate] listingUpdate (required):
  Future<Response> updateListingWithHttpInfo(String orgId, String listingId, ListingUpdate listingUpdate,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

    // ignore: prefer_final_locals
    Object? postBody = listingUpdate;

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

  /// Save the working copy (withdraws a pending review)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [ListingUpdate] listingUpdate (required):
  Future<Listing?> updateListing(String orgId, String listingId, ListingUpdate listingUpdate,) async {
    final response = await updateListingWithHttpInfo(orgId, listingId, listingUpdate,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Listing',) as Listing;
    
    }
    return null;
  }

  /// Change order and caption
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] mediaId (required):
  ///
  /// * [MediaUpdate] mediaUpdate (required):
  Future<Response> updateMediaWithHttpInfo(String orgId, String mediaId, MediaUpdate mediaUpdate,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/media/{mediaId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{mediaId}', mediaId);

    // ignore: prefer_final_locals
    Object? postBody = mediaUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Change order and caption
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] mediaId (required):
  ///
  /// * [MediaUpdate] mediaUpdate (required):
  Future<Media?> updateMedia(String orgId, String mediaId, MediaUpdate mediaUpdate,) async {
    final response = await updateMediaWithHttpInfo(orgId, mediaId, mediaUpdate,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Media',) as Media;
    
    }
    return null;
  }
}
