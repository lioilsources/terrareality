// Acceptance M5 against a running api (dev stack with `terractl seed-dev`):
// a viewing is booked through the app's own repository code.
//   flutter test test/live_booking_test.dart --dart-define=LIVE_API_URL=http://localhost:8080
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:terra_api/api.dart';
import 'package:terrareality/src/applications/applications_repository.dart';

const liveUrl = String.fromEnvironment('LIVE_API_URL');
const devPassword = 'terra-dev-password';

Future<dynamic> call(String method, String path, {String? token, Object? body}) async {
  final req = http.Request(method, Uri.parse('$liveUrl$path'));
  req.headers['Content-Type'] = 'application/json';
  if (token != null) req.headers['Authorization'] = 'Bearer $token';
  if (body != null) req.body = jsonEncode(body);
  final res = await http.Response.fromStream(await req.send());
  if (res.statusCode >= 300) fail('$method $path: ${res.statusCode} ${res.body}');
  return res.body.isEmpty ? null : jsonDecode(res.body);
}

Future<String> login(String email) async =>
    (await call('POST', '/v1/auth/login', body: {'email': email, 'password': devPassword}))['session']['token'] as String;

ApiApplicationsRepository repoFor(String token) {
  final auth = HttpBearerAuth()..accessToken = token;
  return ApiApplicationsRepository(ApplicationsApi(ApiClient(basePath: liveUrl, authentication: auth)));
}

void main() {
  test('seeker books a viewing with the app repository', () async {
    final owner = await login('owner@terra.local');
    final staff = await login('staff@terra.local');
    final me = await call('GET', '/v1/me', token: owner);
    final org = me['organizations'][0]['organization']['id'] as String;

    // A published flat with one viewing slot.
    final addr = (await call('GET', '/v1/addresses/search?q=dejvick', token: owner))[0]['ruian_id'];
    final l = await call('POST', '/v1/orgs/$org/listings',
        token: owner, body: {'ruian_id': addr, 'unit_kind': 'apartment', 'layout': '2+kk', 'floor_area': 50});
    final path = '/v1/orgs/$org/listings/${l['id']}';
    await call('PUT', path, token: owner, body: {
      'title': {'cs': 'Flutter prohlídka ${DateTime.now().millisecondsSinceEpoch}', 'en': ''},
      'description': {'cs': 'Byt pro test rezervace prohlídky z mobilní aplikace, světlý a tichý.', 'en': ''},
      'rent_amount': 2000000,
      'attributes': l['attributes'],
      'location_precision': 'approximate',
    });
    final photo = await File('../web/e2e/fixtures/flat.jpg').readAsBytes();
    final up = await call('POST', '$path/media',
        token: owner, body: {'filename': 'flat.jpg', 'content_type': 'image/jpeg', 'size': photo.length});
    await http.put(Uri.parse(up['upload_url'] as String), headers: {'Content-Type': 'image/jpeg'}, body: photo);
    await call('POST', '/v1/orgs/$org/media/${up['media']['id']}/complete', token: owner);
    for (var i = 0; i < 60; i++) {
      final media = (await call('GET', path, token: owner))['media'] as List;
      if (media.isNotEmpty && media.first['status'] == 'ready') break;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    await call('POST', '$path/submit', token: owner);
    final queue = await call('GET', '/v1/backoffice/reviews', token: staff) as List;
    final version = queue.firstWhere((q) => q['listing_id'] == l['id'])['version_id'];
    await call('POST', '/v1/backoffice/reviews/$version/decision', token: staff, body: {'approve': true});
    final slot = await call('POST', '$path/viewing-slots', token: owner, body: {
      'starts_at': DateTime.now().toUtc().add(const Duration(days: 3)).toIso8601String(),
      'note': 'Zvonek Flutter',
    });

    // A new seeker applies; the booking goes through the app's repository.
    final email = 'flutter-${DateTime.now().microsecondsSinceEpoch}@example.com';
    final reg = await call('POST', '/v1/auth/register', body: {
      'email': email, 'password': 'Flutter-pass-123', 'display_name': 'Flutter Seeker',
      'accept_terms_version': '2026-10', 'accept_privacy_version': '2026-10', 'client': 'mobile',
    });
    final seeker = reg['session']['token'] as String;
    final app = await call('POST', '/v1/applications', token: seeker, body: {'listing_id': l['id']});
    final appId = app['application']['id'] as String;

    final repo = repoFor(seeker);
    final before = await repo.detail(appId);
    expect(before.slots.map((s) => s.id), contains(slot['id']));
    final bookingId = await repo.book(appId, slot['id'] as String);
    final after = await repo.detail(appId);
    expect(after.booking?.id, bookingId);
    expect(after.booking?.note, 'Zvonek Flutter');
    final mine = await repo.mine();
    expect(mine.map((a) => a.id), contains(appId));
  }, skip: liveUrl.isEmpty ? 'LIVE_API_URL not set' : null, timeout: const Timeout(Duration(minutes: 2)));
}
