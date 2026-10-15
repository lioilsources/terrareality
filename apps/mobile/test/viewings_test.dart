import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/applications/applications_repository.dart';
import 'package:terrareality/src/viewings/viewings_repository.dart';

Viewing _viewing(String id, String slot) => Viewing(
      id: id,
      applicationId: 'a1',
      listingId: 'l1',
      listingTitle: I18nText(cs: 'Byt 3+1 Dejvice', en: ''),
      city: 'Praha',
      startsAt: DateTime.utc(2026, 10, 20, 15),
      durationMin: 20,
      note: slot,
    );

/// Viewings and applications share the booking state like the API does.
class FakeBookings implements ApplicationsRepository {
  Viewing? booking = _viewing('b1', 'Zvonek Novák');
  final cancelled = <String>[];
  final booked = <String>[];

  Application get _app => Application(
        id: 'a1',
        listingId: 'l1',
        orgId: 'o1',
        listingTitle: I18nText(cs: 'Byt 3+1 Dejvice', en: ''),
        status: ApplicationStatus.invited,
        householdSize: 1,
        consentNeeded: false,
        createdAt: DateTime(2026, 10, 14),
      );

  @override
  Future<List<Application>> mine() async => [_app];

  @override
  Future<void> cancel(String bookingId) async {
    cancelled.add(bookingId);
    booking = null;
  }

  @override
  Future<ApplicationDetail> detail(String id) async => ApplicationDetail(
        application: _app,
        consents: [],
        booking: booking,
        slots: [
          ViewingSlot(id: 's2', startsAt: DateTime.utc(2026, 10, 22, 16), durationMin: 20, capacity: 2, booked: 0,
              note: 'Druhý termín', bookings: []),
        ],
      );

  @override
  Future<String> book(String applicationId, String slotId) async {
    booked.add(slotId);
    booking = _viewing('b2', 'Druhý termín');
    return 'b2';
  }

  @override
  Future<void> consent(String applicationId) async {}
}

class FakeViewings implements ViewingsRepository {
  FakeViewings(this.bookings);

  final FakeBookings bookings;

  @override
  Future<List<Viewing>> mine() async => [?bookings.booking];

  @override
  Future<void> cancel(String bookingId) => bookings.cancel(bookingId);
}

Future<FakeBookings> _pump(WidgetTester tester) async {
  final repo = FakeBookings();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      viewingsRepositoryProvider.overrideWithValue(FakeViewings(repo)),
      applicationsRepositoryProvider.overrideWithValue(repo),
    ],
    child: TerraApp(locale: const Locale('cs'), router: createRouter(initialLocation: '/prohlidky')),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('a seeker cancels a booked viewing', (tester) async {
    final repo = await _pump(tester);
    expect(find.text('Moje prohlídky'), findsOneWidget);
    expect(find.byKey(const Key('viewing-b1')), findsOneWidget);
    expect(find.textContaining('Zvonek Novák'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel-b1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(repo.cancelled, ['b1']);
    expect(find.text('Nemáte domluvenou žádnou prohlídku.'), findsOneWidget);
  });

  testWidgets('a seeker moves the viewing to another slot', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.byKey(const Key('viewing-b1')));
    await tester.pumpAndSettle();
    expect(find.text('Rezervovat'), findsOneWidget);
    await tester.tap(find.text('Rezervovat'));
    await tester.pumpAndSettle();
    expect(repo.booked, ['s2']);

    // pageBack() looks for the English 'Back' tooltip; the app runs in Czech.
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('viewing-b2')), findsOneWidget);
  });
}
