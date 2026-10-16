# terra_api.model.ListingSummary

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**status** | [**ListingStatus**](ListingStatus.md) |  | 
**title** | [**I18nText**](I18nText.md) |  | 
**unitKind** | [**UnitKind**](UnitKind.md) |  | 
**unitLabel** | **String** |  | 
**addressLabel** | **String** |  | 
**rentAmount** | **int** |  | [optional] 
**currency** | **String** |  | 
**coverUrl** | **String** |  | [optional] 
**pendingReview** | **bool** |  | 
**publishedVersion** | **int** |  | [optional] 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**isDemo** | **bool** | Demo listing of the closed beta (terractl demo seed): shown with a prominent label, cannot be contacted, applied for or booked (problem code demo_listing). | [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


