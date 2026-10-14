# terra_api.model.ChatResponse

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**query** | [**SearchQuery**](SearchQuery.md) |  | 
**place** | [**Place**](Place.md) |  | [optional] 
**reply** | **String** |  | 
**model** | **String** | LLM route or \"rules\" for the offline parser. | 
**degraded** | **bool** | The LLM was unavailable and rules were used. | 
**result** | [**SearchResult**](SearchResult.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


