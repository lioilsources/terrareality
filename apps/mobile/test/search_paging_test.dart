import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/search/listing_map.dart';
import 'package:terrareality/src/search/search_repository.dart';

import 'auth_fakes.dart' show offline;
import 'fakes.dart';

/// [total] listings served by offset/limit like POST /v1/search (limit > 100 → 24).
class PagedSearch extends FakeSearch {
  PagedSearch(this.totalCount);

  final int totalCount;
  bool failNext = false;

  @override
  Future<SearchResult> search(SearchQuery q) async {
    queries.add(q);
    if (failNext) {
      failNext = false;
      throw offline();
    }
    final limit = (q.limit ?? 24) > 100 ? 24 : (q.limit ?? 24);
    final offset = q.offset ?? 0;
    final end = (offset + limit).clamp(0, totalCount);
    return SearchResult(
      total: totalCount,
      rentMin: 0,
      rentMax: 0,
      items: [for (var i = offset; i < end; i++) card('l$i', 'Byt $i')],
    );
  }
}

void main() {
  test('load more pages by offset past 100 results and stops at the total', () async {
    final repo = PagedSearch(130);
    final c = ProviderContainer(overrides: [searchRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final sub = c.listen(searchResultProvider, (_, _) {});
    addTearDown(sub.close);

    var page = await c.read(searchResultProvider.future);
    expect(page.items, hasLength(30));
    final counts = [page.items.length];
    while (page.hasMore) {
      await c.read(searchResultProvider.notifier).more();
      page = c.read(searchResultProvider).value!;
      counts.add(page.items.length);
    }
    expect(counts, [30, 60, 90, 120, 130]); // never shrinks
    expect(page.items.map((x) => x.id).toSet(), hasLength(130)); // results 101+ arrive, no duplicates
    expect(repo.queries.map((q) => q.offset), [0, 30, 60, 90, 120]);
    expect(repo.queries.every((q) => q.limit! <= 100), isTrue);
  });

  test('changing the filters starts again from the first page', () async {
    final repo = PagedSearch(130);
    final c = ProviderContainer(overrides: [searchRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final sub = c.listen(searchResultProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(searchResultProvider.future);
    await c.read(searchResultProvider.notifier).more();
    c.read(searchFiltersProvider.notifier).set(const SearchFilters(layouts: {'2+kk'}));
    final page = await c.read(searchResultProvider.future);
    expect(page.items, hasLength(30));
    expect(repo.queries.last.offset, 0);
    expect(repo.queries.last.layouts, ['2+kk']);
  });

  test('a failed page keeps the results and can be retried', () async {
    final repo = PagedSearch(70);
    final c = ProviderContainer(overrides: [searchRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final sub = c.listen(searchResultProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(searchResultProvider.future);
    repo.failNext = true;
    await c.read(searchResultProvider.notifier).more();
    var page = c.read(searchResultProvider).value!;
    expect(page.items, hasLength(30));
    expect(page.moreError, isNotNull);
    await c.read(searchResultProvider.notifier).more();
    page = c.read(searchResultProvider).value!;
    expect(page.items, hasLength(60));
    expect(page.moreError, isNull);
  });

  testWidgets('the button disappears once everything is loaded', (tester) async {
    final repo = PagedSearch(35);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        searchRepositoryProvider.overrideWithValue(repo),
        listingMapProvider.overrideWithValue(FakeMap()),
      ],
      child: TerraApp(locale: const Locale('cs'), router: createRouter()),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('load-more')), 500);
    await tester.tap(find.byKey(const Key('load-more')));
    await tester.pumpAndSettle();
    expect(repo.queries.last.offset, 30);
    expect(find.byKey(const Key('load-more')), findsNothing);
    await tester.scrollUntilVisible(find.text('Byt 34'), 500);
    expect(find.text('Byt 34'), findsOneWidget);
  });

  testWidgets('rent fields accept digits only', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        searchRepositoryProvider.overrideWithValue(FakeSearch()),
        listingMapProvider.overrideWithValue(FakeMap()),
      ],
      child: TerraApp(locale: const Locale('cs'), router: createRouter()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-filters')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('rent-min')));
    await tester.enterText(find.byKey(const Key('rent-min')), '15 000 Kč');
    expect(tester.widget<TextField>(find.byKey(const Key('rent-min'))).controller!.text, '15000');
  });
}
