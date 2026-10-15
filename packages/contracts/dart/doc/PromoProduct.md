# terra_api.model.PromoProduct

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**code** | **String** |  | 
**kind** | [**PromoProductKind**](PromoProductKind.md) |  | 
**durationDays** | **int** |  | 
**netAmount** | **int** | Net price in minor units. | 
**vatRateBp** | **int** | VAT rate in basis points (2100 = 21 %). | 
**vatAmount** | **int** |  | 
**grossAmount** | **int** |  | 
**currency** | **String** |  | 
**name** | [**I18nText**](I18nText.md) |  | 
**active** | **bool** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


