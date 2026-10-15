import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry DSN; crash reporting is off unless `--dart-define=SENTRY_DSN=...`.
const sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Deployment name sent with crash reports (`--dart-define=SENTRY_ENVIRONMENT=...`).
const sentryEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: 'development');

/// Reports uncaught errors. No personal data is attached (sendDefaultPii off).
abstract class CrashReporter {
  /// Starts the reporter and runs the app inside it.
  Future<void> run(Widget Function() app);

  void record(Object error, StackTrace? stack);
}

/// The default: errors stay in the debug console.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> run(Widget Function() app) async => runApp(app());

  @override
  void record(Object error, StackTrace? stack) => debugPrint('error: $error');
}

class SentryCrashReporter implements CrashReporter {
  const SentryCrashReporter(this.dsn);

  final String dsn;

  @override
  Future<void> run(Widget Function() app) => SentryFlutter.init(
        (o) {
          o.dsn = dsn;
          o.environment = sentryEnvironment;
          o.sendDefaultPii = false;
          o.tracesSampleRate = 0;
        },
        appRunner: () => runApp(app()),
      );

  @override
  void record(Object error, StackTrace? stack) => unawaited(Sentry.captureException(error, stackTrace: stack));
}

CrashReporter crashReporterFromEnvironment() =>
    sentryDsn.isEmpty ? const NoopCrashReporter() : const SentryCrashReporter(sentryDsn);
