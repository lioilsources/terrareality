# terra_api.model.LeaseInput

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**applicationId** | **String** |  | [optional] 
**listingId** | **String** |  | [optional] 
**template** | [**LeaseTemplate**](LeaseTemplate.md) |  | 
**startsOn** | [**DateTime**](DateTime.md) |  | 
**endsOn** | [**DateTime**](DateTime.md) |  | [optional] 
**rentAmount** | **int** |  | 
**servicesAmount** | **int** |  | [optional] 
**depositAmount** | **int** |  | [optional] 
**dueDay** | **int** |  | [optional] [default to 15]
**noticeMonths** | **int** |  | [optional] [default to 3]
**payeeIban** | **String** |  | 
**payeeName** | **String** |  | 
**clauses** | **List<String>** |  | [optional] [default to const []]
**propertyAddress** | **String** |  | [optional] 
**unitLabel** | **String** |  | [optional] 
**parties** | [**List<LeasePartyInput>**](LeasePartyInput.md) |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


