import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../l10n/gen/app_localizations.dart';
import 'applications/applications_screen.dart';
import 'auth/link_screens.dart';
import 'auth/login_screen.dart';
import 'auth/session.dart' show MfaRequired;
import 'leases/leases_screen.dart';
import 'messaging/conversations_screen.dart';
import 'messaging/thread_screen.dart';
import 'portfolio/portfolio_screen.dart';
import 'profile/profile_screen.dart';
import 'push/push_registrar.dart';
import 'search/listing_screen.dart';
import 'search/search_screen.dart';
import 'status/status_screen.dart';
import 'viewings/viewings_screen.dart';

/// App routes. The same paths as the web, so App Links / Universal Links
/// (https://terrareality.cz/zpravy/{id}, /zadosti/{id}, /smlouvy/{id},
/// /inzerat/{id}, /prohlidky, and the e-mail links /auth/magic?token= and
/// /auth/reset?token=; see AndroidManifest.xml and Runner.entitlements) open
/// the matching screen: Flutter hands the URL to the router, which matches on
/// the path. Anything else falls back to search.
GoRouter createRouter({String initialLocation = '/hledat'}) => GoRouter(
  initialLocation: initialLocation,
  onException: (_, state, router) => router.go('/hledat'),
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/hledat'),
    ShellRoute(
      builder: (_, state, child) => HomeShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/hledat', pageBuilder: (_, _) => const NoTransitionPage(child: SearchScreen())),
        GoRoute(path: '/zpravy', pageBuilder: (_, _) => const NoTransitionPage(child: ConversationsScreen())),
        GoRoute(path: '/zadosti', pageBuilder: (_, _) => const NoTransitionPage(child: ApplicationsScreen())),
        GoRoute(path: '/smlouvy', pageBuilder: (_, _) => const NoTransitionPage(child: LeasesScreen())),
        GoRoute(path: '/profil', pageBuilder: (_, _) => const NoTransitionPage(child: ProfileScreen())),
      ],
    ),
    GoRoute(path: '/stav', builder: (_, _) => const StatusScreen()),
    GoRoute(
      path: '/login',
      builder: (_, s) => LoginScreen(
        next: s.uri.queryParameters['next'],
        // A sign-in link that needs the second factor (never from a URL).
        mfaToken: s.extra is MfaRequired ? (s.extra! as MfaRequired).mfaToken : null,
      ),
    ),
    GoRoute(
      path: magicLinkPath,
      builder: (_, s) => MagicLinkScreen(token: s.uri.queryParameters['token'] ?? ''),
    ),
    GoRoute(
      path: resetPasswordPath,
      builder: (_, s) => ResetPasswordScreen(token: s.uri.queryParameters['token'] ?? ''),
    ),
    GoRoute(
      path: '/inzerat/:id',
      builder: (_, s) => ListingScreen(id: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/zpravy/:id',
      builder: (_, s) => ThreadScreen(id: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/prohlidky',
      builder: (_, s) => ViewingsScreen(cancelledApplicationId: s.uri.queryParameters['zruseno']),
    ),
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

/// Bottom navigation of the seeker/tenant app. Admin features stay on the web.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const tabs = ['/hledat', '/zpravy', '/zadosti', '/smlouvy', '/profil'];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final index = tabs.indexWhere((p) => location.startsWith(p));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(tabs[i]),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.search), label: t.navSearch),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), label: t.navMessages),
          NavigationDestination(icon: const Icon(Icons.assignment_outlined), label: t.navApplications),
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: t.navLease),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: t.navProfile),
        ],
      ),
    );
  }
}

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
      builder: (_, child) => PushNavigation(router: router, child: child ?? const SizedBox.shrink()),
    );
  }
}
