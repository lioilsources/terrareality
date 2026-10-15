# terra_api.model.RiskFactor

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**key** | **String** |  | 
**group** | **String** |  | 
**weight** | **int** | Absent for tenants. | [optional] 
**value** | **num** |  | 
**points** | **num** | Contribution to the score; absent for tenants. | [optional] 
**known** | **bool** | false when there is no data (counted as 0). | 
**detail** | [**Map<String, Object>**](Object.md) |  | [optional] [default to const {}]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


