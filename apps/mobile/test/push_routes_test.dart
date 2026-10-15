import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terrareality/src/platform/url_opener.dart';
import 'package:terrareality/src/push/push_registrar.dart';

class _FakePush implements PushRegistrar {
  final controller = StreamController<Map<String, String>>.broadcast();

  @override
  Future<String?> token() async => 'tok';

  @override
  Future<Map<String, String>?> initialMessage() async => null;

  @override
  Stream<Map<String, String>> get opened => controller.stream;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();
}

class _FakeOpener implements UrlOpener {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

void main() {
  test('push payloads map to app routes', () {
    expect(routeForPush({'kind': 'conversation', 'id': 'c1'}), '/zpravy/c1');
    expect(routeForPush({'kind': 'lease', 'id': 'l1'}), '/smlouvy/l1');
    expect(routeForPush({'kind': 'viewing', 'id': 'b1'}), '/prohlidky');
    expect(routeForPush({'conversation_id': 'c2', 'link': 'https://terrareality.cz/zpravy/c2'}), '/zpravy/c2');
    expect(routeForPush({'link': 'https://terrareality.cz/zadosti/a1'}), '/zadosti/a1');
    expect(routeForPush({'link': 'https://terrareality.cz/admin'}), isNull);
    expect(routeForPush({}), isNull);
  });

  test('application, lease and obligation pushes from the API open their screens', () {
    // Payloads as internal/applications/push.go and internal/leasing/push.go send them.
    expect(
      routeForPush({
        'kind': 'application',
        'id': 'a1',
        'status': 'accepted',
        'link': 'https://terrareality.cz/zadosti/a1',
      }),
      '/zadosti/a1',
    );
    expect(
      routeForPush({'kind': 'lease', 'id': 'l1', 'state': 'proposed', 'link': 'https://terrareality.cz/smlouvy/l1'}),
      '/smlouvy/l1',
    );
    // An obligation's id is the payment share; the screen is its lease.
    expect(
      routeForPush({'kind': 'obligation', 'id': 's1', 'lease_id': 'l1', 'stage': 'payment_overdue'}),
      '/smlouvy/l1',
    );
    // Without lease_id the web link is the fallback.
    expect(
      routeForPush({'kind': 'obligation', 'id': 's1', 'link': 'https://terrareality.cz/smlouvy/l2'}),
      '/smlouvy/l2',
    );
    expect(externalLinkForPush({'kind': 'lease', 'id': 'l1'}), isNull);
  });

  test('landlord pushes open the web admin instead of an app route', () {
    final data = {
      'kind': 'application',
      'id': 'a1',
      'audience': 'landlord',
      'org_id': 'o1',
      'link': 'https://terrareality.cz/admin/orgs/o1/listings/x1/zajemci',
    };
    expect(routeForPush(data), isNull);
    expect(externalLinkForPush(data).toString(), 'https://terrareality.cz/admin/orgs/o1/listings/x1/zajemci');
    expect(externalLinkForPush({'audience': 'landlord', 'link': 'javascript:alert(1)'}), isNull);
    expect(routeForPush({'kind': 'obligation', 'id': 'l1', 'lease_id': 'l1', 'audience': 'landlord'}), isNull);
  });

  testWidgets('tapping pushes navigates or opens the browser', (tester) async {
    final push = _FakePush();
    final opener = _FakeOpener();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Text('home', textDirection: TextDirection.ltr),
        ),
        GoRoute(
          path: '/smlouvy/:id',
          builder: (_, s) => Text('lease ${s.pathParameters['id']}', textDirection: TextDirection.ltr),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pushRegistrarProvider.overrideWithValue(push), urlOpenerProvider.overrideWithValue(opener)],
        child: PushNavigation(
          router: router,
          child: WidgetsApp.router(routerConfig: router, color: const Color(0xFF000000)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    push.controller.add({'kind': 'obligation', 'id': 's1', 'lease_id': 'l9'});
    await tester.pumpAndSettle();
    expect(find.text('lease l9'), findsOneWidget);
    expect(opener.opened, isEmpty);

    push.controller.add({
      'kind': 'lease',
      'id': 'l9',
      'audience': 'landlord',
      'link': 'https://terrareality.cz/admin/orgs/o1/smlouvy/l9',
    });
    await tester.pumpAndSettle();
    expect(opener.opened, [Uri.parse('https://terrareality.cz/admin/orgs/o1/smlouvy/l9')]);
  });
}
