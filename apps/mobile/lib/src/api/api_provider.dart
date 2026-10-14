import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

/// API base URL. Override with `--dart-define=API_URL=https://api.terrareality.cz`.
/// Defaults reach the host machine from simulators/emulators in dev.
String defaultApiUrl() {
  const fromEnv = String.fromEnvironment('API_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

final apiBaseUrlProvider = Provider<String>((ref) => defaultApiUrl());

/// The signed-in session token (null when signed out). Kept in memory for
/// now; secure storage arrives with the full app in M8.
class AuthSession extends Notifier<String?> {
  @override
  String? build() => null;

  void signIn(String token) => state = token;
  void signOut() => state = null;
}

final authSessionProvider = NotifierProvider<AuthSession, String?>(AuthSession.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(authSessionProvider);
  final auth = HttpBearerAuth();
  if (token != null) auth.accessToken = token;
  return ApiClient(basePath: ref.watch(apiBaseUrlProvider), authentication: auth);
});

final systemApiProvider = Provider<SystemApi>((ref) => SystemApi(ref.watch(apiClientProvider)));
