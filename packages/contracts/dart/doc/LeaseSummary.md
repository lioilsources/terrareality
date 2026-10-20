# terra_api.model.LeaseSummary

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orgId** | **String** |  | 
**orgName** | **String** |  | [optional] 
**code** | **int** | Lease number; the variable symbol of payments unless `variable_symbol` is set. | 
**state** | [**LeaseState**](LeaseState.md) |  | 
**origin** | [**LeaseOrigin**](LeaseOrigin.md) |  | 
**cutoverOn** | [**DateTime**](DateTime.md) | Imported lease: payments are tracked from this day. | [optional] 
**variableSymbol** | **String** | Imported lease: the tenants' own variable symbol, used for payments instead of `code`. | [optional] 
**template** | [**LeaseTemplate**](LeaseTemplate.md) |  | 
**propertyAddress** | **String** |  | 
**unitLabel** | **String** |  | [optional] 
**tenantNames** | **String** |  | [optional] 
**startsOn** | [**DateTime**](DateTime.md) |  | 
**endsOn** | [**DateTime**](DateTime.md) |  | [optional] 
**rentAmount** | **int** |  | 
**currency** | **String** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


