# terra_api.api.LeasingApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**confirmLeaseSettlement**](LeasingApi.md#confirmleasesettlement) | **POST** /v1/leases/{leaseId}/settlement | Confirm the deposit settlement after the lease ended (all parties settle the lease)
[**connectBank**](LeasingApi.md#connectbank) | **POST** /v1/orgs/{orgId}/bank/connections | Link the landlord's account (open banking AIS, read only)
[**createLease**](LeasingApi.md#createlease) | **POST** /v1/orgs/{orgId}/leases | Draft a lease (from an accepted application, or with explicit parties)
[**finishBankConnection**](LeasingApi.md#finishbankconnection) | **POST** /v1/orgs/{orgId}/bank/connections/{connectionId}/finish | Complete linking after returning from the bank
[**getBankOverview**](LeasingApi.md#getbankoverview) | **GET** /v1/orgs/{orgId}/bank | Linked accounts and recent incoming transactions with their match status
[**getLease**](LeasingApi.md#getlease) | **GET** /v1/leases/{leaseId} | Lease with parties, documents, signatures and the current debt
[**getLeaseEvents**](LeasingApi.md#getleaseevents) | **GET** /v1/leases/{leaseId}/events | Hash-chained event log with its verification (export for disputes)
[**getLeaseLedger**](LeasingApi.md#getleaseledger) | **GET** /v1/leases/{leaseId}/ledger | Double-entry ledger of the lease (JSON, or CSV with format=csv)
[**getShareQR**](LeasingApi.md#getshareqr) | **GET** /v1/obligation-shares/{shareId}/qr | QR payment (QR Platba / SPAYD) of one open share as a PNG image
[**giveLeaseNotice**](LeasingApi.md#giveleasenotice) | **POST** /v1/leases/{leaseId}/notice | Give notice; the lease ends after the notice period
[**listLeaseObligations**](LeasingApi.md#listleaseobligations) | **GET** /v1/leases/{leaseId}/obligations | Payment schedule split between parties, with QR payments (SPAYD) for open shares
[**listMyLeases**](LeasingApi.md#listmyleases) | **GET** /v1/me/leases | Leases where I am a tenant
[**listOrgLeases**](LeasingApi.md#listorgleases) | **GET** /v1/orgs/{orgId}/leases | Leases of the organization
[**markSharePaid**](LeasingApi.md#marksharepaid) | **POST** /v1/orgs/{orgId}/obligation-shares/{shareId}/paid | The landlord confirms a payment arrived (\"přišlo\")
[**matchBankTransaction**](LeasingApi.md#matchbanktransaction) | **POST** /v1/orgs/{orgId}/bank/transactions/{transactionId}/match | Confirm a suggested match or match manually; or ignore the transaction
[**proposeLease**](LeasingApi.md#proposelease) | **POST** /v1/orgs/{orgId}/leases/{leaseId}/propose | Render the lease document and ask all parties to sign
[**requestLeaseChanges**](LeasingApi.md#requestleasechanges) | **POST** /v1/leases/{leaseId}/request-changes | Tenant asks the landlord to change the proposal
[**signLease**](LeasingApi.md#signlease) | **POST** /v1/leases/{leaseId}/sign | Sign the proposed document as my party (mock now; Bank iD SIGN when contracted)
[**syncBank**](LeasingApi.md#syncbank) | **POST** /v1/orgs/{orgId}/bank/sync | Fetch and match new transactions now
[**updateLease**](LeasingApi.md#updatelease) | **PUT** /v1/orgs/{orgId}/leases/{leaseId} | Edit a draft or a lease in negotiation


# **confirmLeaseSettlement**
> ConfirmLeaseSettlement200Response confirmLeaseSettlement(leaseId)

Confirm the deposit settlement after the lease ended (all parties settle the lease)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.confirmLeaseSettlement(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->confirmLeaseSettlement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**ConfirmLeaseSettlement200Response**](ConfirmLeaseSettlement200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **connectBank**
> BankLink connectBank(orgId, connectBankRequest)

Link the landlord's account (open banking AIS, read only)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final connectBankRequest = ConnectBankRequest(); // ConnectBankRequest | 

try {
    final result = api_instance.connectBank(orgId, connectBankRequest);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->connectBank: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **connectBankRequest** | [**ConnectBankRequest**](ConnectBankRequest.md)|  | 

### Return type

[**BankLink**](BankLink.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createLease**
> LeaseDetail createLease(orgId, leaseInput)

Draft a lease (from an accepted application, or with explicit parties)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final leaseInput = LeaseInput(); // LeaseInput | 

try {
    final result = api_instance.createLease(orgId, leaseInput);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->createLease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **leaseInput** | [**LeaseInput**](LeaseInput.md)|  | 

### Return type

[**LeaseDetail**](LeaseDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **finishBankConnection**
> BankConnection finishBankConnection(orgId, connectionId)

Complete linking after returning from the bank

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final connectionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.finishBankConnection(orgId, connectionId);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->finishBankConnection: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **connectionId** | **String**|  | 

### Return type

[**BankConnection**](BankConnection.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getBankOverview**
> BankOverview getBankOverview(orgId, status, before, limit)

Linked accounts and recent incoming transactions with their match status

Transactions are paged newest first; `transactions_next_before` is the cursor of the next page.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final status = status_example; // String | 
final before = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Cursor; return items with an id lower than this one.
final limit = 56; // int | 

try {
    final result = api_instance.getBankOverview(orgId, status, before, limit);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->getBankOverview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **status** | **String**|  | [optional] 
 **before** | **String**| Cursor; return items with an id lower than this one. | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**BankOverview**](BankOverview.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLease**
> LeaseDetail getLease(leaseId)

Lease with parties, documents, signatures and the current debt

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getLease(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->getLease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**LeaseDetail**](LeaseDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLeaseEvents**
> LeaseEventLog getLeaseEvents(leaseId)

Hash-chained event log with its verification (export for disputes)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getLeaseEvents(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->getLeaseEvents: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**LeaseEventLog**](LeaseEventLog.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLeaseLedger**
> List<LedgerEntry> getLeaseLedger(leaseId, format)

Double-entry ledger of the lease (JSON, or CSV with format=csv)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final format = format_example; // String | 

try {
    final result = api_instance.getLeaseLedger(leaseId, format);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->getLeaseLedger: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **format** | **String**|  | [optional] 

### Return type

[**List<LedgerEntry>**](LedgerEntry.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/csv, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getShareQR**
> MultipartFile getShareQR(shareId)

QR payment (QR Platba / SPAYD) of one open share as a PNG image

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final shareId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getShareQR(shareId);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->getShareQR: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shareId** | **String**|  | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/png, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **giveLeaseNotice**
> GiveLeaseNotice200Response giveLeaseNotice(leaseId, giveLeaseNoticeRequest)

Give notice; the lease ends after the notice period

A tenant or co-tenant gives notice without a reason. The landlord (organization member with the leases permission) must state a statutory `reason`; the notice period is then at least three months. `delivered_on` lies between 30 days ago and 7 days from today. Errors: 403 `notice_not_allowed` (guarantor, subtenant), 422 `invalid_delivered_on`, 422 `landlord_notice_reason_required` (landlord without a reason, or other_serious_reason without an explanation), 422 `notice_reason_not_applicable` (flat_needed_for_landlord_or_relative on a fixed-term lease), 409 `lease_not_active`. 

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final giveLeaseNoticeRequest = GiveLeaseNoticeRequest(); // GiveLeaseNoticeRequest | 

try {
    final result = api_instance.giveLeaseNotice(leaseId, giveLeaseNoticeRequest);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->giveLeaseNotice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **giveLeaseNoticeRequest** | [**GiveLeaseNoticeRequest**](GiveLeaseNoticeRequest.md)|  | 

### Return type

[**GiveLeaseNotice200Response**](GiveLeaseNotice200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listLeaseObligations**
> List<ObligationShare> listLeaseObligations(leaseId)

Payment schedule split between parties, with QR payments (SPAYD) for open shares

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listLeaseObligations(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->listLeaseObligations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<ObligationShare>**](ObligationShare.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyLeases**
> List<LeaseSummary> listMyLeases()

Leases where I am a tenant

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();

try {
    final result = api_instance.listMyLeases();
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->listMyLeases: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<LeaseSummary>**](LeaseSummary.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listOrgLeases**
> List<LeaseSummary> listOrgLeases(orgId, before, limit)

Leases of the organization

Paged newest first: a full page (as many items as `limit`) may have more; pass the last item's id as `before`.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final before = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Cursor; return items with an id lower than this one.
final limit = 56; // int | 

try {
    final result = api_instance.listOrgLeases(orgId, before, limit);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->listOrgLeases: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **before** | **String**| Cursor; return items with an id lower than this one. | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**List<LeaseSummary>**](LeaseSummary.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markSharePaid**
> markSharePaid(orgId, shareId, markSharePaidRequest)

The landlord confirms a payment arrived (\"přišlo\")

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final shareId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final markSharePaidRequest = MarkSharePaidRequest(); // MarkSharePaidRequest | 

try {
    api_instance.markSharePaid(orgId, shareId, markSharePaidRequest);
} catch (e) {
    print('Exception when calling LeasingApi->markSharePaid: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **shareId** | **String**|  | 
 **markSharePaidRequest** | [**MarkSharePaidRequest**](MarkSharePaidRequest.md)|  | [optional] 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **matchBankTransaction**
> matchBankTransaction(orgId, transactionId, matchBankTransactionRequest)

Confirm a suggested match or match manually; or ignore the transaction

Errors: 422 `currency_mismatch` (the transaction and the share have different currencies), 409 `already_matched`.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final transactionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final matchBankTransactionRequest = MatchBankTransactionRequest(); // MatchBankTransactionRequest | 

try {
    api_instance.matchBankTransaction(orgId, transactionId, matchBankTransactionRequest);
} catch (e) {
    print('Exception when calling LeasingApi->matchBankTransaction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **transactionId** | **String**|  | 
 **matchBankTransactionRequest** | [**MatchBankTransactionRequest**](MatchBankTransactionRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **proposeLease**
> LeaseDetail proposeLease(orgId, leaseId)

Render the lease document and ask all parties to sign

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.proposeLease(orgId, leaseId);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->proposeLease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **leaseId** | **String**|  | 

### Return type

[**LeaseDetail**](LeaseDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestLeaseChanges**
> requestLeaseChanges(leaseId, requestLeaseChangesRequest)

Tenant asks the landlord to change the proposal

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final requestLeaseChangesRequest = RequestLeaseChangesRequest(); // RequestLeaseChangesRequest | 

try {
    api_instance.requestLeaseChanges(leaseId, requestLeaseChangesRequest);
} catch (e) {
    print('Exception when calling LeasingApi->requestLeaseChanges: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **requestLeaseChangesRequest** | [**RequestLeaseChangesRequest**](RequestLeaseChangesRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signLease**
> SignLease200Response signLease(leaseId, signLeaseRequest)

Sign the proposed document as my party (mock now; Bank iD SIGN when contracted)

`provider` must be one of the lease detail's `sign_providers`. Errors: 422 `invalid_provider` (not enabled on this server), 409 `document_changed` (a new version was proposed meanwhile: reload and sign the new document), 409 `lease_not_proposed`, 409 `already_signed`, 403 `not_a_party`. 

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final signLeaseRequest = SignLeaseRequest(); // SignLeaseRequest | 

try {
    final result = api_instance.signLease(leaseId, signLeaseRequest);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->signLease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **signLeaseRequest** | [**SignLeaseRequest**](SignLeaseRequest.md)|  | 

### Return type

[**SignLease200Response**](SignLease200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **syncBank**
> SyncBank200Response syncBank(orgId)

Fetch and match new transactions now

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.syncBank(orgId);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->syncBank: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**SyncBank200Response**](SyncBank200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateLease**
> LeaseDetail updateLease(orgId, leaseId, leaseInput)

Edit a draft or a lease in negotiation

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LeasingApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final leaseInput = LeaseInput(); // LeaseInput | 

try {
    final result = api_instance.updateLease(orgId, leaseId, leaseInput);
    print(result);
} catch (e) {
    print('Exception when calling LeasingApi->updateLease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **leaseId** | **String**|  | 
 **leaseInput** | [**LeaseInput**](LeaseInput.md)|  | 

### Return type

[**LeaseDetail**](LeaseDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

