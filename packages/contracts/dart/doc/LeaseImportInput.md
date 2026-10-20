# terra_api.model.LeaseImportInput

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**listingId** | **String** |  | [optional] 
**template** | [**LeaseTemplate**](LeaseTemplate.md) |  | 
**startsOn** | [**DateTime**](DateTime.md) |  | 
**endsOn** | [**DateTime**](DateTime.md) |  | [optional] 
**rentAmount** | **int** |  | 
**servicesAmount** | **int** |  | [optional] 
**depositAmount** | **int** |  | [optional] 
**depositHeld** | **bool** | The landlord already holds the deposit (no deposit obligation). | [optional] [default to false]
**dueDay** | **int** |  | [optional] [default to 15]
**noticeMonths** | **int** | Default: the portfolio rules of the place, else 3. | [optional] 
**payeeIban** | **String** |  | 
**payeeName** | **String** |  | 
**propertyAddress** | **String** |  | 
**ruianId** | **int** | RÚIAN address of the flat (where the lease is in the portfolio). | [optional] 
**unitLabel** | **String** |  | [optional] 
**cutoverOn** | [**DateTime**](DateTime.md) | Payments are tracked from this day (default: the first day of next month). | [optional] 
**variableSymbol** | **String** | The tenants' existing variable symbol (leading zeros are dropped). | [optional] 
**parties** | [**List<LeaseImportPartyInput>**](LeaseImportPartyInput.md) |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


