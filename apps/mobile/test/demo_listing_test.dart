import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/l10n/gen/app_localizations.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/common/api_error.dart';
import 'package:terrareality/src/search/listing_map.dart';
import 'package:terrareality/src/search/listing_screen.dart';
import 'package:terrareality/src/search/search_repository.dart';
import 'package:terrareality/src/search/search_screen.dart';

import 'fakes.dart';

const _badgeCs = 'Ukázkový inzerát – nelze pronajmout';

Future<void> _pumpCard(WidgetTester tester, ListingCard c, {Locale locale = const Locale('cs')}) async {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => Scaffold(body: ListView(children: [ListingCardTile(card: c)]))),
  ]);
  await tester.pumpWidget(ProviderScope(child: TerraApp(locale: locale, router: router)));
  await tester.pumpAndSettle();
}

Future<void> _pumpDetail(WidgetTester tester, FakeSearch repo) async {
  final router = GoRouter(initialLocation: '/inzerat/l1', routes: [
    GoRoute(path: '/inzerat/:id', builder: (_, s) => ListingScreen(id: s.pathParameters['id']!)),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      searchRepositoryProvider.overrideWithValue(repo),
      listingMapProvider.overrideWithValue(FakeMap()),
    ],
    child: TerraApp(locale: const Locale('cs'), router: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a demo card shows the demo badge', (tester) async {
    await _pumpCard(tester, card('l1', 'Byt 3+kk Dejvice', isDemo: true));
    expect(find.byKey(const Key('demo-l1')), findsOneWidget);
    expect(find.text(_badgeCs), findsOneWidget);
  });

  testWidgets('a regular card has no demo badge', (tester) async {
    await _pumpCard(tester, card('l1', 'Byt 3+kk Dejvice'));
    expect(find.byKey(const Key('demo-l1')), findsNothing);
    expect(find.text(_badgeCs), findsNothing);
  });

  testWidgets('the demo badge is translated', (tester) async {
    await _pumpCard(tester, card('l1', 'Byt 3+kk Dejvice', isDemo: true), locale: const Locale('en'));
    expect(find.text('Demo listing – not available to rent'), findsOneWidget);
  });

  testWidgets('a demo listing detail explains itself and offers no actions', (tester) async {
    await _pumpDetail(tester, FakeSearch()..demo = true);
    expect(find.byKey(const Key('demo-banner')), findsOneWidget);
    expect(find.text(_badgeCs), findsOneWidget);
    expect(find.textContaining('uzavřenou betu'), findsOneWidget);
    expect(find.byKey(const Key('action-chat')), findsNothing);
    expect(find.byKey(const Key('action-viewing')), findsNothing);
    expect(find.byKey(const Key('action-apply')), findsNothing);
  });

  testWidgets('a regular listing detail keeps its actions', (tester) async {
    await _pumpDetail(tester, FakeSearch());
    expect(find.byKey(const Key('demo-banner')), findsNothing);
    expect(find.byKey(const Key('action-chat')), findsOneWidget);
    expect(find.byKey(const Key('action-viewing')), findsOneWidget);
    expect(find.byKey(const Key('action-apply')), findsOneWidget);
  });

  test('the demo_listing problem code has its own message', () async {
    final t = await AppLocalizations.delegate.load(const Locale('cs'));
    final e = ApiException(409, '{"code":"demo_listing","title":"Demo listing"}');
    expect(errorMessage(t, e), t.errorDemoListing);
  });
}
