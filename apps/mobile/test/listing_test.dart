import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/search/listing_map.dart';
import 'package:terrareality/src/search/listing_screen.dart';
import 'package:terrareality/src/search/search_repository.dart';

import 'fakes.dart';

Future<FakeSearch> _pump(WidgetTester tester, {FakeSearch? repo}) async {
  final r = repo ?? FakeSearch();
  final router = GoRouter(initialLocation: '/inzerat/l1', routes: [
    GoRoute(path: '/inzerat/:id', builder: (_, s) => ListingScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/zpravy/:id', builder: (_, s) => Text('thread ${s.pathParameters['id']}')),
    GoRoute(path: '/zadosti/:id', builder: (_, s) => Text('application ${s.pathParameters['id']}')),
    GoRoute(path: '/login', builder: (_, _) => const Text('login')),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      searchRepositoryProvider.overrideWithValue(r),
      listingMapProvider.overrideWithValue(FakeMap()),
    ],
    child: TerraApp(locale: const Locale('cs'), router: router),
  ));
  await tester.pumpAndSettle();
  return r;
}

void main() {
  testWidgets('listing detail shows rent, parameters and the map pin', (tester) async {
    await _pump(tester);
    expect(find.text('Byt 3+kk Dejvice'), findsOneWidget);
    expect(find.byKey(const Key('rent')), findsOneWidget);
    expect(find.text('Kauce'), findsOneWidget);
    expect(find.text('12 měsíců'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('marker-l1')), 200, scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('marker-l1')), findsOneWidget);
    expect(find.textContaining('Poloha je přibližná'), findsOneWidget);
  });

  testWidgets('message the landlord opens the new conversation', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.byKey(const Key('action-chat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-send')));
    await tester.pumpAndSettle();
    expect(repo.chats, ['Dobrý den, mám zájem o tento inzerát.']);
    expect(find.text('thread c9'), findsOneWidget);
  });

  testWidgets('request a viewing creates an application and opens its slots', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.byKey(const Key('action-viewing')));
    await tester.pumpAndSettle();
    expect(repo.applied, ['Dobrý den, rád bych se přišel podívat.']);
    expect(find.text('application a1'), findsOneWidget);
  });

  testWidgets('apply reuses an existing application', (tester) async {
    final repo = await _pump(tester, repo: FakeSearch()..existingApplication = 'a7');
    await tester.tap(find.byKey(const Key('action-apply')));
    await tester.pumpAndSettle();
    expect(repo.applied, isEmpty);
    expect(find.text('application a7'), findsOneWidget);
  });

  testWidgets('apply asks for the household and sends the application', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.byKey(const Key('action-apply')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('household')), '2');
    await tester.tap(find.byKey(const Key('contact-send')));
    await tester.pumpAndSettle();
    expect(repo.applied, [null]);
    expect(find.text('application a1'), findsOneWidget);
  });

  testWidgets('a signed-out seeker is sent to the login', (tester) async {
    await _pump(tester, repo: FakeSearch()..failWith = ApiException(401, 'unauthorized'));
    await tester.tap(find.byKey(const Key('action-chat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-send')));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });
}
