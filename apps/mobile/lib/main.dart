import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/api/api_provider.dart';
import 'src/app.dart';
import 'src/auth/token_store.dart';
import 'src/crash/crash_reporter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fails a release build without API_URL at start instead of talking to localhost.
  final apiUrl = defaultApiUrl();
  const store = SecureTokenStore();
  final token = await restoreSession(store);
  final reporter = crashReporterFromEnvironment();
  // Sentry installs its own handlers; the no-op reporter just logs.
  if (reporter is NoopCrashReporter) {
    FlutterError.onError = (d) {
      FlutterError.presentError(d);
      reporter.record(d.exception, d.stack);
    };
  }
  await reporter.run(
    () => ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWithValue(apiUrl),
        tokenStoreProvider.overrideWithValue(store),
        initialSessionProvider.overrideWithValue(token),
      ],
      child: TerraApp(),
    ),
  );
}
