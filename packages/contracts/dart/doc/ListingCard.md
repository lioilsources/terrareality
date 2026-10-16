# terra_api.model.ListingCard

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**unitKind** | [**UnitKind**](UnitKind.md) |  | 
**layout** | **String** |  | [optional] 
**rentAmount** | **int** |  | 
**currency** | **String** |  | 
**floorArea** | **double** |  | [optional] 
**title** | [**I18nText**](I18nText.md) |  | 
**city** | **String** |  | 
**cityPart** | **String** |  | [optional] 
**lat** | **double** |  | 
**lng** | **double** |  | 
**coverUrl** | **String** |  | [optional] 
**publishedAt** | [**DateTime**](DateTime.md) |  | 
**promoted** | **bool** | Paid top placement running now; the card shows a transparent \"Promoted\" label. | [default to false]
**highlighted** | **bool** | Paid visual highlight running now. | [default to false]
**isDemo** | **bool** | Demo listing of the closed beta (terractl demo seed): shown with a prominent label, cannot be contacted, applied for or booked (problem code demo_listing). | [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


