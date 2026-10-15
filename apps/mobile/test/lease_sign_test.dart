import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/leases/leases_repository.dart';
import 'package:terrareality/src/leases/payments_repository.dart';
import 'package:terrareality/src/platform/url_opener.dart';

import 'leases_test.dart' show FakeRepo, NoCardPayments;

class _Opener implements UrlOpener {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

Future<_Opener> _pump(WidgetTester tester, FakeRepo repo) async {
  final opener = _Opener();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      leasesRepositoryProvider.overrideWithValue(repo),
      paymentsRepositoryProvider.overrideWithValue(NoCardPayments()),
      urlOpenerProvider.overrideWithValue(opener),
    ],
    child: TerraApp(locale: const Locale('cs'), router: createRouter(initialLocation: '/smlouvy/l1')),
  ));
  await tester.pumpAndSettle();
  return opener;
}

Future<void> _signAndConfirm(WidgetTester tester, {bool confirm = true}) async {
  await tester.tap(find.byKey(const Key('sign-lease')));
  await tester.pumpAndSettle();
  await tester.tap(confirm ? find.byKey(const Key('confirm-sign')) : find.text('Zrušit'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cancelling the confirmation signs nothing', (tester) async {
    final repo = FakeRepo();
    await _pump(tester, repo);
    await _signAndConfirm(tester, confirm: false);
    expect(repo.signCalls, 0);
    expect(find.byKey(const Key('sign-lease')), findsOneWidget);
  });

  testWidgets('an unavailable signature provider gets its own message, no crash', (tester) async {
    final repo = FakeRepo()
      ..signError = ApiException(400, '{"code":"invalid_provider","status":400,"title":"Bad Request"}');
    await _pump(tester, repo);
    await _signAndConfirm(tester);
    expect(repo.signCalls, 1);
    expect(find.text('Podepisování teď není dostupné. Zkuste to později nebo na webu.'), findsOneWidget);
    expect(repo.signed, isFalse);
  });

  testWidgets('a server error while signing is shown', (tester) async {
    final repo = FakeRepo()..signError = ApiException(500, 'boom');
    await _pump(tester, repo);
    await _signAndConfirm(tester);
    expect(find.text('Něco se pokazilo. Zkuste to prosím znovu.'), findsOneWidget);
  });

  testWidgets('a provider redirect opens in the browser', (tester) async {
    final repo = FakeRepo()..redirect = Uri.parse('https://sign.bankid.cz/session/1');
    final opener = await _pump(tester, repo);
    await _signAndConfirm(tester);
    expect(opener.opened, [Uri.parse('https://sign.bankid.cz/session/1')]);
    expect(find.textContaining('Podpis dokončete u poskytovatele'), findsOneWidget);
  });

  test('only https URLs leave the app', () {
    expect(safeExternalUrl('https://checkout.revolut.com/pay/1'), isNotNull);
    expect(safeExternalUrl('http://checkout.revolut.com/pay/1'), isNull);
    expect(safeExternalUrl('javascript:alert(1)'), isNull);
    expect(safeExternalUrl('intent://x#Intent;end'), isNull);
    expect(safeExternalUrl('https://'), isNull);
    expect(safeExternalUrl(null), isNull);
  });
}
