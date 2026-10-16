import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/leases/leases_repository.dart';
import 'package:terrareality/src/leases/payments_repository.dart';
import 'package:terrareality/src/platform/url_opener.dart';

import 'leases_test.dart' show FakeRepo;

PaymentLink _link(String shareId) => PaymentLink(
      id: 'pl1',
      shareId: shareId,
      provider: PaymentLinkProviderEnum.revolut,
      url: 'https://checkout.revolut.com/pay/abc',
      amount: 1200000,
      currency: 'CZK',
      status: PaymentLinkStatusEnum.created,
      createdAt: DateTime(2026, 10, 15),
    );

/// A BillingApi answering with fixed status codes; records calls.
class FakeBilling implements BillingApi {
  FakeBilling({this.getCode = 404, this.createCode = 201});

  final int getCode;
  final int createCode;
  final gets = <String>[];
  final creates = <String>[];

  @override
  Future<PaymentLink?> getPaymentLink(String shareId) async {
    gets.add(shareId);
    if (getCode == 200) return _link(shareId);
    throw ApiException(getCode, 'error');
  }

  @override
  Future<PaymentLink?> createPaymentLink(String shareId) async {
    creates.add(shareId);
    if (createCode == 201) return _link(shareId);
    throw ApiException(createCode, 'error');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordingOpener implements UrlOpener {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

Future<RecordingOpener> _pump(WidgetTester tester, FakeBilling billing) async {
  final leases = FakeRepo();
  await leases.sign('l1', SignProviderIdEnum.mock); // signed: the rent share s2 is open and has a SPAYD
  final opener = RecordingOpener();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      leasesRepositoryProvider.overrideWithValue(leases),
      paymentsRepositoryProvider.overrideWithValue(ApiPaymentsRepository(billing)),
      urlOpenerProvider.overrideWithValue(opener),
    ],
    child: TerraApp(locale: const Locale('cs'), router: createRouter(initialLocation: '/smlouvy/l1')),
  ));
  await tester.pumpAndSettle();
  return opener;
}

Future<void> _tapPay(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('revolut-s2')));
  await tester.tap(find.byKey(const Key('revolut-s2')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no link yet: the button shows, and the link is created only on tap', (tester) async {
    final billing = FakeBilling(getCode: 404);
    final opener = await _pump(tester, billing);
    expect(find.byKey(const Key('qr-s2')), findsOneWidget);
    expect(find.text('Zaplatit kartou (Revolut)'), findsOneWidget);
    expect(billing.gets, ['s2']);
    expect(billing.creates, isEmpty); // loading the lease never creates a merchant order

    await _tapPay(tester);
    expect(billing.creates, ['s2']);
    expect(opener.opened, [Uri.parse('https://checkout.revolut.com/pay/abc')]);
  });

  testWidgets('an existing link is reused without creating another', (tester) async {
    final billing = FakeBilling(getCode: 200);
    final opener = await _pump(tester, billing);
    await _tapPay(tester);
    expect(billing.creates, isEmpty);
    expect(opener.opened, hasLength(1));
  });

  testWidgets('a 409 on create shows a short message', (tester) async {
    final billing = FakeBilling(getCode: 404, createCode: 409);
    final opener = await _pump(tester, billing);
    await _tapPay(tester);
    expect(opener.opened, isEmpty);
    expect(find.byKey(const Key('revolut-message-s2')), findsOneWidget);
    expect(find.textContaining('nemá napojený Revolut'), findsOneWidget);
  });

  testWidgets('the card option is hidden when the API answers 403', (tester) async {
    final billing = FakeBilling(getCode: 403);
    await _pump(tester, billing);
    expect(find.byKey(const Key('qr-s2')), findsOneWidget);
    expect(find.byKey(const Key('revolut-s2')), findsNothing);
    expect(billing.creates, isEmpty);
  });
}
