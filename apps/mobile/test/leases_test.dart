import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/app.dart';
import 'package:terrareality/src/leases/leases_repository.dart';
import 'package:terrareality/src/leases/payments_repository.dart';

LeaseSummary _summary(LeaseState state) => LeaseSummary(
      id: 'l1',
      orgId: 'o1',
      orgName: 'Lucie Pronajímatelka',
      code: 2600000007,
      state: state,
      origin: LeaseOrigin.platform,
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
  var signCalls = 0;
  Object? signError;
  Uri? redirect;
  final signedWith = <SignProviderIdEnum>[];
  int loads = 0;

  /// The server's enabled signature methods (LeaseDetail.sign_providers).
  List<SignProvider> providers = [SignProvider(id: SignProviderIdEnum.mock, level: SignProviderLevelEnum.simple)];

  @override
  Future<List<LeaseSummary>> mine() async => [_summary(state)];

  @override
  Future<LeaseView> lease(String id) async {
    loads++;
    return _view();
  }

  LeaseView _view() => LeaseView(
        LeaseDetail(
          lease: _summary(state),
          landlordView: false,
          payeeIban: 'CZ65 0800 0000 1920 0014 5399',
          payeeName: 'Lucie',
          dueDay: 15,
          noticeMonths: 3,
          depositAmount: 4000000,
          servicesAmount: 400000,
          depositHeld: false,
          clauses: [],
          parties: [
            LeaseParty(id: 'p1', role: LeasePartyRoleEnum.coTenant, name: 'Anna', shareBps: 5000, position: 1, me: true, hasAccount: true,
                signedAt: signed ? DateTime(2026, 10, 14) : null),
            // Another tenant's e-mail is not shown to a tenant-side caller.
            LeaseParty(id: 'p2', role: LeasePartyRoleEnum.coTenant, name: 'Petr', shareBps: 5000, position: 2, me: false, hasAccount: true),
          ],
          documents: [],
          totalDebt: signed ? 1200000 : 0,
          signProviders: providers,
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
  Future<SignOutcome> sign(String id, SignProviderIdEnum provider) async {
    signCalls++;
    signedWith.add(provider);
    if (signError != null) throw signError!;
    if (redirect != null) return SignOutcome(signed: false, redirect: redirect);
    signed = true;
    state = LeaseState.signed;
    return const SignOutcome(signed: true);
  }
}

class NoCardPayments implements PaymentsRepository {
  @override
  Future<CardPayment?> cardPayment(String shareId) async => null;

  @override
  Future<PaymentLink> createLink(String shareId) => throw UnimplementedError();
}

void main() {
  testWidgets('a tenant signs and sees what to pay with a QR code', (tester) async {
    final repo = FakeRepo();
    final router = createRouter()..go('/smlouvy');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        leasesRepositoryProvider.overrideWithValue(repo),
        paymentsRepositoryProvider.overrideWithValue(NoCardPayments()),
      ],
      child: TerraApp(locale: const Locale('cs'), router: router),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Dejvická 12, Praha 6'), findsOneWidget);
    await tester.tap(find.text('Dejvická 12, Praha 6'));
    await tester.pumpAndSettle();
    expect(find.text('Auditní řetězec je neporušený.'), findsOneWidget);
    expect(find.text('Způsob podpisu: prostý elektronický podpis'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sign-lease')));
    await tester.pumpAndSettle();
    // A confirmation names the address and the method before anything is signed.
    expect(find.text('Podepsat smlouvu?'), findsOneWidget);
    expect(find.textContaining('prostý elektronický podpis. Podpis je právně závazný.'), findsOneWidget);
    expect(repo.signCalls, 0);
    await tester.tap(find.byKey(const Key('confirm-sign')));
    await tester.pumpAndSettle();
    expect(repo.signed, isTrue);
    expect(find.text('Smlouva je podepsaná.'), findsOneWidget);
    expect(find.text('Co mám zaplatit'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Zaplaceno'), findsOneWidget); // the deposit is in the history
    expect(find.textContaining('Po splatnosti'), findsOneWidget);
  });
}
