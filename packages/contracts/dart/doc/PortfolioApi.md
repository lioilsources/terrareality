# terra_api.api.PortfolioApi

## Load the API package
```dart
import 'package:terra_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createPortfolioGroup**](PortfolioApi.md#createportfoliogroup) | **POST** /v1/orgs/{orgId}/portfolio/groups | Create a group
[**createPortfolioSummary**](PortfolioApi.md#createportfoliosummary) | **POST** /v1/orgs/{orgId}/portfolio/summary | Ask the AI to summarize the portfolio (aggregates only, no personal data)
[**deletePortfolioGroup**](PortfolioApi.md#deleteportfoliogroup) | **DELETE** /v1/orgs/{orgId}/portfolio/groups/{portfolioGroupId} | Delete a group (and its rules)
[**deletePortfolioRule**](PortfolioApi.md#deleteportfoliorule) | **DELETE** /v1/orgs/{orgId}/portfolio/rules/{ruleId} | Delete a rule
[**getLeaseRisk**](PortfolioApi.md#getleaserisk) | **GET** /v1/leases/{leaseId}/risk | Risk of a lease with its factors (tenants see only the payment factors)
[**getPortfolio**](PortfolioApi.md#getportfolio) | **GET** /v1/orgs/{orgId}/portfolio | Portfolio dashboard across municipalities (risk, concentration, income, attention, trend)
[**getPortfolioSummary**](PortfolioApi.md#getportfoliosummary) | **GET** /v1/orgs/{orgId}/portfolio/summary | The latest AI summary of the portfolio (a suggestion)
[**getRentRoll**](PortfolioApi.md#getrentroll) | **GET** /v1/orgs/{orgId}/portfolio/rent-roll | Rent roll of all units and running leases (JSON, CSV or XLSX)
[**getRiskWeights**](PortfolioApi.md#getriskweights) | **GET** /v1/orgs/{orgId}/portfolio/risk-weights | Factor weights of the lease risk score
[**listPortfolioGroups**](PortfolioApi.md#listportfoliogroups) | **GET** /v1/orgs/{orgId}/portfolio/groups | Groups (tags) of properties and leases
[**listPortfolioRules**](PortfolioApi.md#listportfoliorules) | **GET** /v1/orgs/{orgId}/portfolio/rules | Rules per municipality or group (overrides of the jurisdiction defaults)
[**resolvePortfolioRules**](PortfolioApi.md#resolveportfoliorules) | **GET** /v1/orgs/{orgId}/portfolio/rules/resolve | Rules a new lease at a place would get (lease form defaults)
[**savePortfolioRule**](PortfolioApi.md#saveportfoliorule) | **PUT** /v1/orgs/{orgId}/portfolio/rules | Set the rules of a municipality or a group (applies to new leases)
[**setRiskWeights**](PortfolioApi.md#setriskweights) | **PUT** /v1/orgs/{orgId}/portfolio/risk-weights | Set factor weights (0 switches a factor off); leases are rescored
[**updatePortfolioGroup**](PortfolioApi.md#updateportfoliogroup) | **PUT** /v1/orgs/{orgId}/portfolio/groups/{portfolioGroupId} | Rename a group and replace its members


# **createPortfolioGroup**
> PortfolioGroup createPortfolioGroup(orgId, portfolioGroupInput)

Create a group

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final portfolioGroupInput = PortfolioGroupInput(); // PortfolioGroupInput | 

try {
    final result = api_instance.createPortfolioGroup(orgId, portfolioGroupInput);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->createPortfolioGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **portfolioGroupInput** | [**PortfolioGroupInput**](PortfolioGroupInput.md)|  | 

### Return type

[**PortfolioGroup**](PortfolioGroup.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createPortfolioSummary**
> PortfolioSummary createPortfolioSummary(orgId)

Ask the AI to summarize the portfolio (aggregates only, no personal data)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.createPortfolioSummary(orgId);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->createPortfolioSummary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**PortfolioSummary**](PortfolioSummary.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePortfolioGroup**
> deletePortfolioGroup(orgId, portfolioGroupId)

Delete a group (and its rules)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final portfolioGroupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deletePortfolioGroup(orgId, portfolioGroupId);
} catch (e) {
    print('Exception when calling PortfolioApi->deletePortfolioGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **portfolioGroupId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePortfolioRule**
> deletePortfolioRule(orgId, ruleId)

Delete a rule

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final ruleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deletePortfolioRule(orgId, ruleId);
} catch (e) {
    print('Exception when calling PortfolioApi->deletePortfolioRule: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **ruleId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLeaseRisk**
> LeaseRisk getLeaseRisk(leaseId)

Risk of a lease with its factors (tenants see only the payment factors)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getLeaseRisk(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->getLeaseRisk: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**LeaseRisk**](LeaseRisk.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPortfolio**
> PortfolioDashboard getPortfolio(orgId, municipality, region, groupId)

Portfolio dashboard across municipalities (risk, concentration, income, attention, trend)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final municipality = municipality_example; // String | Admin path of a municipality.
final region = region_example; // String | Admin path of a region.
final groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPortfolio(orgId, municipality, region, groupId);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->getPortfolio: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **municipality** | **String**| Admin path of a municipality. | [optional] 
 **region** | **String**| Admin path of a region. | [optional] 
 **groupId** | **String**|  | [optional] 

### Return type

[**PortfolioDashboard**](PortfolioDashboard.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPortfolioSummary**
> GetPortfolioSummary200Response getPortfolioSummary(orgId)

The latest AI summary of the portfolio (a suggestion)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPortfolioSummary(orgId);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->getPortfolioSummary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**GetPortfolioSummary200Response**](GetPortfolioSummary200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRentRoll**
> RentRoll getRentRoll(orgId, municipality, region, groupId, format)

Rent roll of all units and running leases (JSON, CSV or XLSX)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final municipality = municipality_example; // String | Admin path of a municipality.
final region = region_example; // String | Admin path of a region.
final groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final format = format_example; // String | 

try {
    final result = api_instance.getRentRoll(orgId, municipality, region, groupId, format);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->getRentRoll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **municipality** | **String**| Admin path of a municipality. | [optional] 
 **region** | **String**| Admin path of a region. | [optional] 
 **groupId** | **String**|  | [optional] 
 **format** | **String**|  | [optional] 

### Return type

[**RentRoll**](RentRoll.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, text/csv, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRiskWeights**
> RiskWeights getRiskWeights(orgId)

Factor weights of the lease risk score

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getRiskWeights(orgId);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->getRiskWeights: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**RiskWeights**](RiskWeights.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPortfolioGroups**
> PortfolioGroups listPortfolioGroups(orgId)

Groups (tags) of properties and leases

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listPortfolioGroups(orgId);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->listPortfolioGroups: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**PortfolioGroups**](PortfolioGroups.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPortfolioRules**
> PortfolioRuleList listPortfolioRules(orgId)

Rules per municipality or group (overrides of the jurisdiction defaults)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listPortfolioRules(orgId);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->listPortfolioRules: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 

### Return type

[**PortfolioRuleList**](PortfolioRuleList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resolvePortfolioRules**
> ResolvedRules resolvePortfolioRules(orgId, listingId, ruianId, address)

Rules a new lease at a place would get (lease form defaults)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final listingId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final ruianId = 789; // int | 
final address = address_example; // String | 

try {
    final result = api_instance.resolvePortfolioRules(orgId, listingId, ruianId, address);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->resolvePortfolioRules: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **listingId** | **String**|  | [optional] 
 **ruianId** | **int**|  | [optional] 
 **address** | **String**|  | [optional] 

### Return type

[**ResolvedRules**](ResolvedRules.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **savePortfolioRule**
> ReportConversation201Response savePortfolioRule(orgId, portfolioRuleInput)

Set the rules of a municipality or a group (applies to new leases)

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final portfolioRuleInput = PortfolioRuleInput(); // PortfolioRuleInput | 

try {
    final result = api_instance.savePortfolioRule(orgId, portfolioRuleInput);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->savePortfolioRule: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **portfolioRuleInput** | [**PortfolioRuleInput**](PortfolioRuleInput.md)|  | 

### Return type

[**ReportConversation201Response**](ReportConversation201Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setRiskWeights**
> RiskWeights setRiskWeights(orgId, setRiskWeightsRequest)

Set factor weights (0 switches a factor off); leases are rescored

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final setRiskWeightsRequest = SetRiskWeightsRequest(); // SetRiskWeightsRequest | 

try {
    final result = api_instance.setRiskWeights(orgId, setRiskWeightsRequest);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->setRiskWeights: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **setRiskWeightsRequest** | [**SetRiskWeightsRequest**](SetRiskWeightsRequest.md)|  | 

### Return type

[**RiskWeights**](RiskWeights.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePortfolioGroup**
> PortfolioGroup updatePortfolioGroup(orgId, portfolioGroupId, portfolioGroupInput)

Rename a group and replace its members

### Example
```dart
import 'package:terra_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PortfolioApi();
final orgId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final portfolioGroupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final portfolioGroupInput = PortfolioGroupInput(); // PortfolioGroupInput | 

try {
    final result = api_instance.updatePortfolioGroup(orgId, portfolioGroupId, portfolioGroupInput);
    print(result);
} catch (e) {
    print('Exception when calling PortfolioApi->updatePortfolioGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orgId** | **String**|  | 
 **portfolioGroupId** | **String**|  | 
 **portfolioGroupInput** | [**PortfolioGroupInput**](PortfolioGroupInput.md)|  | 

### Return type

[**PortfolioGroup**](PortfolioGroup.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

