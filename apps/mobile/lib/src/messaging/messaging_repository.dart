import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as cf;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../api/api_provider.dart';
import '../push/push_registrar.dart';

/// A realtime event from the conversation channel (see the web client).
class RealtimeEvent {
  RealtimeEvent(this.type, this.conversationId, {this.message, this.userId, this.at});

  final String type; // message | read | blocked | removed
  final String conversationId;
  final Message? message;
  final String? userId;
  final DateTime? at;

  static RealtimeEvent? fromJson(Map<String, dynamic> j) {
    final conv = j['conversation_id'] as String?;
    final type = j['type'] as String?;
    if (conv == null || type == null) return null;
    return RealtimeEvent(
      type,
      conv,
      message: j['message'] == null ? null : Message.fromJson(j['message']),
      userId: j['user_id'] as String?,
      at: j['at'] == null ? null : DateTime.parse(j['at'] as String),
    );
  }
}

/// Messaging operations the screens need.
abstract class MessagingRepository {
  Future<List<Conversation>> conversations();
  Future<ConversationDetail> detail(String id);
  Future<List<Message>> messages(String id);
  Future<Message> send(String id, String body);
  Future<void> markRead(String id);
  Future<void> report(String id, String reason, String note);

  /// Events of one conversation while the stream is listened to.
  Stream<RealtimeEvent> events(String id);
}

class ApiMessagingRepository implements MessagingRepository {
  ApiMessagingRepository(this.api);

  final MessagingApi api;

  @override
  Future<List<Conversation>> conversations() async => await api.listConversations() ?? [];

  @override
  Future<ConversationDetail> detail(String id) async => (await api.getConversation(id))!;

  @override
  Future<List<Message>> messages(String id) async => (await api.listMessages(id, limit: 100) ?? []).reversed.toList();

  @override
  Future<Message> send(String id, String body) async => (await api.sendMessage(id, MessageInput(body: body)))!.message;

  @override
  Future<void> markRead(String id) => api.markConversationRead(id);

  @override
  Future<void> report(String id, String reason, String note) => api.reportConversation(
    id,
    ReportInput(reason: ReportInputReasonEnum.fromJson(reason)!, note: note.isEmpty ? null : note),
  );

  @override
  Stream<RealtimeEvent> events(String id) {
    late cf.Client client;
    final out = StreamController<RealtimeEvent>();
    void handle(List<int> data) {
      final e = RealtimeEvent.fromJson(jsonDecode(utf8.decode(data)) as Map<String, dynamic>);
      if (e != null && e.conversationId == id) out.add(e);
    }

    out.onListen = () async {
      final tok = (await api.realtimeToken())!;
      client = cf.createClient(
        tok.url,
        cf.ClientConfig(token: tok.token, getToken: (_) async => (await api.realtimeToken())!.token),
      );
      final sub = client.newSubscription(
        'conv:$id',
        cf.SubscriptionConfig(getToken: (_) async => (await api.conversationRealtimeToken(id))!.token),
      );
      sub.publication.listen((e) => handle(e.data));
      await sub.subscribe();
      await client.connect();
    };
    out.onCancel = () => client.disconnect();
    return out.stream;
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => ApiMessagingRepository(MessagingApi(ref.watch(apiClientProvider))),
);

/// Signs in with e-mail and password and registers the device for push.
Future<void> signIn(WidgetRef ref, String email, String password) async {
  final res = await AuthApi(
    ref.read(apiClientProvider),
  ).login(LoginRequest(email: email, password: password, client: ClientKind.mobile));
  final token = res?.session?.token;
  if (token == null) throw StateError('second factor required');
  ref.read(authSessionProvider.notifier).signIn(token);
  final push = await ref.read(pushRegistrarProvider).token();
  if (push != null) {
    await MeApi(
      ref.read(apiClientProvider),
    ).registerPushDevice(PushDeviceInput(platform: PushDeviceInputPlatformEnum.fcm, token: push, label: 'app'));
  }
}
