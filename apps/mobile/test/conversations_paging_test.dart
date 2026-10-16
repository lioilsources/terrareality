import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/messaging/conversations_screen.dart';
import 'package:terrareality/src/messaging/messaging_repository.dart';

import 'auth_fakes.dart' show offline;
import 'messaging_test.dart' show FakeRepo;

Conversation conv(int i) => Conversation(
  id: 'c${(1000 - i).toString().padLeft(4, '0')}', // newest first: ids descend
  listingId: 'l1',
  orgId: 'o1',
  orgName: 'Pronajímatel $i',
  seekerId: 's1',
  seekerName: 'Tomáš',
  listingTitle: I18nText(cs: 'Byt $i', en: ''),
  role: ConversationRole.seeker,
  lastMessageAt: DateTime(2026, 10, 14),
  lastMessage: 'Zpráva $i',
  unread: 0,
  blocked: false,
  blockedByMe: false,
  createdAt: DateTime(2026, 10, 14),
);

/// [total] conversations served by `before`/`limit` like GET /v1/conversations.
class PagedInbox extends FakeRepo {
  PagedInbox(this.total);

  final int total;
  final befores = <String?>[];
  final limits = <int>[];
  bool failNext = false;

  late final all = [for (var i = 0; i < total; i++) conv(i)];

  @override
  Future<List<Conversation>> conversations({String? before, int limit = conversationsPageSize}) async {
    befores.add(before);
    limits.add(limit);
    if (failNext) {
      failNext = false;
      throw offline();
    }
    final start = before == null ? 0 : all.indexWhere((c) => c.id == before) + 1;
    return all.skip(start).take(limit).toList();
  }
}

void main() {
  test('the inbox pages by the last conversation id until a short page', () async {
    final repo = PagedInbox(120);
    final c = ProviderContainer(overrides: [messagingRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final sub = c.listen(conversationsProvider, (_, _) {});
    addTearDown(sub.close);

    var page = await c.read(conversationsProvider.future);
    final counts = [page.items.length];
    while (page.hasMore) {
      await c.read(conversationsProvider.notifier).more();
      page = c.read(conversationsProvider).value!;
      counts.add(page.items.length);
    }
    expect(counts, [50, 100, 120]);
    expect(repo.befores, [null, repo.all[49].id, repo.all[99].id]);
    expect(repo.limits.every((l) => l == 50), isTrue);
    expect(page.items.map((x) => x.id).toSet(), hasLength(120));
  });

  test('an exact multiple of the page size ends with an empty page', () async {
    final repo = PagedInbox(50);
    final c = ProviderContainer(overrides: [messagingRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final sub = c.listen(conversationsProvider, (_, _) {});
    addTearDown(sub.close);
    expect((await c.read(conversationsProvider.future)).hasMore, isTrue);
    await c.read(conversationsProvider.notifier).more();
    final page = c.read(conversationsProvider).value!;
    expect(page.hasMore, isFalse);
    expect(page.items, hasLength(50));
  });

  test('a conversation that moved to a later page is not listed twice', () async {
    final repo = PagedInbox(60);
    final c = ProviderContainer(overrides: [messagingRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final sub = c.listen(conversationsProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(conversationsProvider.future);
    // Meanwhile the first conversation went quiet and sorts after the cursor.
    repo.all.add(repo.all.removeAt(0));
    await c.read(conversationsProvider.notifier).more();
    final page = c.read(conversationsProvider).value!;
    expect(page.items.map((x) => x.id).toSet(), hasLength(page.items.length));
    expect(page.items, hasLength(60));
  });

  testWidgets('scrolling to the end loads more; a failed page shows the error view with retry', (tester) async {
    final repo = PagedInbox(70)..failNext = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [messagingRepositoryProvider.overrideWithValue(repo)],
      child: TerraApp(locale: const Locale('cs'), router: createRouter()..go('/zpravy')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Pronajímatel 0'), findsOneWidget);
    expect(repo.befores, [null]);

    repo.failNext = true;
    await tester.scrollUntilVisible(find.byKey(const Key('load-more-error')), 500,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(repo.befores, hasLength(2));
    expect(find.textContaining('připojení'), findsWidgets);
    expect(find.text('Pronajímatel 49'), findsOneWidget); // loaded items stay

    await tester.tap(find.byKey(const Key('error-retry')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pronajímatel 69'), 500, scrollable: find.byType(Scrollable).first);
    expect(find.text('Pronajímatel 69'), findsOneWidget);
    expect(find.byKey(const Key('load-more-error')), findsNothing);
    expect(find.byKey(const Key('load-more')), findsNothing); // a short page ends the list
    expect(repo.befores, hasLength(3));
  });
}
