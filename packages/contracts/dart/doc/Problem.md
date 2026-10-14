# terra_api.model.Problem

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**type** | **String** |  | 
**title** | **String** |  | 
**status** | **int** |  | 
**detail** | **String** |  | [optional] 
**instance** | **String** |  | [optional] 
**code** | **String** | Stable machine-readable error code for client-side translation, e.g. invalid_credentials. | [optional] 
**errors** | [**List<FieldError>**](FieldError.md) | Field errors (code invalid_fields). | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


