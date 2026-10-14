# terra_api.model.RoommateProfile

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**active** | **bool** |  | 
**adminPath** | **String** | Admin unit path (from /v1/areas); empty = anywhere. | [optional] 
**areaLabel** | **String** |  | [optional] 
**budgetMax** | **int** | Monthly budget in minor units (CZK). | 
**moveIn** | [**DateTime**](DateTime.md) |  | [optional] 
**about** | **String** |  | [optional] 
**lifestyle** | **List<String>** |  | [default to const []]
**hasRoom** | **bool** | Offers a room in their own flat. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


