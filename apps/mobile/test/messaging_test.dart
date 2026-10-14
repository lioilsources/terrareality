import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/messaging/messaging_repository.dart';

const seeker = 'seeker-1';
const owner = 'owner-1';

Conversation _conv({int unread = 1}) => Conversation(
  id: 'c1',
  listingId: 'l1',
  orgId: 'o1',
  orgName: 'Lucie Pronajímatelka',
  seekerId: seeker,
  seekerName: 'Tomáš',
  listingTitle: I18nText(cs: 'Byt 2+kk Dejvice', en: ''),
  role: ConversationRole.seeker,
  lastMessageAt: DateTime(2026, 10, 14, 12),
  lastMessage: 'Pošlete zálohu předem',
  unread: unread,
  blocked: false,
  blockedByMe: false,
  createdAt: DateTime(2026, 10, 14, 10),
);

Message _msg(String id, String sender, String body, {List<MessageFlag> flags = const [], int minute = 0}) => Message(
  id: id,
  conversationId: 'c1',
  senderId: sender,
  kind: MessageKindEnum.text,
  body: body,
  flags: flags,
  removed: false,
  createdAt: DateTime(2026, 10, 14, 12, minute),
  attachments: [],
);

class FakeRepo implements MessagingRepository {
  final events$ = StreamController<RealtimeEvent>.broadcast();
  final sent = <String>[];
  int reads = 0;
  DateTime? peerReadAt;

  @override
  Future<List<Conversation>> conversations() async => [_conv()];

  @override
  Future<ConversationDetail> detail(String id) async =>
      ConversationDetail(conversation: _conv(), prescreen: [], peerReadAt: peerReadAt);

  @override
  Future<List<Message>> messages(String id) async => [
    _msg('m1', seeker, 'Dobrý den, volejte [•••]', flags: [MessageFlag.contactPhone]),
    _msg('m2', owner, 'Pošlete zálohu předem', flags: [MessageFlag.advancePayment], minute: 1),
  ];

  @override
  Future<Message> send(String id, String body) async {
    sent.add(body);
    return _msg('m-${sent.length}', seeker, body, minute: 5);
  }

  @override
  Future<void> markRead(String id) async => reads++;

  @override
  Future<void> report(String id, String reason, String note) async {}

  @override
  Stream<RealtimeEvent> events(String id) => events$.stream;
}

Future<FakeRepo> _pump(WidgetTester tester, String path) async {
  final repo = FakeRepo();
  final router = createRouter()..go(path);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [messagingRepositoryProvider.overrideWithValue(repo)],
      child: TerraApp(locale: const Locale('cs'), router: router),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('inbox lists conversations with the unread count', (tester) async {
    await _pump(tester, '/zpravy');
    expect(find.text('Lucie Pronajímatelka'), findsOneWidget);
    expect(find.textContaining('Byt 2+kk Dejvice'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('thread shows warnings, sends and receives in realtime', (tester) async {
    final repo = await _pump(tester, '/zpravy/c1');
    expect(find.text('Dobrý den, volejte [•••]'), findsOneWidget);
    expect(find.textContaining('Kontaktní údaje jsme skryli'), findsOneWidget);
    expect(find.textContaining('Pozor: zpráva žádá platbu předem'), findsOneWidget);
    expect(repo.reads, 1);

    await tester.enterText(find.byType(TextField), 'Raději se potkáme na prohlídce.');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(repo.sent, ['Raději se potkáme na prohlídce.']);
    expect(find.text('Raději se potkáme na prohlídce.'), findsOneWidget);

    repo.events$.add(RealtimeEvent('message', 'c1', message: _msg('m9', owner, 'Dobře, ve čtvrtek?', minute: 6)));
    await tester.pumpAndSettle();
    expect(find.text('Dobře, ve čtvrtek?'), findsOneWidget);
    expect(repo.reads, 2);

    expect(find.text('Přečteno'), findsNothing);
    // A receipt from the seeker's own side does not count.
    repo.events$.add(RealtimeEvent('read', 'c1', userId: seeker, at: DateTime(2026, 10, 14, 13)));
    await tester.pumpAndSettle();
    expect(find.text('Přečteno'), findsNothing);
    repo.events$.add(RealtimeEvent('read', 'c1', userId: owner, at: DateTime(2026, 10, 14, 13)));
    await tester.pumpAndSettle();
    expect(find.text('Přečteno'), findsOneWidget);
  });

  testWidgets('router knows the messaging routes', (tester) async {
    final router = createRouter();
    expect(
      router.configuration.routes.whereType<GoRoute>().map((r) => r.path),
      containsAll(['/zpravy', '/zpravy/:id']),
    );
  });
}
