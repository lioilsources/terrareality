import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/status/status_repository.dart';

Health _health(HealthStatusEnum status) => Health(
      status: status,
      checks: {
        'vision': HealthCheck(status: HealthCheckStatusEnum.disabled),
        'database': HealthCheck(status: HealthCheckStatusEnum.ok, latencyMs: 2),
      },
    );

Widget _app(PlatformStatus s) => ProviderScope(
      overrides: [platformStatusProvider.overrideWith((ref) async => s)],
      child: TerraApp(locale: const Locale('cs'), router: createRouter(initialLocation: '/stav')),
    );

void main() {
  test('orderedChecks puts known checks first', () {
    final names = orderedChecks(_health(HealthStatusEnum.ok)).map((e) => e.key).toList();
    expect(names, ['database', 'vision']);
  });

  testWidgets('shows healthy status', (tester) async {
    await tester.pumpWidget(_app(PlatformStatus(health: _health(HealthStatusEnum.ok))));
    await tester.pumpAndSettle();
    expect(find.text('Vše v pořádku'), findsOneWidget);
    expect(find.text('Databáze'), findsOneWidget);
  });

  testWidgets('shows unreachable state with retry', (tester) async {
    await tester.pumpWidget(_app(const PlatformStatus()));
    await tester.pumpAndSettle();
    expect(find.text('API není dostupné'), findsOneWidget);
    expect(find.text('Zkusit znovu'), findsOneWidget);
  });

  testWidgets('is the About page, without sign-in or internal actions in the app bar', (tester) async {
    await tester.pumpWidget(_app(PlatformStatus(health: _health(HealthStatusEnum.ok))));
    await tester.pumpAndSettle();
    expect(find.text('O aplikaci'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsNothing);
  });
}
