# terra_api.model.LeaseImportPartyInput

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  | 
**email** | **String** | Optional; nobody is contacted at import. | [optional] 
**role** | **String** |  | 
**shareBps** | **int** | Payment share in basis points; all zero = equal shares. | [optional] 
**openingBalance** | **int** | Owed at the cutover (minor units); 0 = nothing. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


