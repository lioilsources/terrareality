import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../auth/token_store.dart';

/// API base URL. Set with `--dart-define=API_URL=https://api.terrareality.cz`.
/// Debug builds fall back to the host machine from simulators/emulators; a
/// release build without API_URL refuses to start instead of silently
/// talking to localhost (which ATS would block anyway).
String defaultApiUrl({bool release = kReleaseMode, String fromEnv = const String.fromEnvironment('API_URL')}) {
  if (fromEnv.isNotEmpty) {
    if (release && !fromEnv.startsWith('https://')) {
      throw StateError('API_URL must be https in release builds (got $fromEnv)');
    }
    return fromEnv;
  }
  if (release) {
    throw StateError('Release builds need --dart-define=API_URL=https://api.terrareality.cz');
  }
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

final apiBaseUrlProvider = Provider<String>((ref) => defaultApiUrl());

/// The session restored from secure storage at start (main overrides it).
final initialSessionProvider = Provider<String?>((ref) => null);

/// The signed-in session token (null when signed out). Persisted in the
/// platform keystore through [TokenStore]; sign-in and sign-out with their
/// side effects (push device, server logout) live in auth/session.dart.
class AuthSession extends Notifier<String?> {
  @override
  String? build() => ref.read(initialSessionProvider);

  Future<void> signIn(String token) async {
    state = token;
    await _persist(token);
  }

  Future<void> signOut() async {
    state = null;
    await _persist(null);
  }

  Future<void> _persist(String? token) async {
    try {
      await ref.read(tokenStoreProvider).writeToken(token);
    } catch (e) {
      // The session still works for this run; it just will not survive a restart.
      debugPrint('token store failed: $e');
    }
  }
}

final authSessionProvider = NotifierProvider<AuthSession, String?>(AuthSession.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(authSessionProvider);
  final auth = HttpBearerAuth();
  if (token != null) auth.accessToken = token;
  return ApiClient(basePath: ref.watch(apiBaseUrlProvider), authentication: auth);
});

final systemApiProvider = Provider<SystemApi>((ref) => SystemApi(ref.watch(apiClientProvider)));
