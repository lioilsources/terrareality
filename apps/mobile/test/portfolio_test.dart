import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/portfolio/portfolio_repository.dart';
import 'package:terrareality/src/portfolio/portfolio_screen.dart';

PortfolioCity _city(String name, int risk, RiskBand band, double share, int debt) => PortfolioCity(
      path: 'cz.x.${name.toLowerCase()}',
      name: name,
      region: 'Kraj',
      leases: 1,
      vacant: 0,
      monthly: 2000000,
      expected: 2000000,
      received: debt > 0 ? 0 : 2000000,
      debt: debt,
      weightedRisk: risk,
      band: band,
      share: share,
    );

class FakePortfolio implements PortfolioRepository {
  @override
  Future<List<PortfolioOrg>> orgs() async => [PortfolioOrg('o1', 'Rodinné investice')];

  @override
  Future<PortfolioDashboard> dashboard(String orgId) async => PortfolioDashboard(
        role: Role.investor,
        currency: 'CZK',
        leases: 3,
        vacant: 0,
        monthly: 6000000,
        debt: 4200000,
        weightedRisk: 29,
        band: RiskBand.medium,
        period: '2026-10',
        expected: 6000000,
        received: 4000000,
        cities: [
          _city('Praha', 11, RiskBand.low, 0.42, 0),
          _city('Brno', 53, RiskBand.high, 0.32, 4200000),
          _city('Ostrava', 30, RiskBand.medium, 0.26, 0),
        ],
        concentration: PortfolioDashboardConcentration(hhi: 0.35),
        attention: [
          PortfolioAttention(kind: PortfolioAttentionKindEnum.escalation, severity: 3, label: 'Kounicova 20', city: 'Brno',
              amount: 4200000),
        ],
        trend: [],
      );
}

void main() {
  testWidgets('portfolio shows municipalities with risk and attention', (tester) async {
    final router = GoRouter(initialLocation: '/portfolio', routes: [
      GoRoute(path: '/portfolio', builder: (_, _) => const PortfolioScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [portfolioRepositoryProvider.overrideWithValue(FakePortfolio())],
      child: TerraApp(locale: const Locale('cs'), router: router),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('29 · střední'), findsOneWidget);
    expect(find.byKey(const ValueKey('city-Praha')), findsOneWidget);
    expect(find.text('53 · vysoké'), findsOneWidget);
    expect(find.text('Eskalace platby'), findsOneWidget);
    expect(find.textContaining('Kounicova 20'), findsOneWidget);
  });
}
