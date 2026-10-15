import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/crash/crash_reporter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reporter = crashReporterFromEnvironment();
  // Sentry installs its own handlers; the no-op reporter just logs.
  if (reporter is NoopCrashReporter) {
    FlutterError.onError = (d) {
      FlutterError.presentError(d);
      reporter.record(d.exception, d.stack);
    };
  }
  await reporter.run(() => ProviderScope(child: TerraApp()));
}
