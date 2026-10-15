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

/// The signature method the app offers. Until the API lists the enabled
/// providers (contract change, see docs/05-review-implementation.md V-12),
/// the build picks it: `--dart-define=SIGN_PROVIDER=bankid_sign`; the
/// default is the platform's simple electronic signature (`mock`).
const signProvider = String.fromEnvironment('SIGN_PROVIDER', defaultValue: 'mock');

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
  Future<SignOutcome> sign(String id);
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
  Future<SignOutcome> sign(String id) async {
    final provider = SignLeaseRequestProviderEnum.fromJson(signProvider) ?? SignLeaseRequestProviderEnum.mock;
    final res = await api.signLease(id, SignLeaseRequest(provider: provider));
    return SignOutcome(signed: res?.signed ?? false, redirect: safeExternalUrl(res?.redirectUrl));
  }
}

final leasesRepositoryProvider = Provider<LeasesRepository>(
  (ref) => ApiLeasesRepository(LeasingApi(ref.watch(apiClientProvider))),
);
