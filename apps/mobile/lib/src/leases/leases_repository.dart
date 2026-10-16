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

/// The result of a signature: done, or continue at the provider.
class SignOutcome {
  const SignOutcome({required this.signed, this.redirect});

  final bool signed;

  /// The provider's page (https only) where the signature continues.
  final Uri? redirect;
}

/// Leases for the tenant screens.
abstract class LeasesRepository {
  Future<List<LeaseSummary>> mine();
  Future<LeaseView> lease(String id);

  /// Signs with [provider], one of the lease detail's `sign_providers`.
  Future<SignOutcome> sign(String id, SignProviderIdEnum provider);
}

/// Only https pages leave the app (payment and signature providers).
Uri? safeExternalUrl(String? raw) {
  final u = Uri.tryParse(raw ?? '');
  if (u == null || u.scheme != 'https' || u.host.isEmpty) return null;
  return u;
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
  Future<SignOutcome> sign(String id, SignProviderIdEnum provider) async {
    final req = SignLeaseRequestProviderEnum.fromJson(provider.value);
    // A provider this client build does not know cannot be requested.
    if (req == null) throw ApiException(422, '{"code":"invalid_provider","status":422,"title":"Unprocessable Entity"}');
    final res = await api.signLease(id, SignLeaseRequest(provider: req));
    return SignOutcome(signed: res?.signed ?? false, redirect: safeExternalUrl(res?.redirectUrl));
  }
}

final leasesRepositoryProvider = Provider<LeasesRepository>(
  (ref) => ApiLeasesRepository(LeasingApi(ref.watch(apiClientProvider))),
);
