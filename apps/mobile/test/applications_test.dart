import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/applications/applications_repository.dart';

Application _app(ApplicationStatus status) => Application(
      id: 'a1',
      listingId: 'l1',
      orgId: 'o1',
      listingTitle: I18nText(cs: 'Byt 3+1 Dejvice', en: ''),
      status: status,
      householdSize: 3,
      consentNeeded: false,
      createdAt: DateTime(2026, 10, 14),
    );

class FakeRepo implements ApplicationsRepository {
  final booked = <String>[];
  Viewing? booking;

  @override
  Future<List<Application>> mine() async => [_app(ApplicationStatus.invited)];

  @override
  Future<ApplicationDetail> detail(String id) async => ApplicationDetail(
        application: _app(ApplicationStatus.invited),
        consents: [],
        booking: booking,
        slots: [
          ViewingSlot(id: 's1', startsAt: DateTime.utc(2026, 10, 20, 15), durationMin: 20, capacity: 1, booked: 0,
              note: 'Zvonek Novák', bookings: []),
          ViewingSlot(id: 's2', startsAt: DateTime.utc(2026, 10, 21, 15), durationMin: 20, capacity: 1, booked: 1,
              note: '', bookings: []),
        ],
      );

  @override
  Future<String> book(String applicationId, String slotId) async {
    booked.add(slotId);
    booking = Viewing(id: 'b1', applicationId: applicationId, listingId: 'l1',
        listingTitle: I18nText(cs: 'Byt 3+1 Dejvice', en: ''), startsAt: DateTime.utc(2026, 10, 20, 15),
        durationMin: 20, note: 'Zvonek Novák');
    return 'b1';
  }

  @override
  Future<void> cancel(String bookingId) async => booking = null;

  @override
  Future<void> consent(String applicationId) async {}
}

void main() {
  testWidgets('a seeker books a viewing from the app', (tester) async {
    final repo = FakeRepo();
    final router = createRouter()..go('/zadosti');
    await tester.pumpWidget(ProviderScope(
      overrides: [applicationsRepositoryProvider.overrideWithValue(repo)],
      child: TerraApp(locale: const Locale('cs'), router: router),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Byt 3+1 Dejvice'), findsOneWidget);
    expect(find.text('Pozvánka na prohlídku'), findsOneWidget);

    await tester.tap(find.text('Byt 3+1 Dejvice'));
    await tester.pumpAndSettle();
    expect(find.text('obsazeno'), findsOneWidget); // the full slot cannot be booked
    expect(find.text('Rezervovat'), findsOneWidget);

    await tester.tap(find.text('Rezervovat'));
    await tester.pumpAndSettle();
    expect(repo.booked, ['s1']);
    expect(find.byKey(const Key('booking')), findsOneWidget);
    expect(find.text('Prohlídka je rezervovaná.'), findsOneWidget);
  });
}
