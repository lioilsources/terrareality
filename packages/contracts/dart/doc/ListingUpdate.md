# terra_api.model.ListingUpdate

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**title** | [**I18nText**](I18nText.md) |  | 
**description** | [**I18nText**](I18nText.md) |  | 
**rentAmount** | **int** | Minor units (haléře). | [optional] 
**depositAmount** | **int** |  | [optional] 
**utilitiesAmount** | **int** |  | [optional] 
**availableFrom** | [**DateTime**](DateTime.md) |  | [optional] 
**minTermMonths** | **int** |  | [optional] 
**attributes** | [**Map<String, Object>**](Object.md) |  | [default to const {}]
**locationPrecision** | **String** |  | 
**unitLabel** | **String** |  | [optional] 
**floor** | **int** |  | [optional] 
**floorArea** | **double** |  | [optional] 
**layout** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


