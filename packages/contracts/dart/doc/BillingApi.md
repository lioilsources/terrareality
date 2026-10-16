# terra_api.api.BillingApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createPaymentLink**](BillingApi.md#createpaymentlink) | **POST** /v1/obligation-shares/{shareId}/payment-link | Card payment link in the landlord's own Revolut merchant account (money goes landlord-direct)
[**createPromoCheckout**](BillingApi.md#createpromocheckout) | **POST** /v1/orgs/{orgId}/listings/{listingId}/promotions/checkout | Order a promotion of a listing; pay by card on the returned Stripe Checkout page
[**deleteRevolutAccount**](BillingApi.md#deleterevolutaccount) | **DELETE** /v1/orgs/{orgId}/revolut | Disconnect the Revolut account
[**getInvoicePdf**](BillingApi.md#getinvoicepdf) | **GET** /v1/orgs/{orgId}/invoices/{invoiceId}/pdf | The invoice as a PDF
[**getOrder**](BillingApi.md#getorder) | **GET** /v1/orgs/{orgId}/orders/{orderId} | One order (the checkout success page polls it until paid)
[**getPaymentLink**](BillingApi.md#getpaymentlink) | **GET** /v1/obligation-shares/{shareId}/payment-link | The latest valid payment link of a share (404 when none)
[**getRevolutAccount**](BillingApi.md#getrevolutaccount) | **GET** /v1/orgs/{orgId}/revolut | The landlord's own Revolut Business merchant account (connection state only, never the key)
[**listInvoices**](BillingApi.md#listinvoices) | **GET** /v1/orgs/{orgId}/invoices | Invoices (daňové doklady) issued to the organization
[**listOrders**](BillingApi.md#listorders) | **GET** /v1/orgs/{orgId}/orders | Promotion orders of the organization
[**listPromoProducts**](BillingApi.md#listpromoproducts) | **GET** /v1/promo-products | Active promotion products (topování, zvýraznění, balíček) with net, VAT and gross prices
[**listPromotions**](BillingApi.md#listpromotions) | **GET** /v1/orgs/{orgId}/listings/{listingId}/promotions | Paid promotion periods of a listing (running, scheduled and past)
[**putRevolutAccount**](BillingApi.md#putrevolutaccount) | **PUT** /v1/orgs/{orgId}/revolut | Connect the landlord's Revolut Business merchant API key (stored encrypted)
[**stripeWebhook**](BillingApi.md#stripewebhook) | **POST** /v1/webhooks/stripe | Stripe events (checkout.session.completed and friends); verified by the Stripe-Signature header


# **createPaymentLink**
> PaymentLink createPaymentLink(shareId)

Card payment link in the landlord's own Revolut merchant account (money goes landlord-direct)

For the share's party and members of the owning organization. 409 when the organization has no Revolut account; 404 when the payments.revolut flag is off. The platform never holds the money (ADR 0002).

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final shareId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.createPaymentLink(shareId);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->createPaymentLink: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shareId** | **String**|  | 

### Return type

[**PaymentLink**](PaymentLink.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createPromoCheckout**
> PromoCheckout createPromoCheckout(orgId, listingId, promoCheckoutInput)

Order a promotion of a listing; pay by card on the returned Stripe Checkout page

The order stays pending until the signed Stripe webhook confirms the payment. Stripe collects only the platform's own fee for promotion; rent never goes through the platform (ADR 0002).

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final promoCheckoutInput = PromoCheckoutInput(); // PromoCheckoutInput | 

try {
    final result = api_instance.createPromoCheckout(orgId, listingId, promoCheckoutInput);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->createPromoCheckout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 
 **promoCheckoutInput** | [**PromoCheckoutInput**](PromoCheckoutInput.md)|  | 

### Return type

[**PromoCheckout**](PromoCheckout.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteRevolutAccount**
> deleteRevolutAccount(orgId)

Disconnect the Revolut account

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteRevolutAccount(orgId);
} catch (e) {
    print('Exception when calling BillingApi->deleteRevolutAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getInvoicePdf**
> MultipartFile getInvoicePdf(orgId, invoiceId)

The invoice as a PDF

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final invoiceId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getInvoicePdf(orgId, invoiceId);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->getInvoicePdf: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **invoiceId** | **String**|  | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/pdf, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOrder**
> Order getOrder(orgId, orderId)

One order (the checkout success page polls it until paid)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final orderId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getOrder(orgId, orderId);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->getOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **orderId** | **String**|  | 

### Return type

[**Order**](Order.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPaymentLink**
> PaymentLink getPaymentLink(shareId)

The latest valid payment link of a share (404 when none)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final shareId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPaymentLink(shareId);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->getPaymentLink: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shareId** | **String**|  | 

### Return type

[**PaymentLink**](PaymentLink.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRevolutAccount**
> RevolutAccount getRevolutAccount(orgId)

The landlord's own Revolut Business merchant account (connection state only, never the key)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getRevolutAccount(orgId);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->getRevolutAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**RevolutAccount**](RevolutAccount.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listInvoices**
> InvoiceList listInvoices(orgId, before, limit)

Invoices (daňové doklady) issued to the organization

Paged newest first; `next_before` is the cursor of the next page.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final before = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Cursor; return items with an id lower than this one.
final limit = 56; // int | 

try {
    final result = api_instance.listInvoices(orgId, before, limit);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->listInvoices: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **before** | **String**| Cursor; return items with an id lower than this one. | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**InvoiceList**](InvoiceList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listOrders**
> OrderList listOrders(orgId, before, limit)

Promotion orders of the organization

Paged newest first; `next_before` is the cursor of the next page.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final before = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Cursor; return items with an id lower than this one.
final limit = 56; // int | 

try {
    final result = api_instance.listOrders(orgId, before, limit);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->listOrders: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **before** | **String**| Cursor; return items with an id lower than this one. | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**OrderList**](OrderList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPromoProducts**
> PromoProductList listPromoProducts()

Active promotion products (topování, zvýraznění, balíček) with net, VAT and gross prices

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();

try {
    final result = api_instance.listPromoProducts();
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->listPromoProducts: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PromoProductList**](PromoProductList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPromotions**
> PromotionList listPromotions(orgId, listingId)

Paid promotion periods of a listing (running, scheduled and past)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listPromotions(orgId, listingId);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->listPromotions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 

### Return type

[**PromotionList**](PromotionList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putRevolutAccount**
> RevolutAccount putRevolutAccount(orgId, revolutAccountInput)

Connect the landlord's Revolut Business merchant API key (stored encrypted)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BillingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final revolutAccountInput = RevolutAccountInput(); // RevolutAccountInput | 

try {
    final result = api_instance.putRevolutAccount(orgId, revolutAccountInput);
    print(result);
} catch (e) {
    print('Exception when calling BillingApi->putRevolutAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **revolutAccountInput** | [**RevolutAccountInput**](RevolutAccountInput.md)|  | 

### Return type

[**RevolutAccount**](RevolutAccount.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stripeWebhook**
> stripeWebhook(body, stripeSignature)

Stripe events (checkout.session.completed and friends); verified by the Stripe-Signature header

The raw body is needed to verify the signature, so it is accepted as bytes. Events are processed once.

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = BillingApi();
final body = MultipartFile(); // MultipartFile | 
final stripeSignature = stripeSignature_example; // String | Checked by the handler; a missing header is rejected with 400.

try {
    api_instance.stripeWebhook(body, stripeSignature);
} catch (e) {
    print('Exception when calling BillingApi->stripeWebhook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | **MultipartFile**|  | 
 **stripeSignature** | **String**| Checked by the handler; a missing header is rejected with 400. | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/octet-stream
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

