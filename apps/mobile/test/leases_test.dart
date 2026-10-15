import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/leases/leases_repository.dart';

LeaseSummary _summary(LeaseState state) => LeaseSummary(
      id: 'l1',
      orgId: 'o1',
      orgName: 'Lucie Pronajímatelka',
      code: 2600000007,
      state: state,
      template: LeaseTemplate.spolecnyNajem,
      propertyAddress: 'Dejvická 12, Praha 6',
      startsOn: DateTime(2026, 11, 1),
      rentAmount: 2000000,
      currency: 'CZK',
      createdAt: DateTime(2026, 10, 14),
    );

ObligationShare _share(String id, String period, int paid, {String? spayd}) => ObligationShare(
      id: id,
      obligationId: 'o-$id',
      kind: period.isEmpty ? ObligationShareKindEnum.deposit : ObligationShareKindEnum.rent,
      period: period,
      dueOn: DateTime(2026, 11, 15),
      amount: 1200000,
      paidAmount: paid,
      currency: 'CZK',
      partyId: 'p1',
      partyName: 'Anna',
      mine: true,
      status: paid >= 1200000 ? ObligationShareStatusEnum.paid : ObligationShareStatusEnum.open,
      spayd: spayd,
    );

class FakeRepo implements LeasesRepository {
  var state = LeaseState.proposed;
  var signed = false;

  @override
  Future<List<LeaseSummary>> mine() async => [_summary(state)];

  @override
  Future<LeaseView> lease(String id) async => LeaseView(
        LeaseDetail(
          lease: _summary(state),
          landlordView: false,
          payeeIban: 'CZ65 0800 0000 1920 0014 5399',
          payeeName: 'Lucie',
          dueDay: 15,
          noticeMonths: 3,
          depositAmount: 4000000,
          servicesAmount: 400000,
          clauses: [],
          parties: [
            LeaseParty(id: 'p1', role: LeasePartyRoleEnum.coTenant, name: 'Anna', shareBps: 5000, position: 1, me: true,
                signedAt: signed ? DateTime(2026, 10, 14) : null),
          ],
          documents: [],
          totalDebt: signed ? 1200000 : 0,
        ),
        signed
            ? [
                _share('s1', '', 1200000),
                _share('s2', '2026-11', 0, spayd: 'SPD*1.0*ACC:CZ6508000000192000145399*AM:12000.00*CC:CZK*X-VS:2600000007*X-SS:1'),
              ]
            : [],
        true,
      );

  @override
  Future<void> sign(String id) async {
    signed = true;
    state = LeaseState.signed;
  }
}

void main() {
  testWidgets('a tenant signs and sees what to pay with a QR code', (tester) async {
    final repo = FakeRepo();
    final router = createRouter()..go('/smlouvy');
    await tester.pumpWidget(ProviderScope(
      overrides: [leasesRepositoryProvider.overrideWithValue(repo)],
      child: TerraApp(locale: const Locale('cs'), router: router),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Dejvická 12, Praha 6'), findsOneWidget);
    await tester.tap(find.text('Dejvická 12, Praha 6'));
    await tester.pumpAndSettle();
    expect(find.text('Auditní řetězec je neporušený.'), findsOneWidget);
    await tester.tap(find.text('Podepsat'));
    await tester.pumpAndSettle();
    expect(repo.signed, isTrue);
    expect(find.text('Co mám zaplatit'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Zaplaceno'), findsOneWidget); // the deposit is in the history
    expect(find.textContaining('Po splatnosti'), findsOneWidget);
  });
}
