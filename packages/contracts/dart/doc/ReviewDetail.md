# terra_api.model.ReviewDetail

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**item** | [**ReviewItem**](ReviewItem.md) |  | 
**snapshot** | [**Map<String, Object>**](Object.md) |  | [default to const {}]
**photos** | [**List<PhotoVariants>**](PhotoVariants.md) |  | [default to const []]
**privacyFlags** | [**List<PrivacyFlag>**](PrivacyFlag.md) | Submitted photos whose privacy blur suggestion was not applied (the owner kept the photo or has not decided); staff must look at them. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


