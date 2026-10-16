# terra_api.api.ApplicationsApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**bookViewing**](ApplicationsApi.md#bookviewing) | **POST** /v1/applications/{applicationId}/bookings | Book a viewing slot (replaces an earlier booking of this application)
[**cancelViewing**](ApplicationsApi.md#cancelviewing) | **DELETE** /v1/viewing-bookings/{bookingId} | Cancel a booked viewing
[**checkInsolvency**](ApplicationsApi.md#checkinsolvency) | **POST** /v1/me/passport/insolvency-check | Check the insolvency register (needs a verified identity; once a day)
[**completeIncomeUpload**](ApplicationsApi.md#completeincomeupload) | **POST** /v1/me/passport/income/complete | Check the uploaded income proof and attach it to the passport
[**consentApplication**](ApplicationsApi.md#consentapplication) | **POST** /v1/applications/{applicationId}/consent | Consent to a group application; the last consent submits it
[**createApplication**](ApplicationsApi.md#createapplication) | **POST** /v1/applications | Apply for a listing, alone or as a group (a group application waits for every member's consent)
[**createGroup**](ApplicationsApi.md#creategroup) | **POST** /v1/groups | Create a tenant group and invite flatmates by e-mail
[**createIncomeUpload**](ApplicationsApi.md#createincomeupload) | **POST** /v1/me/passport/income | Reserve an upload for an income proof (PUT the file, then complete)
[**createViewingSlot**](ApplicationsApi.md#createviewingslot) | **POST** /v1/orgs/{orgId}/listings/{listingId}/viewing-slots | Offer a viewing slot
[**decideApplication**](ApplicationsApi.md#decideapplication) | **POST** /v1/orgs/{orgId}/applications/{applicationId}/decision | Invite to a viewing, accept (other applicants get an automatic answer) or reject with a reason code
[**deleteIncomeProof**](ApplicationsApi.md#deleteincomeproof) | **DELETE** /v1/me/passport/income | Remove my income proof
[**deleteViewingSlot**](ApplicationsApi.md#deleteviewingslot) | **DELETE** /v1/orgs/{orgId}/viewing-slots/{slotId} | Remove a slot; active bookings are cancelled and every booked applicant is notified (e-mail and push)
[**getApplicantIncomeProof**](ApplicationsApi.md#getapplicantincomeproof) | **GET** /v1/orgs/{orgId}/applications/{applicationId}/people/{userId}/income-proof | Short-lived download link of an applicant's income proof (every call is audited)
[**getApplication**](ApplicationsApi.md#getapplication) | **GET** /v1/applications/{applicationId} | Application with consents, bookable viewing slots and my booking
[**getGroup**](ApplicationsApi.md#getgroup) | **GET** /v1/groups/{groupId} | Group with members and chat (chat only for joined members)
[**getPassport**](ApplicationsApi.md#getpassport) | **GET** /v1/me/passport | My Tenant Passport
[**getRoommateProfile**](ApplicationsApi.md#getroommateprofile) | **GET** /v1/me/roommate-profile | My \"looking for a flatmate\" profile (404 when none)
[**inviteToGroup**](ApplicationsApi.md#invitetogroup) | **POST** /v1/groups/{groupId}/invitations | Invite a flatmate by e-mail
[**joinGroup**](ApplicationsApi.md#joingroup) | **POST** /v1/groups/{groupId}/join | Accept an invitation (consent to act as a member of the group)
[**leaveGroup**](ApplicationsApi.md#leavegroup) | **POST** /v1/groups/{groupId}/leave | Leave a group
[**listListingApplications**](ApplicationsApi.md#listlistingapplications) | **GET** /v1/orgs/{orgId}/listings/{listingId}/applications | Applicants of a listing, verified first, with passport facts and the AI summary
[**listListingRoommates**](ApplicationsApi.md#listlistingroommates) | **GET** /v1/orgs/{orgId}/listings/{listingId}/roommates | Seekers who match a published room listing
[**listMyApplications**](ApplicationsApi.md#listmyapplications) | **GET** /v1/applications | My applications, including my groups' applications
[**listMyGroups**](ApplicationsApi.md#listmygroups) | **GET** /v1/groups | Groups I belong to or am invited to
[**listMyViewings**](ApplicationsApi.md#listmyviewings) | **GET** /v1/me/viewings | My upcoming viewings
[**listRoommates**](ApplicationsApi.md#listroommates) | **GET** /v1/roommates | Other seekers ranked by match with my profile
[**listViewingSlots**](ApplicationsApi.md#listviewingslots) | **GET** /v1/orgs/{orgId}/listings/{listingId}/viewing-slots | Upcoming viewing slots with bookings
[**saveRoommateProfile**](ApplicationsApi.md#saveroommateprofile) | **PUT** /v1/me/roommate-profile | Create or update my roommate profile
[**sendGroupMessage**](ApplicationsApi.md#sendgroupmessage) | **POST** /v1/groups/{groupId}/messages | Post to the group chat
[**withdrawApplication**](ApplicationsApi.md#withdrawapplication) | **POST** /v1/applications/{applicationId}/withdraw | Withdraw my application


# **bookViewing**
> ReportConversation201Response bookViewing(applicationId, bookViewingRequest)

Book a viewing slot (replaces an earlier booking of this application)

Viewings of a demo listing (is_demo) are refused with 409 and problem code demo_listing.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final applicationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final bookViewingRequest = BookViewingRequest(); // BookViewingRequest | 

try {
    final result = api_instance.bookViewing(applicationId, bookViewingRequest);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->bookViewing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **applicationId** | **String**|  | 
 **bookViewingRequest** | [**BookViewingRequest**](BookViewingRequest.md)|  | 

### Return type

[**ReportConversation201Response**](ReportConversation201Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cancelViewing**
> cancelViewing(bookingId)

Cancel a booked viewing

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final bookingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.cancelViewing(bookingId);
} catch (e) {
    print('Exception when calling ApplicationsApi->cancelViewing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **bookingId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **checkInsolvency**
> Passport checkInsolvency()

Check the insolvency register (needs a verified identity; once a day)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();

try {
    final result = api_instance.checkInsolvency();
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->checkInsolvency: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Passport**](Passport.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **completeIncomeUpload**
> Passport completeIncomeUpload(completeIncomeUploadRequest)

Check the uploaded income proof and attach it to the passport

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final completeIncomeUploadRequest = CompleteIncomeUploadRequest(); // CompleteIncomeUploadRequest | 

try {
    final result = api_instance.completeIncomeUpload(completeIncomeUploadRequest);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->completeIncomeUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **completeIncomeUploadRequest** | [**CompleteIncomeUploadRequest**](CompleteIncomeUploadRequest.md)|  | 

### Return type

[**Passport**](Passport.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **consentApplication**
> consentApplication(applicationId)

Consent to a group application; the last consent submits it

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final applicationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.consentApplication(applicationId);
} catch (e) {
    print('Exception when calling ApplicationsApi->consentApplication: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **applicationId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createApplication**
> ApplicationDetail createApplication(applicationInput)

Apply for a listing, alone or as a group (a group application waits for every member's consent)

A demo listing (is_demo) is refused with 409 and problem code demo_listing.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final applicationInput = ApplicationInput(); // ApplicationInput | 

try {
    final result = api_instance.createApplication(applicationInput);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->createApplication: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **applicationInput** | [**ApplicationInput**](ApplicationInput.md)|  | 

### Return type

[**ApplicationDetail**](ApplicationDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createGroup**
> Group createGroup(createGroupRequest)

Create a tenant group and invite flatmates by e-mail

Errors: 403 `email_unverified` (confirm the e-mail first), 429 `rate_limited` (more than 30 invitations a day).

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final createGroupRequest = CreateGroupRequest(); // CreateGroupRequest | 

try {
    final result = api_instance.createGroup(createGroupRequest);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->createGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createGroupRequest** | [**CreateGroupRequest**](CreateGroupRequest.md)|  | 

### Return type

[**Group**](Group.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createIncomeUpload**
> CreateIncomeUpload201Response createIncomeUpload(createIncomeUploadRequest)

Reserve an upload for an income proof (PUT the file, then complete)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final createIncomeUploadRequest = CreateIncomeUploadRequest(); // CreateIncomeUploadRequest | 

try {
    final result = api_instance.createIncomeUpload(createIncomeUploadRequest);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->createIncomeUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createIncomeUploadRequest** | [**CreateIncomeUploadRequest**](CreateIncomeUploadRequest.md)|  | 

### Return type

[**CreateIncomeUpload201Response**](CreateIncomeUpload201Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createViewingSlot**
> ViewingSlot createViewingSlot(orgId, listingId, createViewingSlotRequest)

Offer a viewing slot

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final createViewingSlotRequest = CreateViewingSlotRequest(); // CreateViewingSlotRequest | 

try {
    final result = api_instance.createViewingSlot(orgId, listingId, createViewingSlotRequest);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->createViewingSlot: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 
 **createViewingSlotRequest** | [**CreateViewingSlotRequest**](CreateViewingSlotRequest.md)|  | 

### Return type

[**ViewingSlot**](ViewingSlot.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **decideApplication**
> decideApplication(orgId, applicationId, decideApplicationRequest)

Invite to a viewing, accept (other applicants get an automatic answer) or reject with a reason code

The applicants' e-mails and pushes are queued in the same transaction as the decision. Errors: 409 `listing_already_accepted` (another application of the listing was accepted), 409 `application_closed`, 422 `invalid_reason`. 

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final applicationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final decideApplicationRequest = DecideApplicationRequest(); // DecideApplicationRequest | 

try {
    api_instance.decideApplication(orgId, applicationId, decideApplicationRequest);
} catch (e) {
    print('Exception when calling ApplicationsApi->decideApplication: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **applicationId** | **String**|  | 
 **decideApplicationRequest** | [**DecideApplicationRequest**](DecideApplicationRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteIncomeProof**
> deleteIncomeProof()

Remove my income proof

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();

try {
    api_instance.deleteIncomeProof();
} catch (e) {
    print('Exception when calling ApplicationsApi->deleteIncomeProof: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteViewingSlot**
> deleteViewingSlot(orgId, slotId)

Remove a slot; active bookings are cancelled and every booked applicant is notified (e-mail and push)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final slotId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteViewingSlot(orgId, slotId);
} catch (e) {
    print('Exception when calling ApplicationsApi->deleteViewingSlot: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **slotId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getApplicantIncomeProof**
> DownloadLink getApplicantIncomeProof(orgId, applicationId, userId)

Short-lived download link of an applicant's income proof (every call is audited)

Only while the application is open (submitted, invited) and for 30 days after it was accepted. Errors: 404 `income_proof_not_found`, 404 `application_not_found`. 

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final applicationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getApplicantIncomeProof(orgId, applicationId, userId);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->getApplicantIncomeProof: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **applicationId** | **String**|  | 
 **userId** | **String**|  | 

### Return type

[**DownloadLink**](DownloadLink.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getApplication**
> ApplicationDetail getApplication(applicationId)

Application with consents, bookable viewing slots and my booking

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final applicationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getApplication(applicationId);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->getApplication: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **applicationId** | **String**|  | 

### Return type

[**ApplicationDetail**](ApplicationDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getGroup**
> Group getGroup(groupId)

Group with members and chat (chat only for joined members)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getGroup(groupId);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->getGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**Group**](Group.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPassport**
> Passport getPassport()

My Tenant Passport

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();

try {
    final result = api_instance.getPassport();
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->getPassport: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Passport**](Passport.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRoommateProfile**
> RoommateProfile getRoommateProfile()

My \"looking for a flatmate\" profile (404 when none)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();

try {
    final result = api_instance.getRoommateProfile();
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->getRoommateProfile: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**RoommateProfile**](RoommateProfile.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **inviteToGroup**
> inviteToGroup(groupId, inviteToGroupRequest)

Invite a flatmate by e-mail

Errors: 403 `email_unverified`, 429 `rate_limited` (more than 30 invitations a day), 422 `group_full`.

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final inviteToGroupRequest = InviteToGroupRequest(); // InviteToGroupRequest | 

try {
    api_instance.inviteToGroup(groupId, inviteToGroupRequest);
} catch (e) {
    print('Exception when calling ApplicationsApi->inviteToGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **inviteToGroupRequest** | [**InviteToGroupRequest**](InviteToGroupRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **joinGroup**
> joinGroup(groupId)

Accept an invitation (consent to act as a member of the group)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.joinGroup(groupId);
} catch (e) {
    print('Exception when calling ApplicationsApi->joinGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **leaveGroup**
> leaveGroup(groupId)

Leave a group

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.leaveGroup(groupId);
} catch (e) {
    print('Exception when calling ApplicationsApi->leaveGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listListingApplications**
> List<Applicant> listListingApplications(orgId, listingId)

Applicants of a listing, verified first, with passport facts and the AI summary

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listListingApplications(orgId, listingId);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->listListingApplications: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 

### Return type

[**List<Applicant>**](Applicant.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listListingRoommates**
> List<RoommateMatch> listListingRoommates(orgId, listingId)

Seekers who match a published room listing

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listListingRoommates(orgId, listingId);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->listListingRoommates: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 

### Return type

[**List<RoommateMatch>**](RoommateMatch.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyApplications**
> List<Application> listMyApplications()

My applications, including my groups' applications

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();

try {
    final result = api_instance.listMyApplications();
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->listMyApplications: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Application>**](Application.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyGroups**
> List<GroupSummary> listMyGroups()

Groups I belong to or am invited to

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();

try {
    final result = api_instance.listMyGroups();
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->listMyGroups: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<GroupSummary>**](GroupSummary.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyViewings**
> List<Viewing> listMyViewings()

My upcoming viewings

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();

try {
    final result = api_instance.listMyViewings();
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->listMyViewings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Viewing>**](Viewing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRoommates**
> List<RoommateMatch> listRoommates(area)

Other seekers ranked by match with my profile

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final area = area_example; // String | Admin unit path.

try {
    final result = api_instance.listRoommates(area);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->listRoommates: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **area** | **String**| Admin unit path. | [optional] 

### Return type

[**List<RoommateMatch>**](RoommateMatch.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listViewingSlots**
> List<ViewingSlot> listViewingSlots(orgId, listingId)

Upcoming viewing slots with bookings

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listViewingSlots(orgId, listingId);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->listViewingSlots: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | 

### Return type

[**List<ViewingSlot>**](ViewingSlot.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **saveRoommateProfile**
> RoommateProfile saveRoommateProfile(roommateProfile)

Create or update my roommate profile

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final roommateProfile = RoommateProfile(); // RoommateProfile | 

try {
    final result = api_instance.saveRoommateProfile(roommateProfile);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->saveRoommateProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roommateProfile** | [**RoommateProfile**](RoommateProfile.md)|  | 

### Return type

[**RoommateProfile**](RoommateProfile.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendGroupMessage**
> GroupMessage sendGroupMessage(groupId, sendGroupMessageRequest)

Post to the group chat

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final sendGroupMessageRequest = SendGroupMessageRequest(); // SendGroupMessageRequest | 

try {
    final result = api_instance.sendGroupMessage(groupId, sendGroupMessageRequest);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->sendGroupMessage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **sendGroupMessageRequest** | [**SendGroupMessageRequest**](SendGroupMessageRequest.md)|  | 

### Return type

[**GroupMessage**](GroupMessage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **withdrawApplication**
> withdrawApplication(applicationId)

Withdraw my application

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final applicationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.withdrawApplication(applicationId);
} catch (e) {
    print('Exception when calling ApplicationsApi->withdrawApplication: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **applicationId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

