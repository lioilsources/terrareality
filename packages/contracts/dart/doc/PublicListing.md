# terra_api.model.PublicListing

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**prescreen** | [**List<PrescreenQuestion>**](PrescreenQuestion.md) | Questions to answer when contacting the landlord. | [default to const []]
**title** | [**I18nText**](I18nText.md) |  | 
**description** | [**I18nText**](I18nText.md) |  | 
**rentAmount** | **int** |  | 
**depositAmount** | **int** |  | [optional] 
**utilitiesAmount** | **int** |  | [optional] 
**currency** | **String** |  | 
**availableFrom** | [**DateTime**](DateTime.md) |  | [optional] 
**minTermMonths** | **int** |  | [optional] 
**attributes** | [**Map<String, Object>**](Object.md) |  | [default to const {}]
**unit** | [**PublicListingUnit**](PublicListingUnit.md) |  | 
**location** | [**PublicListingLocation**](PublicListingLocation.md) |  | 
**areaNames** | **List<String>** | From region to neighbourhood. | [default to const []]
**photos** | [**List<PhotoVariants>**](PhotoVariants.md) |  | [default to const []]
**publishedAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


