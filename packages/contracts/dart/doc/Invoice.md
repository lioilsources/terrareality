# terra_api.model.Invoice

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**number** | **String** | TR-YYYY-000001 | 
**orderId** | **String** |  | 
**issuedOn** | [**DateTime**](DateTime.md) |  | 
**taxableSupplyOn** | [**DateTime**](DateTime.md) | Datum uskutečnění zdanitelného plnění. | 
**netAmount** | **int** |  | 
**vatAmount** | **int** |  | 
**grossAmount** | **int** |  | 
**currency** | **String** |  | 
**vatRateBp** | **int** |  | 
**sentAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


