import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import 'leases_repository.dart';

final myLeasesProvider = FutureProvider.autoDispose<List<LeaseSummary>>(
  (ref) => ref.watch(leasesRepositoryProvider).mine(),
);

final leaseProvider = FutureProvider.autoDispose.family<LeaseView, String>(
  (ref, id) => ref.watch(leasesRepositoryProvider).lease(id),
);

String money(int minor, String locale) => '${NumberFormat.decimalPattern(locale).format(minor ~/ 100)} Kč';

String stateText(AppLocalizations t, LeaseState s) => switch (s) {
      LeaseState.proposed => t.leaseProposed,
      LeaseState.signed => t.leaseSigned,
      LeaseState.active => t.leaseActive,
      LeaseState.noticeGiven => t.leaseNotice,
      LeaseState.terminated || LeaseState.settled => t.leaseEnded,
      _ => t.leaseDraft,
    };

/// The tenant's leases.
class LeasesScreen extends ConsumerWidget {
  const LeasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final list = ref.watch(myLeasesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.leasesTitle)),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(t.statusUnreachable)),
        data: (items) => items.isEmpty
            ? Center(child: Text(t.leasesEmpty))
            : ListView(children: [
                for (final l in items)
                  ListTile(
                    title: Text(l.propertyAddress),
                    subtitle: Text('${l.orgName ?? ''} · ${stateText(t, l.state)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/smlouvy/${l.id}'),
                  ),
              ]),
      ),
    );
  }
}

/// One lease: state, what I pay (with QR Platba) and the payment history.
class LeaseScreen extends ConsumerWidget {
  const LeaseScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMd(locale);
    final view = ref.watch(leaseProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(t.leaseTitle)),
      body: view.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(t.statusUnreachable)),
        data: (v) {
          final l = v.detail.lease;
          final me = v.detail.parties.where((p) => p.me).firstOrNull;
          final mine = v.shares.where((s) => s.mine).toList();
          final open = mine.where((s) => s.paidAmount < s.amount).toList();
          final paid = mine.where((s) => s.paidAmount >= s.amount).toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(l.propertyAddress, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${t.leaseCode}: ${l.code} · ${stateText(t, l.state)}'),
            Text(v.detail.totalDebt > 0 ? '${t.leaseDebt}: ${money(v.detail.totalDebt, locale)}' : t.leaseNoDebt,
                key: const Key('debt')),
            Text(v.chainValid ? t.leaseChainOk : t.leaseChainBroken,
                style: TextStyle(color: v.chainValid ? Colors.green.shade700 : Colors.red)),
            if (l.state == LeaseState.proposed && me != null && me.signedAt == null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await ref.read(leasesRepositoryProvider).sign(id);
                  ref.invalidate(leaseProvider(id));
                },
                child: Text(t.leaseSign),
              ),
            ],
            if (open.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(t.leaseToPay, style: Theme.of(context).textTheme.titleMedium),
              for (final s in open)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${date.format(s.dueOn)} · ${s.period.isEmpty ? t.leaseDeposit : s.period}'),
                      Text(money(s.amount - s.paidAmount, locale), style: Theme.of(context).textTheme.titleMedium),
                      if (s.spayd != null)
                        Center(child: QrImageView(key: Key('qr-${s.id}'), data: s.spayd!, size: 180)),
                    ]),
                  ),
                ),
            ],
            if (paid.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(t.leaseHistory, style: Theme.of(context).textTheme.titleMedium),
              for (final s in paid)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text('${s.period.isEmpty ? t.leaseDeposit : s.period} · ${money(s.amount, locale)}'),
                  subtitle: Text(date.format(s.dueOn)),
                ),
            ],
            const SizedBox(height: 12),
            Text(t.leaseMoneyNote, style: Theme.of(context).textTheme.bodySmall),
          ]);
        },
      ),
    );
  }
}
