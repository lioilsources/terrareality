import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/common/api_error.dart';
import 'package:terrareality/src/messaging/messaging_repository.dart';

import 'auth_fakes.dart' show offline;

/// Messaging that fails until [error] is cleared.
class FailingRepo implements MessagingRepository {
  FailingRepo(this.error);

  Object? error;
  Object? sendError;
  int loads = 0;

  Conversation _conv() => Conversation(
    id: 'c1',
    listingId: 'l1',
    orgId: 'o1',
    orgName: 'Lucie',
    seekerId: 's1',
    seekerName: 'Tomáš',
    listingTitle: I18nText(cs: 'Byt', en: ''),
    role: ConversationRole.seeker,
    lastMessageAt: DateTime(2026, 10, 14),
    lastMessage: 'Dobrý den',
    unread: 0,
    blocked: false,
    blockedByMe: false,
    createdAt: DateTime(2026, 10, 14),
  );

  @override
  Future<List<Conversation>> conversations({String? before, int limit = conversationsPageSize}) async {
    loads++;
    if (error != null) throw error!;
    return [_conv()];
  }

  @override
  Future<ConversationDetail> detail(String id) async {
    loads++;
    if (error != null) throw error!;
    return ConversationDetail(conversation: _conv(), prescreen: []);
  }

  @override
  Future<List<Message>> messages(String id) async => [];

  @override
  Future<Message> send(String id, String body) async => throw sendError ?? ApiException(500, 'boom');

  @override
  Future<void> markRead(String id) async => throw ApiException(401, 'expired');

  @override
  Future<void> report(String id, String reason, String note) async {}

  @override
  Stream<RealtimeEvent> events(String id) => Stream.error(ApiException(401, 'expired'));
}

/// Fails the realtime token call; [gate] holds it to cancel during setup.
class _RealtimeApi extends MessagingApi {
  _RealtimeApi({this.gate});

  final Completer<void>? gate;

  @override
  Future<RealtimeToken?> realtimeToken() async {
    await gate?.future;
    throw ApiException(401, '{"code":"unauthorized"}');
  }
}

Future<FailingRepo> _pump(WidgetTester tester, String path, Object? error) async {
  final repo = FailingRepo(error);
  await tester.pumpWidget(ProviderScope(
    overrides: [messagingRepositoryProvider.overrideWithValue(repo)],
    child: TerraApp(locale: const Locale('cs'), router: createRouter(initialLocation: path)),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('errors are classified for the user', () {
    expect(errorKind(ApiException(401, '')), ErrorKind.signIn);
    expect(errorKind(offline()), ErrorKind.offline);
    expect(errorKind(ApiException(403, '')), ErrorKind.forbidden);
    expect(errorKind(ApiException(429, '')), ErrorKind.rateLimited);
    expect(errorKind(ApiException(500, '')), ErrorKind.server);
    expect(errorKind(StateError('x')), ErrorKind.server);
    expect(errorCode(ApiException(400, '{"code":"invalid_provider"}')), 'invalid_provider');
    expect(errorCode(ApiException(502, '<html>')), isNull);
  });

  testWidgets('a signed-out inbox asks to sign in instead of "API unreachable"', (tester) async {
    await _pump(tester, '/zpravy', ApiException(401, 'unauthorized'));
    expect(find.text('Nejdřív se přihlaste.'), findsOneWidget);
    expect(find.text('API není dostupné'), findsNothing);
    await tester.tap(find.byKey(const Key('error-sign-in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-email')), findsOneWidget);
  });

  testWidgets('offline shows retry, and retry reloads', (tester) async {
    final repo = await _pump(tester, '/zpravy', offline());
    expect(find.textContaining('Nejste připojeni k internetu'), findsOneWidget);
    repo.error = null;
    await tester.tap(find.byKey(const Key('error-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Lucie'), findsOneWidget);
  });

  testWidgets('a thread opened with an expired session shows the error, not a blank screen', (tester) async {
    await _pump(tester, '/zpravy/c1', ApiException(401, 'expired'));
    expect(find.byKey(const Key('api-error')), findsOneWidget);
    expect(find.byKey(const Key('error-sign-in')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed send keeps the text and says why', (tester) async {
    final repo = await _pump(tester, '/zpravy/c1', null);
    repo.sendError = offline();
    await tester.enterText(find.byType(TextField), 'Dobrý den');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nejste připojeni k internetu'), findsOneWidget);
    expect(find.text('Dobrý den'), findsWidgets); // still in the field
    expect(tester.takeException(), isNull);
  });

  test('realtime setup errors reach the stream', () async {
    final events = ApiMessagingRepository(_RealtimeApi()).events('c1');
    await expectLater(events, emitsError(isA<ApiException>()));
  });

  test('cancelling during realtime setup does not throw', () async {
    final gate = Completer<void>();
    final errors = <Object>[];
    await runZonedGuarded(() async {
      final sub = ApiMessagingRepository(_RealtimeApi(gate: gate)).events('c1').listen((_) {});
      await sub.cancel(); // before the token call returns
      gate.complete();
      await pumpEventQueue();
    }, (e, _) => errors.add(e));
    expect(errors, isEmpty);
  });
}
