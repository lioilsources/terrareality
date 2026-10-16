# terra_api.model.SearchQuery

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**text** | **String** |  | [optional] 
**kinds** | [**List<UnitKind>**](UnitKind.md) |  | [optional] [default to const []]
**rentMin** | **int** | Minor units. | [optional] 
**rentMax** | **int** |  | [optional] 
**areaMin** | **double** |  | [optional] 
**areaMax** | **double** |  | [optional] 
**layouts** | **List<String>** |  | [optional] [default to const []]
**adminPath** | **String** |  | [optional] 
**bbox** | **List<double>** | west, south, east, north | [optional] [default to const []]
**attributes** | [**Map<String, AttrFilter>**](AttrFilter.md) |  | [optional] [default to const {}]
**sort** | **String** |  | [optional] 
**limit** | **int** |  | [optional] 
**offset** | **int** |  | [optional] 
**excludeDemo** | **bool** | Leave demo listings out (static site locality pages). | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


