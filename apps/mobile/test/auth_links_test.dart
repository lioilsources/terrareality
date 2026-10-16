import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/api/api_provider.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/auth/link_screens.dart';
import 'package:terrareality/src/auth/login_screen.dart';
import 'package:terrareality/src/auth/session.dart';
import 'package:terrareality/src/auth/token_store.dart';
import 'package:terrareality/src/messaging/messaging_repository.dart';
import 'package:terrareality/src/push/push_registrar.dart';

import 'auth_fakes.dart';
import 'messaging_test.dart' show FakeRepo;

const _token = 'tok_0123456789abcdefghij';

class _Env {
  _Env({String? token}) : store = MemoryTokenStore(token: token), initial = token;

  final auth = FakeAuth();
  final push = FakePush();
  final MemoryTokenStore store;
  final String? initial;

  List<Override> get overrides => [
    authRepositoryProvider.overrideWithValue(auth),
    pushRegistrarProvider.overrideWithValue(push),
    tokenStoreProvider.overrideWithValue(store),
    initialSessionProvider.overrideWithValue(initial),
    messagingRepositoryProvider.overrideWithValue(_EmptyInbox()),
  ];
}

/// The app router as the platform hands it an App Link / Universal Link.
Future<GoRouter> _open(WidgetTester tester, _Env env, String location) async {
  final router = createRouter(initialLocation: location);
  await tester.pumpWidget(ProviderScope(
    overrides: env.overrides,
    child: TerraApp(locale: const Locale('cs'), router: router),
  ));
  await tester.pumpAndSettle();
  return router;
}

Future<void> _pumpLogin(WidgetTester tester, _Env env) async {
  final router = GoRouter(initialLocation: '/login', routes: [
    GoRoute(path: '/login', builder: (_, s) => LoginScreen(next: s.uri.queryParameters['next'])),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: env.overrides,
    child: TerraApp(locale: const Locale('cs'), router: router),
  ));
  await tester.pumpAndSettle();
}

String _path(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

ApiException _problem(int status, String code) =>
    ApiException(status, '{"code":"$code","status":$status,"title":"x","type":"about:blank"}');

void main() {
  group('deep-link routes', () {
    testWidgets('the e-mailed sign-in link opens the magic link screen with its token', (tester) async {
      final env = _Env()..auth.magicError = _problem(400, 'invalid_token');
      final router = await _open(tester, env, 'https://app.terrareality.cz/auth/magic?token=$_token');
      expect(find.byType(MagicLinkScreen), findsOneWidget);
      expect(_path(router), magicLinkPath);
      expect(env.auth.calls, ['magic:$_token']);
    });

    testWidgets('the reset link opens the new password form with its token', (tester) async {
      final env = _Env();
      await _open(tester, env, '/auth/reset?token=$_token');
      final screen = tester.widget<ResetPasswordScreen>(find.byType(ResetPasswordScreen));
      expect(screen.token, _token);
    });

    testWidgets('a link without a token is invalid and calls nothing', (tester) async {
      final env = _Env();
      await _open(tester, env, '/auth/magic');
      expect(find.text('Odkaz je neplatný nebo už vypršel. Požádejte o nový.'), findsOneWidget);
      expect(env.auth.calls, isEmpty);
    });
  });

  group('magic link', () {
    testWidgets('request: sends the link for the entered e-mail in the app language', (tester) async {
      final env = _Env();
      await _pumpLogin(tester, env);
      await tester.enterText(find.byKey(const Key('login-email')), ' anna@example.cz ');
      await tester.tap(find.byKey(const Key('login-magic-link')));
      await tester.pumpAndSettle();
      expect(env.auth.sent, ['magic:anna@example.cz:cs']);
      expect(find.byKey(const Key('login-info')), findsOneWidget);
      expect(find.textContaining('anna@example.cz'), findsWidgets);
    });

    testWidgets('request without an e-mail asks for it', (tester) async {
      final env = _Env();
      await _pumpLogin(tester, env);
      await tester.tap(find.byKey(const Key('login-magic-link')));
      await tester.pumpAndSettle();
      expect(find.text('Nejdřív vyplňte e-mail.'), findsOneWidget);
      expect(env.auth.sent, isEmpty);
    });

    testWidgets('request: rate limit goes through the shared error mapping', (tester) async {
      final env = _Env()..auth.sendError = _problem(429, 'rate_limited');
      await _pumpLogin(tester, env);
      await tester.enterText(find.byKey(const Key('login-email')), 'anna@example.cz');
      await tester.tap(find.byKey(const Key('login-magic-link')));
      await tester.pumpAndSettle();
      expect(find.text('Příliš mnoho pokusů. Zkuste to prosím za chvíli.'), findsOneWidget);
    });

    testWidgets('consume: signs in, stores the token, registers push, opens the app', (tester) async {
      final env = _Env();
      final router = await _open(tester, env, '/auth/magic?token=$_token');
      expect(env.store.token, 'tok-magic');
      expect(env.auth.registered, ['fcm-1']);
      expect(env.store.pushDevice, 'dev-1');
      expect(_path(router), '/zpravy');
    });

    testWidgets('consume: an expired token says so and offers the sign-in screen', (tester) async {
      final env = _Env()..auth.magicError = _problem(400, 'invalid_token');
      final router = await _open(tester, env, '/auth/magic?token=$_token');
      expect(find.text('Odkaz je neplatný nebo už vypršel. Požádejte o nový.'), findsOneWidget);
      expect(find.byKey(const Key('error-retry')), findsNothing);
      expect(env.store.token, isNull);
      await tester.tap(find.byKey(const Key('link-login')));
      await tester.pumpAndSettle();
      expect(_path(router), '/login');
    });

    testWidgets('consume offline can be retried (the token was not used)', (tester) async {
      final env = _Env()..auth.magicError = offline();
      await _open(tester, env, '/auth/magic?token=$_token');
      expect(find.textContaining('Nejste připojeni k internetu'), findsOneWidget);
      env.auth.magicError = null;
      await tester.tap(find.byKey(const Key('error-retry')));
      await tester.pumpAndSettle();
      expect(env.store.token, 'tok-magic');
    });

    testWidgets('consume: mfa_required continues with the code step', (tester) async {
      final env = _Env()..auth.mfa = true;
      final router = await _open(tester, env, '/auth/magic?token=$_token');
      expect(_path(router), '/login');
      expect(find.text('Ověřovací kód'), findsOneWidget);
      expect(env.store.token, isNull);
      // The mfa token never appears in the location.
      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/login');

      await tester.enterText(find.byKey(const Key('mfa-code')), '123456');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      expect(env.auth.calls, contains('mfa:mfa-magic'));
      expect(env.store.token, 'tok-mfa');
      expect(_path(router), '/zpravy');
    });
  });

  group('password reset', () {
    testWidgets('request: sends the reset e-mail for the entered address', (tester) async {
      final env = _Env();
      await _pumpLogin(tester, env);
      await tester.enterText(find.byKey(const Key('login-email')), 'anna@example.cz');
      await tester.tap(find.byKey(const Key('login-forgot')));
      await tester.pumpAndSettle();
      expect(env.auth.sent, ['reset:anna@example.cz:cs']);
      expect(find.byKey(const Key('login-info')), findsOneWidget);
    });

    testWidgets('consume: sets the password and sends the user to sign in', (tester) async {
      final env = _Env();
      final router = await _open(tester, env, '/auth/reset?token=$_token');
      await tester.enterText(find.byKey(const Key('reset-password')), 'dlouhe-nove-heslo');
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();
      expect(env.auth.calls, ['reset:$_token']);
      expect(find.byKey(const Key('reset-done')), findsOneWidget);
      await tester.tap(find.byKey(const Key('link-login')));
      await tester.pumpAndSettle();
      expect(_path(router), '/login');
    });

    testWidgets('consume drops a session stored on this phone (the API revoked it)', (tester) async {
      final env = _Env(token: 'old');
      await _open(tester, env, '/auth/reset?token=$_token');
      await tester.enterText(find.byKey(const Key('reset-password')), 'dlouhe-nove-heslo');
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();
      expect(env.store.token, isNull);
      expect(find.byKey(const Key('reset-done')), findsOneWidget);
    });

    testWidgets('a short password is refused before calling the API', (tester) async {
      final env = _Env();
      await _open(tester, env, '/auth/reset?token=$_token');
      await tester.enterText(find.byKey(const Key('reset-password')), 'kratke');
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Heslo musí mít alespoň 12 znaků.'), findsOneWidget);
      expect(env.auth.calls, isEmpty);
    });

    for (final (code, message) in [
      ('password_too_weak', 'Heslo je příliš snadno uhodnutelné. Zvolte jiné.'),
      ('password_breached', 'Toto heslo se objevilo v úniku dat. Zvolte jiné.'),
    ]) {
      testWidgets('consume: $code is shown and the form stays', (tester) async {
        final env = _Env()..auth.resetError = _problem(422, code);
        await _open(tester, env, '/auth/reset?token=$_token');
        await tester.enterText(find.byKey(const Key('reset-password')), '111111111111');
        await tester.tap(find.byKey(const Key('reset-submit')));
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
        expect(find.byKey(const Key('reset-submit')), findsOneWidget);
        expect(find.byKey(const Key('reset-done')), findsNothing);
      });
    }

    testWidgets('consume: an invalid token says the link expired', (tester) async {
      final env = _Env()..auth.resetError = _problem(400, 'invalid_token');
      await _open(tester, env, '/auth/reset?token=$_token');
      await tester.enterText(find.byKey(const Key('reset-password')), 'dlouhe-nove-heslo');
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Odkaz je neplatný nebo už vypršel. Požádejte o nový.'), findsOneWidget);
      expect(find.byKey(const Key('reset-done')), findsNothing);
    });
  });
}

class _EmptyInbox extends FakeRepo {
  @override
  Future<List<Conversation>> conversations({String? before, int limit = conversationsPageSize}) async => [];
}
