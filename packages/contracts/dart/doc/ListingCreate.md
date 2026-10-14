# terra_api.model.ListingCreate

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ruianId** | **int** |  | 
**unitKind** | [**UnitKind**](UnitKind.md) |  | 
**unitLabel** | **String** |  | [optional] 
**floor** | **int** |  | [optional] 
**floorArea** | **double** |  | [optional] 
**layout** | **String** |  | [optional] 
**parentUnitId** | **String** | Rooms only – an existing apartment at the same address. | [optional] 
**parentLayout** | **String** | Rooms only – layout of the apartment to create. | [optional] 
**parentFloorArea** | **double** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


