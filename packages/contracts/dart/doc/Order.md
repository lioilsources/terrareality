# terra_api.model.Order

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**listingId** | **String** |  | 
**listingTitle** | **String** | In the caller's locale. | 
**productCode** | **String** |  | 
**status** | [**OrderStatus**](OrderStatus.md) |  | 
**netAmount** | **int** |  | 
**vatAmount** | **int** |  | 
**grossAmount** | **int** |  | 
**currency** | **String** |  | 
**startsAt** | [**DateTime**](DateTime.md) |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**paidAt** | [**DateTime**](DateTime.md) |  | [optional] 
**invoiceId** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


