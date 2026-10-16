//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class BillingApi {
  BillingApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Card payment link in the landlord's own Revolut merchant account (money goes landlord-direct)
  ///
  /// For the share's party and members of the owning organization. 409 when the organization has no Revolut account; 404 when the payments.revolut flag is off. The platform never holds the money (ADR 0002).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shareId (required):
  Future<Response> createPaymentLinkWithHttpInfo(String shareId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/obligation-shares/{shareId}/payment-link'
      .replaceAll('{shareId}', shareId);

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

  /// Card payment link in the landlord's own Revolut merchant account (money goes landlord-direct)
  ///
  /// For the share's party and members of the owning organization. 409 when the organization has no Revolut account; 404 when the payments.revolut flag is off. The platform never holds the money (ADR 0002).
  ///
  /// Parameters:
  ///
  /// * [String] shareId (required):
  Future<PaymentLink?> createPaymentLink(String shareId,) async {
    final response = await createPaymentLinkWithHttpInfo(shareId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentLink',) as PaymentLink;
    
    }
    return null;
  }

  /// Order a promotion of a listing; pay by card on the returned Stripe Checkout page
  ///
  /// The order stays pending until the signed Stripe webhook confirms the payment. Stripe collects only the platform's own fee for promotion; rent never goes through the platform (ADR 0002).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [PromoCheckoutInput] promoCheckoutInput (required):
  Future<Response> createPromoCheckoutWithHttpInfo(String orgId, String listingId, PromoCheckoutInput promoCheckoutInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/promotions/checkout'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{listingId}', listingId);

    // ignore: prefer_final_locals
    Object? postBody = promoCheckoutInput;

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

  /// Order a promotion of a listing; pay by card on the returned Stripe Checkout page
  ///
  /// The order stays pending until the signed Stripe webhook confirms the payment. Stripe collects only the platform's own fee for promotion; rent never goes through the platform (ADR 0002).
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  ///
  /// * [PromoCheckoutInput] promoCheckoutInput (required):
  Future<PromoCheckout?> createPromoCheckout(String orgId, String listingId, PromoCheckoutInput promoCheckoutInput,) async {
    final response = await createPromoCheckoutWithHttpInfo(orgId, listingId, promoCheckoutInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PromoCheckout',) as PromoCheckout;
    
    }
    return null;
  }

  /// Disconnect the Revolut account
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> deleteRevolutAccountWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/revolut'
      .replaceAll('{orgId}', orgId);

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

  /// Disconnect the Revolut account
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<void> deleteRevolutAccount(String orgId,) async {
    final response = await deleteRevolutAccountWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// The invoice as a PDF
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] invoiceId (required):
  Future<Response> getInvoicePdfWithHttpInfo(String orgId, String invoiceId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/invoices/{invoiceId}/pdf'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{invoiceId}', invoiceId);

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

  /// The invoice as a PDF
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] invoiceId (required):
  Future<MultipartFile?> getInvoicePdf(String orgId, String invoiceId,) async {
    final response = await getInvoicePdfWithHttpInfo(orgId, invoiceId,);
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

  /// One order (the checkout success page polls it until paid)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] orderId (required):
  Future<Response> getOrderWithHttpInfo(String orgId, String orderId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/orders/{orderId}'
      .replaceAll('{orgId}', orgId)
      .replaceAll('{orderId}', orderId);

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

  /// One order (the checkout success page polls it until paid)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] orderId (required):
  Future<Order?> getOrder(String orgId, String orderId,) async {
    final response = await getOrderWithHttpInfo(orgId, orderId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Order',) as Order;
    
    }
    return null;
  }

  /// The latest valid payment link of a share (404 when none)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shareId (required):
  Future<Response> getPaymentLinkWithHttpInfo(String shareId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/obligation-shares/{shareId}/payment-link'
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

  /// The latest valid payment link of a share (404 when none)
  ///
  /// Parameters:
  ///
  /// * [String] shareId (required):
  Future<PaymentLink?> getPaymentLink(String shareId,) async {
    final response = await getPaymentLinkWithHttpInfo(shareId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentLink',) as PaymentLink;
    
    }
    return null;
  }

  /// The landlord's own Revolut Business merchant account (connection state only, never the key)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<Response> getRevolutAccountWithHttpInfo(String orgId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/revolut'
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

  /// The landlord's own Revolut Business merchant account (connection state only, never the key)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  Future<RevolutAccount?> getRevolutAccount(String orgId,) async {
    final response = await getRevolutAccountWithHttpInfo(orgId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RevolutAccount',) as RevolutAccount;
    
    }
    return null;
  }

  /// Invoices (daňové doklady) issued to the organization
  ///
  /// Paged newest first; `next_before` is the cursor of the next page.
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
  Future<Response> listInvoicesWithHttpInfo(String orgId, { String? before, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/invoices'
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

  /// Invoices (daňové doklady) issued to the organization
  ///
  /// Paged newest first; `next_before` is the cursor of the next page.
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<InvoiceList?> listInvoices(String orgId, { String? before, int? limit, }) async {
    final response = await listInvoicesWithHttpInfo(orgId,  before: before, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InvoiceList',) as InvoiceList;
    
    }
    return null;
  }

  /// Promotion orders of the organization
  ///
  /// Paged newest first; `next_before` is the cursor of the next page.
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
  Future<Response> listOrdersWithHttpInfo(String orgId, { String? before, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/orders'
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

  /// Promotion orders of the organization
  ///
  /// Paged newest first; `next_before` is the cursor of the next page.
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] before:
  ///   Cursor; return items with an id lower than this one.
  ///
  /// * [int] limit:
  Future<OrderList?> listOrders(String orgId, { String? before, int? limit, }) async {
    final response = await listOrdersWithHttpInfo(orgId,  before: before, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'OrderList',) as OrderList;
    
    }
    return null;
  }

  /// Active promotion products (topování, zvýraznění, balíček) with net, VAT and gross prices
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPromoProductsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/promo-products';

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

  /// Active promotion products (topování, zvýraznění, balíček) with net, VAT and gross prices
  Future<PromoProductList?> listPromoProducts() async {
    final response = await listPromoProductsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PromoProductList',) as PromoProductList;
    
    }
    return null;
  }

  /// Paid promotion periods of a listing (running, scheduled and past)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<Response> listPromotionsWithHttpInfo(String orgId, String listingId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/listings/{listingId}/promotions'
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

  /// Paid promotion periods of a listing (running, scheduled and past)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [String] listingId (required):
  Future<PromotionList?> listPromotions(String orgId, String listingId,) async {
    final response = await listPromotionsWithHttpInfo(orgId, listingId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PromotionList',) as PromotionList;
    
    }
    return null;
  }

  /// Connect the landlord's Revolut Business merchant API key (stored encrypted)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [RevolutAccountInput] revolutAccountInput (required):
  Future<Response> putRevolutAccountWithHttpInfo(String orgId, RevolutAccountInput revolutAccountInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/orgs/{orgId}/revolut'
      .replaceAll('{orgId}', orgId);

    // ignore: prefer_final_locals
    Object? postBody = revolutAccountInput;

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

  /// Connect the landlord's Revolut Business merchant API key (stored encrypted)
  ///
  /// Parameters:
  ///
  /// * [String] orgId (required):
  ///
  /// * [RevolutAccountInput] revolutAccountInput (required):
  Future<RevolutAccount?> putRevolutAccount(String orgId, RevolutAccountInput revolutAccountInput,) async {
    final response = await putRevolutAccountWithHttpInfo(orgId, revolutAccountInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RevolutAccount',) as RevolutAccount;
    
    }
    return null;
  }

  /// Stripe events (checkout.session.completed and friends); verified by the Stripe-Signature header
  ///
  /// The raw body is needed to verify the signature, so it is accepted as bytes. Events are processed once.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] body (required):
  ///
  /// * [String] stripeSignature:
  ///   Checked by the handler; a missing header is rejected with 400.
  Future<Response> stripeWebhookWithHttpInfo(MultipartFile body, { String? stripeSignature, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/webhooks/stripe';

    // ignore: prefer_final_locals
    Object? postBody = body;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (stripeSignature != null) {
      headerParams[r'Stripe-Signature'] = parameterToString(stripeSignature);
    }

    const contentTypes = <String>['application/octet-stream'];


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

  /// Stripe events (checkout.session.completed and friends); verified by the Stripe-Signature header
  ///
  /// The raw body is needed to verify the signature, so it is accepted as bytes. Events are processed once.
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] body (required):
  ///
  /// * [String] stripeSignature:
  ///   Checked by the handler; a missing header is rejected with 400.
  Future<void> stripeWebhook(MultipartFile body, { String? stripeSignature, }) async {
    final response = await stripeWebhookWithHttpInfo(body,  stripeSignature: stripeSignature, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
