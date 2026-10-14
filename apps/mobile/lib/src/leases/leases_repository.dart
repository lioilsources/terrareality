import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../api/api_provider.dart';

/// A lease with its payment schedule and audit chain status.
class LeaseView {
  LeaseView(this.detail, this.shares, this.chainValid);

  final LeaseDetail detail;
  final List<ObligationShare> shares;
  final bool chainValid;
}

/// Leases for the tenant screens.
abstract class LeasesRepository {
  Future<List<LeaseSummary>> mine();
  Future<LeaseView> lease(String id);
  Future<void> sign(String id);
}

class ApiLeasesRepository implements LeasesRepository {
  ApiLeasesRepository(this.api);

  final LeasingApi api;

  @override
  Future<List<LeaseSummary>> mine() async => await api.listMyLeases() ?? [];

  @override
  Future<LeaseView> lease(String id) async {
    final detail = await api.getLease(id);
    final shares = await api.listLeaseObligations(id);
    final events = await api.getLeaseEvents(id);
    return LeaseView(detail!, shares ?? [], events?.valid ?? false);
  }

  @override
  Future<void> sign(String id) => api.signLease(id, SignLeaseRequest(provider: SignLeaseRequestProviderEnum.mock));
}

final leasesRepositoryProvider = Provider<LeasesRepository>(
  (ref) => ApiLeasesRepository(LeasingApi(ref.watch(apiClientProvider))),
);
