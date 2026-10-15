# terra_api.model.PortfolioDashboard

## Load the model package
```dart
import 'package:terra_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**role** | [**Role**](Role.md) |  | 
**currency** | **String** |  | 
**leases** | **int** |  | 
**vacant** | **int** |  | 
**monthly** | **int** |  | 
**debt** | **int** |  | 
**weightedRisk** | **int** |  | [optional] 
**band** | [**RiskBand**](RiskBand.md) |  | [optional] 
**period** | **String** | YYYY-MM of the current month. | 
**expected** | **int** |  | 
**received** | **int** |  | 
**cities** | [**List<PortfolioCity>**](PortfolioCity.md) |  | [default to const []]
**concentration** | [**PortfolioDashboardConcentration**](PortfolioDashboardConcentration.md) |  | 
**attention** | [**List<PortfolioAttention>**](PortfolioAttention.md) |  | [default to const []]
**trend** | [**List<PortfolioDashboardTrendInner>**](PortfolioDashboardTrendInner.md) |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


