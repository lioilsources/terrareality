import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../api/api_provider.dart';

/// Snapshot of /healthz and /v1/version. `health == null` means unreachable.
class PlatformStatus {
  const PlatformStatus({this.health, this.version});
  final Health? health;
  final Version? version;

  bool get reachable => health != null;
}

/// Display order of known checks; unknown ones follow alphabetically.
const checkOrder = ['database', 'worker', 'centrifugo', 'vision'];

List<MapEntry<String, HealthCheck>> orderedChecks(Health health) {
  final entries = health.checks.entries.toList();
  int rank(String n) {
    final i = checkOrder.indexOf(n);
    return i == -1 ? checkOrder.length : i;
  }

  entries.sort((a, b) {
    final r = rank(a.key).compareTo(rank(b.key));
    return r != 0 ? r : a.key.compareTo(b.key);
  });
  return entries;
}

final platformStatusProvider = FutureProvider.autoDispose<PlatformStatus>((ref) async {
  final api = ref.watch(systemApiProvider);
  try {
    // /healthz returns 503 with a body when degraded, so parse it manually.
    final res = await api.getHealthWithHttpInfo();
    final health = res.body.isEmpty ? null : Health.fromJson(jsonDecode(res.body));
    Version? version;
    try {
      version = await api.getVersion();
    } catch (_) {}
    return PlatformStatus(health: health, version: version);
  } catch (_) {
    return const PlatformStatus();
  }
});
