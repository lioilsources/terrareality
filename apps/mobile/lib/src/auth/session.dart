import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../api/api_provider.dart';
import '../push/push_registrar.dart';
import 'session_scope.dart';
import 'token_store.dart';

/// The auth calls the app makes. Overridden in tests.
abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> completeMfa(String mfaToken, String code);

  /// E-mails a one-time sign-in link (always succeeds, no account enumeration).
  Future<void> requestMagicLink(String email, UserLocale? locale);

  /// Exchanges the token from the sign-in link for a session.
  Future<AuthResult> verifyMagicLink(String token);

  /// E-mails a password reset link (always succeeds, no account enumeration).
  Future<void> forgotPassword(String email, UserLocale? locale);

  /// Sets a new password with the token from the reset link.
  Future<void> resetPassword(String token, String password);

  Future<void> logout();
  Future<Me?> me();

  /// Registers the device's push token and returns the device id.
  Future<String?> registerPush(String token);
  Future<void> deletePush(String deviceId);
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.client);

  final ApiClient client;

  @override
  Future<AuthResult> login(String email, String password) async =>
      (await AuthApi(client).login(LoginRequest(email: email, password: password, client: ClientKind.mobile)))!;

  @override
  Future<AuthResult> completeMfa(String mfaToken, String code) async =>
      (await AuthApi(client).completeMfa(MfaRequest(mfaToken: mfaToken, code: code)))!;

  @override
  Future<void> requestMagicLink(String email, UserLocale? locale) =>
      AuthApi(client).requestMagicLink(MagicLinkRequest(email: email, locale: locale));

  @override
  Future<AuthResult> verifyMagicLink(String token) async =>
      (await AuthApi(client).verifyMagicLink(TokenRequest(token: token, client: ClientKind.mobile)))!;

  @override
  Future<void> forgotPassword(String email, UserLocale? locale) =>
      AuthApi(client).forgotPassword(MagicLinkRequest(email: email, locale: locale));

  @override
  Future<void> resetPassword(String token, String password) =>
      AuthApi(client).resetPassword(PasswordResetRequest(token: token, password: password));

  @override
  Future<void> logout() => AuthApi(client).logout();

  @override
  Future<Me?> me() => MeApi(client).getMe();

  @override
  Future<String?> registerPush(String token) async => (await MeApi(client).registerPushDevice(
    PushDeviceInput(platform: PushDeviceInputPlatformEnum.fcm, token: token, label: 'app'),
  ))?.id;

  @override
  Future<void> deletePush(String deviceId) => MeApi(client).deletePushDevice(deviceId);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => ApiAuthRepository(ref.watch(apiClientProvider)));

/// The outcome of the password step.
sealed class LoginOutcome {
  const LoginOutcome();
}

class SignedIn extends LoginOutcome {
  const SignedIn();
}

/// TOTP (or a recovery code) is needed; pass [mfaToken] to [AuthService.completeMfa].
class MfaRequired extends LoginOutcome {
  const MfaRequired(this.mfaToken);
  final String mfaToken;
}

/// Sign-in, the second factor and sign-out with their side effects.
class AuthService {
  AuthService(this.ref);

  final Ref ref;

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<LoginOutcome> login(String email, String password) => _finish(_repo.login(email, password));

  Future<LoginOutcome> completeMfa(String mfaToken, String code) => _finish(_repo.completeMfa(mfaToken, code));

  /// Signs in with the token from an e-mailed sign-in link. Like the
  /// password step it may answer with [MfaRequired].
  Future<LoginOutcome> verifyMagicLink(String token) => _finish(_repo.verifyMagicLink(token));

  Future<void> requestMagicLink(String email, UserLocale? locale) => _repo.requestMagicLink(email, locale);

  Future<void> forgotPassword(String email, UserLocale? locale) => _repo.forgotPassword(email, locale);

  /// Sets the new password. The API revokes every session of the account,
  /// so a session stored on this phone is dropped as well.
  Future<void> resetPassword(String token, String password) async {
    await _repo.resetPassword(token, password);
    if (ref.read(authSessionProvider) != null) await signOut();
  }

  Future<LoginOutcome> _finish(Future<AuthResult> call) async {
    final res = await call;
    final token = res.session?.token;
    if (token != null) {
      // Push registration follows the session (PushRegistration), so a
      // failing push endpoint never fails the sign-in.
      await ref.read(authSessionProvider.notifier).signIn(token);
      return const SignedIn();
    }
    if (res.status == AuthResultStatusEnum.mfaRequired && res.mfaToken != null) {
      return MfaRequired(res.mfaToken!);
    }
    throw StateError('unexpected auth result ${res.status}');
  }

  /// Unregisters this device from push, ends the server session, forgets
  /// the token and drops cached data. Each step is best effort: being
  /// offline must not keep the user signed in on this phone.
  Future<void> signOut() async {
    await ref.read(pushRegistrationProvider).unregister();
    try {
      await _repo.logout();
    } catch (e) {
      debugPrint('logout failed: $e');
    }
    await ref.read(authSessionProvider.notifier).signOut();
    for (final p in sessionScopedProviders()) {
      ref.invalidate(p);
    }
  }
}

final authServiceProvider = Provider<AuthService>(AuthService.new);

/// Keeps the device's push registration in step with the session: registers
/// on sign-in and on a restored session, re-registers when the platform
/// rotates the token, and unregisters on sign-out. Failures are only logged.
class PushRegistration {
  PushRegistration(this.ref);

  final Ref ref;
  StreamSubscription<String>? _refresh;

  // Register and unregister run one after another, so a registration still
  // in flight cannot store a device id after sign-out cleared it.
  Future<void> _last = Future.value();

  Future<void> _serial(Future<void> Function() op) => _last = _last.then((_) => op()).catchError((Object e) {
    debugPrint('push registration failed: $e');
  });

  void _start() {
    ref.listen<String?>(authSessionProvider, (prev, next) {
      if (next != null && next != prev) unawaited(register());
    }, fireImmediately: true);
    _refresh = ref.read(pushRegistrarProvider).tokenRefresh.listen((t) {
      if (ref.read(authSessionProvider) != null) unawaited(register(pushToken: t));
    });
    ref.onDispose(() => _refresh?.cancel());
  }

  Future<void> register({String? pushToken}) => _serial(() async {
    if (ref.read(authSessionProvider) == null) return;
    final token = pushToken ?? await ref.read(pushRegistrarProvider).token();
    if (token == null) return;
    final id = await ref.read(authRepositoryProvider).registerPush(token);
    if (id != null) await ref.read(tokenStoreProvider).writePushDevice(id);
  });

  /// Deletes this device's registration (call while the session is valid).
  Future<void> unregister() => _serial(() async {
    final store = ref.read(tokenStoreProvider);
    try {
      final id = await store.readPushDevice();
      if (id != null) await ref.read(authRepositoryProvider).deletePush(id);
    } catch (e) {
      debugPrint('push unregister failed: $e');
    }
    await store.writePushDevice(null);
  });
}

final pushRegistrationProvider = Provider<PushRegistration>((ref) => PushRegistration(ref).._start());

/// The signed-in user (null when signed out).
final meProvider = FutureProvider.autoDispose<Me?>((ref) async {
  if (ref.watch(authSessionProvider) == null) return null;
  return ref.watch(authRepositoryProvider).me();
});
