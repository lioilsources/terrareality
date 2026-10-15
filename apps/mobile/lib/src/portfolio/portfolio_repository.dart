import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../api/api_provider.dart';

/// An organization whose portfolio the user may read.
class PortfolioOrg {
  PortfolioOrg(this.id, this.name);

  final String id;
  final String name;
}

/// The owner's portfolio across municipalities (M6b).
abstract class PortfolioRepository {
  Future<List<PortfolioOrg>> orgs();
  Future<PortfolioDashboard> dashboard(String orgId);
}

class ApiPortfolioRepository implements PortfolioRepository {
  ApiPortfolioRepository(this.client);

  final ApiClient client;

  @override
  Future<List<PortfolioOrg>> orgs() async {
    final me = await MeApi(client).getMe();
    return [
      for (final m in me?.organizations ?? <OrgMembership>[])
        if (m.role != Role.maintenance) PortfolioOrg(m.organization.id, m.organization.name),
    ];
  }

  @override
  Future<PortfolioDashboard> dashboard(String orgId) async => (await PortfolioApi(client).getPortfolio(orgId))!;
}

final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => ApiPortfolioRepository(ref.watch(apiClientProvider)),
);
