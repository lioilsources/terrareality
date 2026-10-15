import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:terra_api/api.dart';

/// Sentry DSN; crash reporting is off unless `--dart-define=SENTRY_DSN=...`.
const sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Deployment name sent with crash reports (`--dart-define=SENTRY_ENVIRONMENT=...`).
const sentryEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: 'development');

/// Reports uncaught errors. No personal data is attached (sendDefaultPii off,
/// API response bodies scrubbed by [scrubEvent]).
abstract class CrashReporter {
  /// Starts the reporter and runs the app inside it.
  Future<void> run(Widget Function() app);

  void record(Object error, StackTrace? stack);
}

/// A safe description of an error: API errors keep only their status code,
/// never the response body (which can carry names, messages, addresses).
String describeError(Object error) =>
    error is ApiException ? 'ApiException(${error.code})' : error.runtimeType.toString();

/// The default: errors stay in the debug console, without response bodies.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> run(Widget Function() app) async => runApp(app());

  @override
  void record(Object error, StackTrace? stack) => debugPrint('error: ${describeError(error)}');
}

final _bodyLike = RegExp(r'ApiException \d+: .*', dotAll: true);

/// Drops API response bodies from a Sentry event: the generated client puts
/// the whole body into `ApiException.message`, which ends up in the
/// exception value and breadcrumbs.
SentryEvent scrubEvent(SentryEvent event) {
  final exceptions = event.exceptions;
  if (exceptions != null) {
    for (final e in exceptions) {
      if (e.type == 'ApiException' || (e.value?.startsWith('ApiException') ?? false)) {
        final t = e.throwable;
        e.value = t is ApiException ? 'ApiException(${t.code})' : 'ApiException';
      } else if (e.value != null) {
        e.value = e.value!.replaceAll(_bodyLike, 'ApiException');
      }
    }
  }
  final crumbs = event.breadcrumbs;
  if (crumbs != null) {
    for (final b in crumbs) {
      if (b.message != null) b.message = b.message!.replaceAll(_bodyLike, 'ApiException');
    }
  }
  final message = event.message;
  if (message != null) {
    event.message = SentryMessage(message.formatted.replaceAll(_bodyLike, 'ApiException'));
  }
  return event;
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
          o.beforeSend = (event, hint) => scrubEvent(event);
        },
        appRunner: () => runApp(app()),
      );

  @override
  void record(Object error, StackTrace? stack) => unawaited(Sentry.captureException(error, stackTrace: stack));
}

CrashReporter crashReporterFromEnvironment() =>
    sentryDsn.isEmpty ? const NoopCrashReporter() : const SentryCrashReporter(sentryDsn);
