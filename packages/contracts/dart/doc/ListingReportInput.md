# terra_api.model.ListingReportInput

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**reason** | [**ListingReportReason**](ListingReportReason.md) |  | 
**explanation** | **String** | Why the reporter considers the listing illegal or in breach of the terms (DSA art. 16(2)(a)). | 
**email** | **String** | Required for anonymous reporters; ignored when signed in (the account e-mail is used). | [optional] 
**name** | **String** | Optional reporter name (anonymous reporters). | [optional] 
**locale** | **String** | Language of the e-mails for anonymous reporters. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


