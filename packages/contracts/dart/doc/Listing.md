# terra_api.model.Listing

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orgId** | **String** |  | 
**prescreen** | [**List<PrescreenQuestion>**](PrescreenQuestion.md) |  | [default to const []]
**status** | [**ListingStatus**](ListingStatus.md) |  | 
**title** | [**I18nText**](I18nText.md) |  | 
**description** | [**I18nText**](I18nText.md) |  | 
**rentAmount** | **int** |  | [optional] 
**depositAmount** | **int** |  | [optional] 
**utilitiesAmount** | **int** |  | [optional] 
**currency** | **String** |  | 
**availableFrom** | [**DateTime**](DateTime.md) |  | [optional] 
**minTermMonths** | **int** |  | [optional] 
**attributes** | [**Map<String, Object>**](Object.md) |  | [default to const {}]
**locationPrecision** | **String** |  | 
**publishedVersion** | **int** |  | [optional] 
**publishedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**pendingReview** | **bool** |  | 
**unit** | [**ListingUnit**](ListingUnit.md) |  | 
**propertyId** | **String** |  | 
**address** | [**ListingAddress**](ListingAddress.md) |  | 
**media** | [**List<Media>**](Media.md) |  | [default to const []]
**suggestions** | [**List<Suggestion>**](Suggestion.md) |  | [default to const []]
**versions** | [**List<ListingVersionInfo>**](ListingVersionInfo.md) |  | [default to const []]
**depositMaxMonths** | **int** | Jurisdiction cap for the deposit in monthly rents. | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


