# terra_api.model.LeaseParty

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**role** | **String** |  | 
**name** | **String** |  | 
**email** | **String** | Shown to the landlord side for every party; a tenant-side caller sees only their own and the landlord's. | [optional] 
**shareBps** | **int** |  | 
**position** | **int** | Specific symbol of this party's payments. | 
**me** | **bool** |  | 
**signedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**debt** | **int** | Due and unpaid amount today. | [optional] 
**hasAccount** | **bool** | Linked to a user account (an imported lease's tenant gets reminders only then). | 
**invitedAt** | [**DateTime**](DateTime.md) | Landlord side: when a tenant of an imported lease was invited to the portal. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


