# terra_api.model.RentRollRow

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**kind** | **String** |  | 
**leaseId** | **String** |  | [optional] 
**unitId** | **String** |  | [optional] 
**code** | **int** |  | [optional] 
**state** | **String** |  | 
**municipality** | **String** |  | 
**municipalityPath** | **String** |  | 
**region** | **String** |  | 
**regionPath** | **String** |  | [optional] 
**address** | **String** |  | 
**unit** | **String** |  | 
**tenants** | **String** | Initials only for the investor role. | [optional] 
**rent** | **int** |  | [optional] 
**services** | **int** |  | [optional] 
**currency** | **String** |  | 
**dueDay** | **int** |  | [optional] 
**startsOn** | [**DateTime**](DateTime.md) |  | [optional] 
**endsOn** | [**DateTime**](DateTime.md) |  | [optional] 
**noticeOn** | [**DateTime**](DateTime.md) |  | [optional] 
**deposit** | **int** |  | [optional] 
**depositPaid** | **int** |  | [optional] 
**billed** | **int** | Receivables due by today (ledger). | [optional] 
**paid** | **int** | Payments booked by today (ledger). | [optional] 
**debt** | **int** | Receivable balance by today. | [optional] 
**riskScore** | **int** |  | [optional] 
**riskBand** | [**RiskBand**](RiskBand.md) |  | [optional] 
**groupIds** | **List<String>** |  | [default to const []]
**lat** | **num** |  | [optional] 
**lng** | **num** |  | [optional] 
**askingRent** | **int** |  | [optional] 
**listingStatus** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


