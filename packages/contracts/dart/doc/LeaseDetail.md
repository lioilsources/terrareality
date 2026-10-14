# terra_api.model.LeaseDetail

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**lease** | [**LeaseSummary**](LeaseSummary.md) |  | 
**landlordView** | **bool** |  | 
**payeeIban** | **String** |  | 
**payeeName** | **String** |  | 
**dueDay** | **int** |  | 
**noticeMonths** | **int** |  | 
**depositAmount** | **int** |  | 
**servicesAmount** | **int** |  | 
**clauses** | **List<String>** |  | [default to const []]
**changeRequest** | **String** |  | [optional] 
**parties** | [**List<LeaseParty>**](LeaseParty.md) |  | [default to const []]
**documents** | [**List<LeaseDocument>**](LeaseDocument.md) |  | [default to const []]
**totalDebt** | **int** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


