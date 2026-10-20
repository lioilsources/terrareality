import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/leases/leases_repository.dart';
import 'package:terrareality/src/leases/payments_repository.dart';
import 'package:terrareality/src/platform/url_opener.dart';

import 'leases_test.dart' show FakeRepo, NoCardPayments;

/// Answers every request with [answer] and records the JSON bodies.
class _Client extends ApiClient {
  _Client(this.answer) : super(basePath: 'http://api.test');

  final Map<String, dynamic> answer;
  final bodies = <Object?>[];

  @override
  Future<Response> invokeAPI(String path, String method, List<QueryParam> queryParams, Object? body,
      Map<String, String> headerParams, Map<String, String> formParams, String? contentType) async {
    bodies.add(jsonDecode(jsonEncode(body)));
    return Response(jsonEncode(answer), 200);
  }
}

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

  testWidgets('a single enabled method is used without a choice and labelled by its level', (tester) async {
    final repo = FakeRepo()
      ..providers = [SignProvider(id: SignProviderIdEnum.bankidSign, level: SignProviderLevelEnum.qualified)];
    await _pump(tester, repo);
    expect(find.byType(RadioListTile<SignProviderIdEnum>), findsNothing);
    expect(find.text('Způsob podpisu: kvalifikovaný elektronický podpis (Bank iD)'), findsOneWidget);
    await _signAndConfirm(tester);
    expect(repo.signedWith, [SignProviderIdEnum.bankidSign]);
  });

  testWidgets('several enabled methods are offered, the preferred one first', (tester) async {
    final repo = FakeRepo()
      ..providers = [
        SignProvider(id: SignProviderIdEnum.bankidSign, level: SignProviderLevelEnum.qualified),
        SignProvider(id: SignProviderIdEnum.mock, level: SignProviderLevelEnum.simple),
      ];
    await _pump(tester, repo);
    expect(find.text('Vyberte způsob podpisu'), findsOneWidget);
    expect(find.byType(RadioListTile<SignProviderIdEnum>), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('sign-provider-mock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-lease')));
    await tester.pumpAndSettle();
    // The confirmation names the chosen method.
    expect(find.textContaining('prostý elektronický podpis. Podpis je právně závazný.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-sign')));
    await tester.pumpAndSettle();
    expect(repo.signedWith, [SignProviderIdEnum.mock]);
  });

  testWidgets('the preferred method is used when the tenant does not choose', (tester) async {
    final repo = FakeRepo()
      ..providers = [
        SignProvider(id: SignProviderIdEnum.bankidSign, level: SignProviderLevelEnum.qualified),
        SignProvider(id: SignProviderIdEnum.mock, level: SignProviderLevelEnum.simple),
      ];
    await _pump(tester, repo);
    await _signAndConfirm(tester);
    expect(repo.signedWith, [SignProviderIdEnum.bankidSign]);
  });

  testWidgets('no enabled method: no sign button, a notice instead', (tester) async {
    final repo = FakeRepo()..providers = [];
    await _pump(tester, repo);
    expect(find.byKey(const Key('sign-lease')), findsNothing);
    expect(find.byKey(const Key('sign-unavailable')), findsOneWidget);
  });

  testWidgets('a document changed meanwhile: told to review, the lease reloads', (tester) async {
    final repo = FakeRepo()
      ..signError = ApiException(409, '{"code":"document_changed","status":409,"title":"Conflict"}');
    await _pump(tester, repo);
    final loads = repo.loads;
    await _signAndConfirm(tester);
    expect(find.text('Smlouva se mezitím změnila. Zkontrolujte novou verzi a podepište ji znovu.'), findsOneWidget);
    expect(repo.loads, greaterThan(loads));
    expect(repo.signed, isFalse);
  });

  testWidgets('a method disabled meanwhile (422 invalid_provider) reloads the lease', (tester) async {
    final repo = FakeRepo()
      ..signError = ApiException(422, '{"code":"invalid_provider","status":422,"title":"Unprocessable Entity"}');
    await _pump(tester, repo);
    final loads = repo.loads;
    await _signAndConfirm(tester);
    expect(find.text('Podepisování teď není dostupné. Zkuste to později nebo na webu.'), findsOneWidget);
    expect(repo.loads, greaterThan(loads));
  });

  test('the API repository sends the chosen method and drops a non-https redirect', () async {
    final client = _Client({'signed': false, 'redirect_url': 'http://sign.example/1'});
    final repo = ApiLeasesRepository(LeasingApi(client));
    final out = await repo.sign('l1', SignProviderIdEnum.bankidSign);
    expect(client.bodies.single, {'provider': 'bankid_sign'});
    expect(out.redirect, isNull);
    expect(out.signed, isFalse);

    final ok = await ApiLeasesRepository(LeasingApi(_Client({'signed': false, 'redirect_url': 'https://sign.bankid.cz/s/1'})))
        .sign('l1', SignProviderIdEnum.bankidSign);
    expect(ok.redirect, Uri.parse('https://sign.bankid.cz/s/1'));
  });

  test('the lease detail parses enabled methods and parties without an e-mail', () {
    final d = LeaseDetail.fromJson({
      'lease': {
        'id': 'l1', 'org_id': 'o1', 'code': 1, 'state': 'proposed', 'origin': 'platform', 'template': 'spolecny_najem',
        'property_address': 'Dejvická 12', 'starts_on': '2026-11-01', 'rent_amount': 2000000, 'currency': 'CZK',
        'created_at': '2026-10-14T10:00:00Z',
      },
      'landlord_view': false, 'payee_iban': 'CZ65', 'payee_name': 'Lucie', 'due_day': 15, 'notice_months': 3,
      'deposit_amount': 0, 'services_amount': 0, 'deposit_held': false, 'clauses': [], 'documents': [], 'total_debt': 0,
      'parties': [
        {'id': 'p1', 'role': 'co_tenant', 'name': 'Anna', 'email': 'anna@example.cz', 'share_bps': 5000, 'position': 1, 'me': true,
         'has_account': true},
        {'id': 'p2', 'role': 'co_tenant', 'name': 'Petr', 'share_bps': 5000, 'position': 2, 'me': false, 'has_account': false},
      ],
      'sign_providers': [
        {'id': 'bankid_sign', 'level': 'qualified'},
        {'id': 'mock', 'level': 'simple'},
      ],
    })!;
    expect(d.signProviders.map((p) => p.id), [SignProviderIdEnum.bankidSign, SignProviderIdEnum.mock]);
    expect(d.parties[1].email, isNull);
    expect(Member.fromJson({
          'user_id': 'u1', 'display_name': 'Iva', 'role': 'viewer', 'verification_level': 'email',
          'joined_at': '2026-10-01T10:00:00Z',
        })?.email, isNull);
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
