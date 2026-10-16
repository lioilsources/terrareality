import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import 'status_repository.dart';

/// "About": the app name and the platform status (reached from Profile).
class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final status = ref.watch(platformStatusProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.about)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(platformStatusProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(t.appName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(t.statusTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            status.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Unreachable(onRetry: () => ref.invalidate(platformStatusProvider)),
              data: (s) => s.reachable
                  ? _StatusBody(status: s)
                  : _Unreachable(onRetry: () => ref.invalidate(platformStatusProvider)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Dot(color: Theme.of(context).colorScheme.error, label: t.statusUnreachable),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: Text(t.retry)),
      ],
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.status});
  final PlatformStatus status;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final health = status.health!;
    final ok = health.status == HealthStatusEnum.ok;
    final labels = {
      'database': t.checkDatabase,
      'worker': t.checkWorker,
      'centrifugo': t.checkCentrifugo,
      'vision': t.checkVision,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Dot(
          key: const Key('overall-status'),
          color: ok ? Colors.green : Colors.orange,
          label: ok ? t.statusOk : t.statusDegraded,
        ),
        if (status.version != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${status.version!.version} · ${t.schemaVersion(status.version!.schemaVersion.toString())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 12),
        for (final e in orderedChecks(health))
          Card(
            child: ListTile(
              leading: Icon(Icons.circle, size: 12, color: _color(e.value.status)),
              title: Text(labels[e.key] ?? e.key),
              trailing: Text(_stateLabel(t, e.value)),
            ),
          ),
      ],
    );
  }

  Color _color(HealthCheckStatusEnum s) => switch (s) {
        HealthCheckStatusEnum.ok => Colors.green,
        HealthCheckStatusEnum.fail => Colors.red,
        _ => Colors.grey,
      };

  String _stateLabel(AppLocalizations t, HealthCheck c) {
    final base = switch (c.status) {
      HealthCheckStatusEnum.ok => t.stateOk,
      HealthCheckStatusEnum.fail => t.stateFail,
      _ => t.stateDisabled,
    };
    return c.latencyMs != null ? '$base · ${c.latencyMs} ms' : base;
  }
}

class _Dot extends StatelessWidget {
  const _Dot({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      );
}
