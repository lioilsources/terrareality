import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/api/api_provider.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/auth/login_screen.dart';
import 'package:terrareality/src/auth/session.dart';
import 'package:terrareality/src/auth/token_store.dart';
import 'package:terrareality/src/messaging/conversations_screen.dart';
import 'package:terrareality/src/push/push_registrar.dart';
import 'package:terrareality/src/status/status_repository.dart';

import 'auth_fakes.dart';

class _Env {
  _Env({String? token, String? device})
    : store = MemoryTokenStore(token: token, pushDevice: device),
      initial = token;

  final auth = FakeAuth();
  final push = FakePush();
  final MemoryTokenStore store;
  final String? initial;

  List<Override> get overrides => [
    authRepositoryProvider.overrideWithValue(auth),
    pushRegistrarProvider.overrideWithValue(push),
    tokenStoreProvider.overrideWithValue(store),
    initialSessionProvider.overrideWithValue(initial),
  ];
}

Future<GoRouter> _pumpLogin(WidgetTester tester, _Env env) async {
  final router = GoRouter(initialLocation: '/login?next=/zadosti', routes: [
    GoRoute(path: '/login', builder: (_, s) => LoginScreen(next: s.uri.queryParameters['next'])),
    GoRoute(path: '/zadosti', builder: (_, _) => const Text('applications')),
    GoRoute(path: '/zpravy', builder: (_, _) => const Text('messages')),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: env.overrides,
    child: TerraApp(locale: const Locale('cs'), router: router),
  ));
  await tester.pumpAndSettle();
  return router;
}

Future<void> _enterCredentials(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('login-email')), 'anna@example.cz');
  await tester.enterText(find.byKey(const Key('login-password')), 'heslo-123456');
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
}

void main() {
  group('login', () {
    testWidgets('signs in, stores the token, registers push and returns to next', (tester) async {
      final env = _Env();
      await _pumpLogin(tester, env);
      await _enterCredentials(tester);
      expect(find.text('applications'), findsOneWidget);
      expect(env.store.token, 'tok-1');
      expect(env.auth.registered, ['fcm-1']);
      expect(env.store.pushDevice, 'dev-1');
    });

    testWidgets('mfa_required asks for the code and completes with completeMfa', (tester) async {
      final env = _Env()..auth.mfa = true;
      await _pumpLogin(tester, env);
      await _enterCredentials(tester);
      // Not "wrong password": the second step.
      expect(find.byKey(const Key('login-error')), findsNothing);
      expect(find.text('Ověřovací kód'), findsOneWidget);
      expect(env.store.token, isNull);

      env.auth.mfaError = ApiException(401, '{"code":"invalid_code","status":401,"title":"Unauthorized","type":"about:blank"}');
      await tester.enterText(find.byKey(const Key('mfa-code')), '000 000');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Kód nesouhlasí nebo vypršel. Zkuste to znovu.'), findsOneWidget);

      env.auth.mfaError = null;
      await tester.enterText(find.byKey(const Key('mfa-code')), '123 456');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      expect(env.auth.calls, contains('mfa:mfa-1'));
      expect(env.auth.codes.last, '123456');
      expect(env.store.token, 'tok-mfa');
      expect(find.text('applications'), findsOneWidget);
    });

    testWidgets('wrong password says so', (tester) async {
      final env = _Env()
        ..auth.loginError = ApiException(401, '{"code":"invalid_credentials","status":401}');
      await _pumpLogin(tester, env);
      await _enterCredentials(tester);
      expect(find.text('Přihlášení se nepovedlo. Zkontrolujte e-mail a heslo.'), findsOneWidget);
      expect(env.store.token, isNull);
    });

    testWidgets('offline is not reported as a wrong password', (tester) async {
      final env = _Env()..auth.loginError = offline();
      await _pumpLogin(tester, env);
      await _enterCredentials(tester);
      expect(find.textContaining('Nejste připojeni k internetu'), findsOneWidget);
    });

    testWidgets('a failing push registration does not fail the sign-in', (tester) async {
      final env = _Env()..auth.registerError = ApiException(500, 'boom');
      await _pumpLogin(tester, env);
      await _enterCredentials(tester);
      expect(find.text('applications'), findsOneWidget);
      expect(env.store.token, 'tok-1');
    });

    test('next only accepts in-app paths', () {
      expect(safeNext('/smlouvy/l1'), '/smlouvy/l1');
      expect(safeNext('//evil.example/x'), '/zpravy');
      expect(safeNext('https://evil.example'), '/zpravy');
      expect(safeNext('/login'), '/zpravy');
      expect(safeNext(null), '/zpravy');
    });
  });

  group('session', () {
    test('a restored session registers push at start; token refresh re-registers', () async {
      final env = _Env(token: 'stored');
      final c = ProviderContainer(overrides: env.overrides);
      addTearDown(c.dispose);
      expect(c.read(authSessionProvider), 'stored');
      c.read(pushRegistrationProvider);
      await pumpEventQueue();
      expect(env.auth.registered, ['fcm-1']);

      env.push.refresh.add('fcm-2');
      await pumpEventQueue();
      expect(env.auth.registered, ['fcm-1', 'fcm-2']);
      expect(env.store.pushDevice, 'dev-2');
    });

    test('no session: nothing is registered, refreshes are ignored', () async {
      final env = _Env();
      final c = ProviderContainer(overrides: env.overrides);
      addTearDown(c.dispose);
      c.read(pushRegistrationProvider);
      env.push.refresh.add('fcm-2');
      await pumpEventQueue();
      expect(env.auth.registered, isEmpty);
    });

    test('sign-out deletes the push device, logs out, clears the token and cached data', () async {
      final env = _Env(token: 'stored');
      var loads = 0;
      final c = ProviderContainer(overrides: [
        ...env.overrides,
        conversationsProvider.overrideWith((ref) async {
          loads++;
          return <Conversation>[];
        }),
      ]);
      addTearDown(c.dispose);
      final sub = c.listen(conversationsProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(conversationsProvider.future);
      expect(loads, 1);

      await c.read(authServiceProvider).signOut();
      // Registered for the restored session, then deleted while the session is
      // still valid, then the server session ends.
      expect(env.auth.calls, ['register:fcm-1', 'delete:dev-1', 'logout']);
      expect(env.store.token, isNull);
      expect(env.store.pushDevice, isNull);
      expect(c.read(authSessionProvider), isNull);
      await c.read(conversationsProvider.future);
      expect(loads, 2); // dropped and refetched, nothing of the previous user is cached
    });

    test('sign-out works offline', () async {
      final env = _Env(token: 'stored', device: 'dev-9')..auth.logoutError = offline();
      final c = ProviderContainer(overrides: env.overrides);
      addTearDown(c.dispose);
      await c.read(authServiceProvider).signOut();
      expect(env.store.token, isNull);
      expect(c.read(authSessionProvider), isNull);
    });
  });

  group('profile', () {
    testWidgets('signed in: shows the user and signs out after confirmation', (tester) async {
      final env = _Env(token: 'stored');
      await tester.pumpWidget(ProviderScope(
        overrides: env.overrides,
        child: TerraApp(locale: const Locale('cs'), router: createRouter(initialLocation: '/profil')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Anna Nováková'), findsOneWidget);
      expect(find.text('Přihlášen(a) jako anna@example.cz'), findsOneWidget);
      expect(find.text('O aplikaci'), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile-sign-out')));
      await tester.pumpAndSettle();
      expect(env.auth.calls, isNot(contains('logout'))); // nothing before the confirmation
      await tester.tap(find.byKey(const Key('confirm-sign-out')));
      await tester.pumpAndSettle();
      expect(env.auth.deleted, ['dev-1']); // the device registered for this session
      expect(env.auth.calls, contains('logout'));
      expect(env.store.token, isNull);
      expect(find.text('Byli jste odhlášeni.'), findsOneWidget);
      expect(find.byKey(const Key('profile-sign-in')), findsOneWidget);
    });

    testWidgets('About opens the platform status', (tester) async {
      final env = _Env();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...env.overrides,
          platformStatusProvider.overrideWith((ref) async => const PlatformStatus()),
        ],
        child: TerraApp(locale: const Locale('cs'), router: createRouter(initialLocation: '/profil')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Nejste přihlášeni.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('profile-about')));
      await tester.pumpAndSettle();
      expect(find.text('Stav platformy'), findsOneWidget);
    });
  });
}
