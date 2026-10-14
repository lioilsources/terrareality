# terra_api.model.Media

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**status** | **String** |  | 
**rejectionReason** | **String** |  | [optional] 
**filename** | **String** |  | 
**contentType** | **String** |  | 
**width** | **int** |  | [optional] 
**height** | **int** |  | [optional] 
**position** | **int** |  | 
**caption** | [**I18nText**](I18nText.md) |  | 
**urls** | **Map<String, String>** | Signed imgproxy URLs by variant (thumb 400px, medium 1024px, large 1920px). | [default to const {}]
**roomType** | **String** |  | [optional] 
**tags** | **List<String>** |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


