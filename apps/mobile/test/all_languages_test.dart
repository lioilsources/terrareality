import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/l10n/gen/app_localizations.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/status/status_repository.dart';

/// The 45 UI languages (BCP 47). `pt`/`zh` ARBs hold pt-BR / zh-Hans; Portuguese (Portugal) and
/// Traditional Chinese are their own files.
const _languages = [
  'cs',
  'en',
  'ar',
  'bn',
  'ca',
  'da',
  'de',
  'el',
  'es',
  'fi',
  'fr',
  'gu',
  'he',
  'hi',
  'hr',
  'hu',
  'id',
  'it',
  'ja',
  'kn',
  'ko',
  'ml',
  'mr',
  'ms',
  'nb',
  'nl',
  'or',
  'pa',
  'pl',
  'pt',
  'pt_PT',
  'ro',
  'ru',
  'sk',
  'sl',
  'sv',
  'ta',
  'te',
  'th',
  'tr',
  'uk',
  'ur',
  'vi',
  'zh',
  'zh_Hant',
];
const _rtl = {'ar', 'he', 'ur'};

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String s) =>
    RegExp(r'\{([A-Za-z]\w*)[},]').allMatches(s).map((m) => m.group(1)!).toSet();

Locale _locale(String code) {
  final parts = code.split('_');
  return parts.length == 1
      ? Locale(parts[0])
      : Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
}

void main() {
  test('every language has exactly the template keys and placeholders', () {
    final template = _arb('cs');
    final keys = template.keys.where((k) => !k.startsWith('@')).toList();
    expect(keys.length, greaterThan(200));
    for (final code in _languages) {
      final arb = _arb(code);
      if (code != 'cs' && code != 'en') {
        expect(
          arb.keys.where((k) => k.startsWith('@') && k != '@@locale'),
          isEmpty,
          reason: '$code: metadata belongs in the template only',
        );
      }
      for (final k in keys) {
        final v = arb[k];
        expect(v, isA<String>(), reason: '$code is missing $k');
        expect((v as String).trim(), isNotEmpty, reason: '$code/$k is empty');
        expect(
          _placeholders(v),
          _placeholders(template[k] as String),
          reason: '$code/$k placeholders',
        );
      }
      expect(
        arb.keys.where((k) => !k.startsWith('@')).length,
        keys.length,
        reason: '$code has extra keys',
      );
    }
  });

  test(
    'no language but Czech keeps the Czech template text for user-facing sentences',
    () {
      final template = _arb('cs');
      for (final code in _languages.where((c) => c != 'cs' && c != 'sk')) {
        final arb = _arb(code);
        final same = [
          for (final e in template.entries)
            if (!e.key.startsWith('@') &&
                (e.value as String).length > 25 &&
                arb[e.key] == e.value)
              e.key,
        ];
        expect(same, isEmpty, reason: '$code still has Czech text: $same');
      }
    },
  );

  test('supportedLocales lists all 45 languages', () {
    final supported = AppLocalizations.supportedLocales
        .map((l) => l.toLanguageTag())
        .toSet();
    expect(supported.length, 45);
    expect(
      supported,
      containsAll([
        'pt',
        'pt-PT',
        'zh',
        'zh-Hant',
        'ar',
        'he',
        'ur',
        'nb',
        'or',
      ]),
    );
  });

  for (final code in _languages) {
    testWidgets('renders the status screen in $code', (tester) async {
      final locale = _locale(code);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            platformStatusProvider.overrideWith(
              (ref) async => PlatformStatus(
                health: Health(
                  status: HealthStatusEnum.ok,
                  checks: {
                    'database': HealthCheck(
                      status: HealthCheckStatusEnum.ok,
                      latencyMs: 2,
                    ),
                  },
                ),
              ),
            ),
          ],
          child: TerraApp(
            locale: locale,
            router: createRouter(initialLocation: '/stav'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = lookupAppLocalizations(locale);
      expect(find.text(t.statusOk), findsOneWidget);
      expect(tester.takeException(), isNull);
      final dir = Directionality.of(tester.element(find.text(t.statusOk)));
      expect(
        dir,
        _rtl.contains(locale.languageCode)
            ? TextDirection.rtl
            : TextDirection.ltr,
      );
    });
  }
}
