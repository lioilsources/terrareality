import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../api/api_provider.dart';

/// Whether card payment is offered for a share, and the link to reuse.
class CardPayment {
  const CardPayment({this.link});

  /// The latest valid link; null when none exists yet (created on tap).
  final PaymentLink? link;
}

/// Card payment links in the landlord's own Revolut merchant account
/// (money goes landlord-direct, ADR 0002). Loading a screen only reads;
/// a link (a real merchant order) is created only when the tenant taps pay.
abstract class PaymentsRepository {
  /// Null when card payment is not available (401/403).
  Future<CardPayment?> cardPayment(String shareId);

  /// Creates a link. Throws [ApiException] (409: not connected or paid).
  Future<PaymentLink> createLink(String shareId);
}

class ApiPaymentsRepository implements PaymentsRepository {
  ApiPaymentsRepository(this.api);

  final BillingApi api;

  @override
  Future<CardPayment?> cardPayment(String shareId) async {
    try {
      return CardPayment(link: await api.getPaymentLink(shareId));
    } on ApiException catch (e) {
      if (e.code == 404) return const CardPayment();
      if (e.code == 401 || e.code == 403) return null;
      rethrow;
    }
  }

  @override
  Future<PaymentLink> createLink(String shareId) async => (await api.createPaymentLink(shareId))!;
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => ApiPaymentsRepository(BillingApi(ref.watch(apiClientProvider))),
);

final cardPaymentProvider = FutureProvider.autoDispose.family<CardPayment?, String>(
  (ref, shareId) => ref.watch(paymentsRepositoryProvider).cardPayment(shareId),
);
