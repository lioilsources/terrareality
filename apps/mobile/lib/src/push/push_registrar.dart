import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/session.dart' show pushRegistrationProvider;
import '../platform/url_opener.dart';

/// Obtains the device push token and reports taps on notifications. The
/// Firebase implementation needs the project's google-services files
/// (docs/open-questions.md, OQ-14); until then the app runs without push and
/// relies on realtime and e-mail.
abstract class PushRegistrar {
  /// Returns an FCM token, or null when push is unavailable.
  Future<String?> token();

  /// The data payload of the notification that launched the app, if any.
  Future<Map<String, String>?> initialMessage();

  /// Data payloads of notifications tapped while the app runs.
  Stream<Map<String, String>> get opened;

  /// New tokens when the platform rotates the current one.
  Stream<String> get tokenRefresh;
}

class NoPush implements PushRegistrar {
  const NoPush();

  @override
  Future<String?> token() async => null;

  @override
  Future<Map<String, String>?> initialMessage() async => null;

  @override
  Stream<Map<String, String>> get opened => const Stream.empty();

  @override
  Stream<String> get tokenRefresh => const Stream.empty();
}

final pushRegistrarProvider = Provider<PushRegistrar>((ref) => const NoPush());

final _uuidish = RegExp(r'^[0-9A-Za-z-]+$');

/// Maps a push data payload to an app route.
///
/// Accepts an explicit `kind` + `id` (conversation, lease, viewing,
/// application, listing; an obligation's `id` is the payment share, its
/// screen is the lease in `lease_id`), the `conversation_id` the message
/// notifier sends, and otherwise the web `link` every push carries
/// (internal/notify/push.go): /zpravy/{id}, /zadosti/{id}, /smlouvy/{id},
/// /inzerat/{id}. Pushes for the landlord (`audience: landlord`) point to
/// the web admin, which the app does not have: no route (see
/// [externalLinkForPush]).
String? routeForPush(Map<String, String> data) {
  if (data['audience'] == 'landlord') return null;
  final id = data['id'];
  if (id != null && _uuidish.hasMatch(id)) {
    switch (data['kind']) {
      case 'conversation' || 'message':
        return '/zpravy/$id';
      case 'lease':
        return '/smlouvy/$id';
      case 'payment' || 'obligation':
        final lease = data['lease_id'];
        if (lease != null && _uuidish.hasMatch(lease)) return '/smlouvy/$lease';
      case 'application':
        return '/zadosti/$id';
      case 'viewing':
        return '/prohlidky';
      case 'listing':
        return '/inzerat/$id';
    }
  }
  final conv = data['conversation_id'];
  if (conv != null && _uuidish.hasMatch(conv)) return '/zpravy/$conv';
  final link = Uri.tryParse(data['link'] ?? '');
  final seg = link?.pathSegments ?? const [];
  if (seg.length == 2 && _uuidish.hasMatch(seg[1])) {
    switch (seg[0]) {
      case 'zpravy' || 'zadosti' || 'smlouvy' || 'inzerat':
        return '/${seg[0]}/${seg[1]}';
    }
  }
  if (seg.isNotEmpty && seg[0] == 'prohlidky') return '/prohlidky';
  return null;
}

/// The web page a landlord push opens in the browser (admin features stay
/// on the web), or null.
Uri? externalLinkForPush(Map<String, String> data) {
  if (data['audience'] != 'landlord') return null;
  final link = Uri.tryParse(data['link'] ?? '');
  if (link == null || (link.scheme != 'https' && link.scheme != 'http') || link.host.isEmpty) return null;
  return link;
}

/// Opens the screen a tapped notification points to.
class PushNavigation extends ConsumerStatefulWidget {
  const PushNavigation({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<PushNavigation> createState() => _PushNavigationState();
}

class _PushNavigationState extends ConsumerState<PushNavigation> {
  StreamSubscription<Map<String, String>>? _sub;

  @override
  void initState() {
    super.initState();
    // Registers the device for a restored session and follows sign-in/out.
    ref.read(pushRegistrationProvider);
    final push = ref.read(pushRegistrarProvider);
    _sub = push.opened.listen(_open);
    push.initialMessage().then((m) {
      if (m != null && mounted) _open(m);
    });
  }

  void _open(Map<String, String> data) {
    final route = routeForPush(data);
    if (route != null) {
      widget.router.push(route);
      return;
    }
    final web = externalLinkForPush(data);
    if (web != null) ref.read(urlOpenerProvider).open(web);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
