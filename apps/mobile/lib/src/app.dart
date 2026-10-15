import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../l10n/gen/app_localizations.dart';
import 'applications/applications_screen.dart';
import 'auth/login_screen.dart';
import 'leases/leases_screen.dart';
import 'messaging/conversations_screen.dart';
import 'messaging/thread_screen.dart';
import 'portfolio/portfolio_screen.dart';
import 'status/status_screen.dart';

GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const StatusScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/zpravy', builder: (_, _) => const ConversationsScreen()),
    GoRoute(
      path: '/zpravy/:id',
      builder: (_, s) => ThreadScreen(id: s.pathParameters['id']!),
    ),
    GoRoute(path: '/zadosti', builder: (_, _) => const ApplicationsScreen()),
    GoRoute(path: '/smlouvy', builder: (_, _) => const LeasesScreen()),
    GoRoute(path: '/portfolio', builder: (_, _) => const PortfolioScreen()),
    GoRoute(
      path: '/smlouvy/:id',
      builder: (_, s) => LeaseScreen(id: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/zadosti/:id',
      builder: (_, s) => ApplicationScreen(id: s.pathParameters['id']!),
    ),
  ],
);

const _seed = Color(0xFF2F7D4F);

class TerraApp extends StatelessWidget {
  TerraApp({super.key, this.locale, GoRouter? router}) : router = router ?? createRouter();

  /// Forces a locale (tests, user preference); null follows the device.
  final Locale? locale;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      theme: ThemeData(colorSchemeSeed: _seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark, useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: router,
    );
  }
}
