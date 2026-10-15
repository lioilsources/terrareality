import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/search/listing_map.dart';
import 'package:terrareality/src/search/search_repository.dart';

import 'fakes.dart';

Future<FakeSearch> _pump(WidgetTester tester, FakeMap map) async {
  final repo = FakeSearch();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      searchRepositoryProvider.overrideWithValue(repo),
      listingMapProvider.overrideWithValue(map),
    ],
    child: TerraApp(locale: const Locale('cs'), router: createRouter()),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('search lists cards with the promoted label and applies filters', (tester) async {
    final repo = await _pump(tester, FakeMap());
    expect(find.text('2 inzeráty'), findsOneWidget);
    expect(find.text('Byt 3+kk Dejvice'), findsOneWidget);
    expect(find.text('Topováno'), findsOneWidget);
    expect(find.byKey(const Key('promoted-l1')), findsOneWidget);
    expect(find.byKey(const Key('promoted-l2')), findsNothing);

    await tester.tap(find.byKey(const Key('open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Byt'));
    await tester.tap(find.widgetWithText(FilterChip, '2+kk'));
    await tester.ensureVisible(find.byKey(const Key('rent-min')));
    await tester.enterText(find.byKey(const Key('rent-min')), '10000');
    await tester.enterText(find.byKey(const Key('rent-max')), '20000');
    await tester.ensureVisible(find.byKey(const Key('apply-filters')));
    await tester.tap(find.byKey(const Key('apply-filters')));
    await tester.pumpAndSettle();

    final q = repo.queries.last;
    expect(q.kinds, [UnitKind.apartment]);
    expect(q.layouts, ['2+kk']);
    expect(q.rentMin, 1000000); // minor units
    expect(q.rentMax, 2000000);
  });

  testWidgets('the map shows points, narrows to its area and opens a listing', (tester) async {
    final map = FakeMap();
    final repo = await _pump(tester, map);
    await tester.tap(find.byKey(const Key('toggle-map')));
    await tester.pumpAndSettle();
    expect(map.markers.map((m) => m.id), ['l1', 'l2']);

    await tester.tap(find.byKey(const Key('move-map')));
    await tester.pumpAndSettle();
    expect(repo.queries.last.bbox, [14.3, 50.0, 14.5, 50.1]);
    expect(find.text('Oblast mapy'), findsOneWidget);

    await tester.tap(find.byKey(const Key('marker-l1')));
    await tester.pumpAndSettle();
    expect(find.text('Inzerát'), findsOneWidget);
    expect(find.text('Byt 3+kk Dejvice'), findsOneWidget);
  });

  testWidgets('falls back to the list when the map style cannot load', (tester) async {
    await _pump(tester, FakeMap(fail: true));
    await tester.tap(find.byKey(const Key('toggle-map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-unavailable')), findsOneWidget);
    expect(find.text('Byt 3+kk Dejvice'), findsOneWidget);
    expect(find.byKey(const Key('toggle-map')), findsNothing);
  });
}
