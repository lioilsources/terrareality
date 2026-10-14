// Contract check of the generated Dart client against a running Go api.
// Skipped unless LIVE_API_URL is set, e.g.:
//   flutter test test/live_api_test.dart --dart-define=LIVE_API_URL=http://localhost:8080
// Uses plain `test` (no widget binding), so real HTTP is allowed.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';

const liveUrl = String.fromEnvironment('LIVE_API_URL');

void main() {
  final skip = liveUrl.isEmpty ? 'LIVE_API_URL not set' : null;

  test('healthz body parses into Health (200 and 503 share the schema)', () async {
    final api = SystemApi(ApiClient(basePath: liveUrl));
    final res = await api.getHealthWithHttpInfo();
    expect(res.statusCode, anyOf(200, 503));
    final health = Health.fromJson(jsonDecode(res.body));
    expect(health, isNotNull);
    expect(health!.checks.keys, containsAll(['database', 'worker']));
  }, skip: skip);

  test('version parses into Version', () async {
    final v = await SystemApi(ApiClient(basePath: liveUrl)).getVersion();
    expect(v, isNotNull);
    expect(v!.schemaVersion, greaterThanOrEqualTo(1));
  }, skip: skip);
}
