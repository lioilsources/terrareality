# terra_api.model.SearchResult

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**total** | **int** |  | 
**items** | [**List<ListingCard>**](ListingCard.md) |  | [default to const []]
**facets** | [**Map<String, List<FacetCount>>**](List.md) |  | [default to const {}]
**rentMin** | **int** |  | 
**rentMax** | **int** |  | 
**areas** | [**List<AreaAggregate>**](AreaAggregate.md) |  | [default to const []]
**points** | [**List<MapPoint>**](MapPoint.md) | Up to 2000 markers. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


