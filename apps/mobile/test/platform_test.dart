import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/api/api_provider.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/common/money.dart';
import 'package:terrareality/src/crash/crash_reporter.dart';
import 'package:terrareality/src/search/listing_map.dart';
import 'package:terrareality/src/search/search_repository.dart';

import 'fakes.dart';

String _plain(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');

void main() {
  group('money', () {
    test('keeps haléře and drops ",00" for whole amounts', () {
      expect(_plain(money(1850000, 'cs')), '18 500 Kč');
      expect(_plain(money(1850050, 'cs')), '18 500,50 Kč');
      expect(_plain(money(99, 'cs')), '0,99 Kč');
    });

    test('uses the currency from the API', () {
      expect(_plain(money(120000, 'cs', currency: 'EUR')), '1 200 €');
      expect(_plain(money(120050, 'en', currency: 'EUR')), '€1,200.50');
      expect(money(500000, 'cs', currency: 'PLN'), isNot(contains('Kč')));
    });
  });

  group('API URL', () {
    test('debug falls back to the local API', () {
      expect(defaultApiUrl(release: false, fromEnv: ''), startsWith('http://'));
    });

    test('release without API_URL refuses to start', () {
      expect(() => defaultApiUrl(release: true, fromEnv: ''), throwsStateError);
      expect(() => defaultApiUrl(release: true, fromEnv: 'http://localhost:8080'), throwsStateError);
      expect(defaultApiUrl(release: true, fromEnv: 'https://api.terrareality.cz'), 'https://api.terrareality.cz');
    });
  });

  group('crash reports', () {
    test('API response bodies never reach Sentry', () {
      final err = ApiException(422, '{"detail":"Anna Nováková, +420 777 123 456"}');
      final event = SentryEvent(
        exceptions: [SentryException(type: 'ApiException', value: err.toString(), throwable: err)],
        breadcrumbs: [Breadcrumb(message: 'failed: ${err.toString()}')],
        message: SentryMessage('ApiException 422: {"detail":"Anna"}'),
      );
      final out = scrubEvent(event);
      expect(out.exceptions!.single.value, 'ApiException(422)');
      expect(out.breadcrumbs!.single.message, isNot(contains('Anna')));
      expect(out.message!.formatted, isNot(contains('Anna')));
      expect(describeError(err), 'ApiException(422)');
    });
  });

  group('deep links', () {
    test('web URLs map to app screens; other paths fall back to search', () async {
      final router = createRouter();
      for (final path in ['/zpravy/c1', '/zadosti/a1', '/smlouvy/l1', '/inzerat/x1', '/prohlidky', '/profil']) {
        expect(router.configuration.findMatch(Uri.parse('https://terrareality.cz$path')).isNotEmpty, isTrue,
            reason: path);
      }
    });

    testWidgets('an unknown link opens search instead of an error page', (tester) async {
      final router = createRouter(initialLocation: '/admin/nastaveni');
      await tester.pumpWidget(ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(FakeSearch()),
          listingMapProvider.overrideWithValue(FakeMap()),
        ],
        child: TerraApp(locale: const Locale('cs'), router: router),
      ));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/hledat');
    });
  });
}
