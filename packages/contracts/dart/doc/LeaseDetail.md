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
**depositHeld** | **bool** | Imported lease: the landlord collected the deposit before the cutover (not scheduled). | 
**contractScanUrl** | **String** | Imported lease: short-lived download link of the paper contract's scan. | [optional] 
**clauses** | **List<String>** |  | [default to const []]
**changeRequest** | **String** |  | [optional] 
**parties** | [**List<LeaseParty>**](LeaseParty.md) |  | [default to const []]
**documents** | [**List<LeaseDocument>**](LeaseDocument.md) |  | [default to const []]
**totalDebt** | **int** |  | 
**signProviders** | [**List<SignProvider>**](SignProvider.md) | Signature methods enabled on this server, in order of preference. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


