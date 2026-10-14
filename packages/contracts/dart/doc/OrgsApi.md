# terra_api.api.OrgsApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptInvitation**](OrgsApi.md#acceptinvitation) | **POST** /v1/invitations/{token}/accept | Accept an invitation; the invitee e-mail must match my account
[**createOrg**](OrgsApi.md#createorg) | **POST** /v1/orgs | Create a company organization; the caller becomes its owner
[**createOrgInvitation**](OrgsApi.md#createorginvitation) | **POST** /v1/orgs/{orgId}/invitations | Invite someone by e-mail (owner, admin)
[**getInvitation**](OrgsApi.md#getinvitation) | **GET** /v1/invitations/{token} | Preview an invitation before accepting it
[**getOrg**](OrgsApi.md#getorg) | **GET** /v1/orgs/{orgId} | One organization and my role in it
[**listMyOrgs**](OrgsApi.md#listmyorgs) | **GET** /v1/orgs | Organizations I belong to, personal first
[**listOrgAudit**](OrgsApi.md#listorgaudit) | **GET** /v1/orgs/{orgId}/audit | Audit log of an organization (owner, admin)
[**listOrgInvitations**](OrgsApi.md#listorginvitations) | **GET** /v1/orgs/{orgId}/invitations | Open invitations
[**listOrgMembers**](OrgsApi.md#listorgmembers) | **GET** /v1/orgs/{orgId}/members | Members of an organization
[**removeOrgMember**](OrgsApi.md#removeorgmember) | **DELETE** /v1/orgs/{orgId}/members/{userId} | Remove a member, or leave the organization when userId is me
[**revokeOrgInvitation**](OrgsApi.md#revokeorginvitation) | **DELETE** /v1/orgs/{orgId}/invitations/{invitationId} | Revoke an open invitation
[**updateOrg**](OrgsApi.md#updateorg) | **PATCH** /v1/orgs/{orgId} | Update organization details (owner, admin)
[**updateOrgMember**](OrgsApi.md#updateorgmember) | **PATCH** /v1/orgs/{orgId}/members/{userId} | Change a member's role (owner, admin)


# **acceptInvitation**
> OrgMembership acceptInvitation(token)

Accept an invitation; the invitee e-mail must match my account

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final token = token_example; // String | 

try {
    final result = api_instance.acceptInvitation(token);
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->acceptInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 

### Return type

[**OrgMembership**](OrgMembership.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createOrg**
> OrgMembership createOrg(orgInput)

Create a company organization; the caller becomes its owner

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgInput = OrgInput(); // OrgInput | 

try {
    final result = api_instance.createOrg(orgInput);
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->createOrg: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgInput** | [**OrgInput**](OrgInput.md)|  | 

### Return type

[**OrgMembership**](OrgMembership.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createOrgInvitation**
> Invitation createOrgInvitation(orgId, invitationInput)

Invite someone by e-mail (owner, admin)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final invitationInput = InvitationInput(); // InvitationInput | 

try {
    final result = api_instance.createOrgInvitation(orgId, invitationInput);
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->createOrgInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **invitationInput** | [**InvitationInput**](InvitationInput.md)|  | 

### Return type

[**Invitation**](Invitation.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getInvitation**
> InvitationPreview getInvitation(token)

Preview an invitation before accepting it

### Example
```dart
import 'package:terra_api/api.dart';

final api_instance = OrgsApi();
final token = token_example; // String | 

try {
    final result = api_instance.getInvitation(token);
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->getInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 

### Return type

[**InvitationPreview**](InvitationPreview.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOrg**
> OrgMembership getOrg(orgId)

One organization and my role in it

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getOrg(orgId);
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->getOrg: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**OrgMembership**](OrgMembership.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyOrgs**
> List<OrgMembership> listMyOrgs()

Organizations I belong to, personal first

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();

try {
    final result = api_instance.listMyOrgs();
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->listMyOrgs: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<OrgMembership>**](OrgMembership.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listOrgAudit**
> AuditPage listOrgAudit(orgId, before, limit)

Audit log of an organization (owner, admin)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final before = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Cursor; return items with an id lower than this one.
final limit = 56; // int | 

try {
    final result = api_instance.listOrgAudit(orgId, before, limit);
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->listOrgAudit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **before** | **String**| Cursor; return items with an id lower than this one. | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**AuditPage**](AuditPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listOrgInvitations**
> List<Invitation> listOrgInvitations(orgId)

Open invitations

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listOrgInvitations(orgId);
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->listOrgInvitations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**List<Invitation>**](Invitation.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listOrgMembers**
> List<Member> listOrgMembers(orgId)

Members of an organization

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listOrgMembers(orgId);
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->listOrgMembers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**List<Member>**](Member.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeOrgMember**
> removeOrgMember(orgId, userId)

Remove a member, or leave the organization when userId is me

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.removeOrgMember(orgId, userId);
} catch (e) {
    print('Exception when calling OrgsApi->removeOrgMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **userId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revokeOrgInvitation**
> revokeOrgInvitation(orgId, invitationId)

Revoke an open invitation

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final invitationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.revokeOrgInvitation(orgId, invitationId);
} catch (e) {
    print('Exception when calling OrgsApi->revokeOrgInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **invitationId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateOrg**
> OrgMembership updateOrg(orgId, orgInput)

Update organization details (owner, admin)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final orgInput = OrgInput(); // OrgInput | 

try {
    final result = api_instance.updateOrg(orgId, orgInput);
    print(result);
} catch (e) {
    print('Exception when calling OrgsApi->updateOrg: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **orgInput** | [**OrgInput**](OrgInput.md)|  | 

### Return type

[**OrgMembership**](OrgMembership.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateOrgMember**
> updateOrgMember(orgId, userId, roleInput)

Change a member's role (owner, admin)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OrgsApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final roleInput = RoleInput(); // RoleInput | 

try {
    api_instance.updateOrgMember(orgId, userId, roleInput);
} catch (e) {
    print('Exception when calling OrgsApi->updateOrgMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **userId** | **String**|  | 
 **roleInput** | [**RoleInput**](RoleInput.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

