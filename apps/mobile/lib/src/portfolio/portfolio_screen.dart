import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../leases/leases_screen.dart' show money;
import 'portfolio_repository.dart';

final portfolioOrgsProvider = FutureProvider.autoDispose<List<PortfolioOrg>>(
  (ref) => ref.watch(portfolioRepositoryProvider).orgs(),
);

final portfolioProvider = FutureProvider.autoDispose.family<PortfolioDashboard, String>(
  (ref, orgId) => ref.watch(portfolioRepositoryProvider).dashboard(orgId),
);

Color bandColor(RiskBand? b) => switch (b) {
      RiskBand.low => const Color(0xFF10B981),
      RiskBand.medium => const Color(0xFFF59E0B),
      RiskBand.high => const Color(0xFFEF4444),
      _ => Colors.grey,
    };

String bandText(AppLocalizations t, RiskBand? b) => switch (b) {
      RiskBand.low => t.riskLow,
      RiskBand.medium => t.riskMedium,
      RiskBand.high => t.riskHigh,
      _ => t.riskNone,
    };

String attentionText(AppLocalizations t, PortfolioAttentionKindEnum k) => switch (k) {
      PortfolioAttentionKindEnum.escalation => t.attentionEscalation,
      PortfolioAttentionKindEnum.debt => t.attentionDebt,
      PortfolioAttentionKindEnum.ending => t.attentionEnding,
      PortfolioAttentionKindEnum.notice => t.attentionNotice,
      PortfolioAttentionKindEnum.vacant => t.attentionVacant,
      _ => t.attentionHighRisk,
    };

/// A risk score with its band.
class RiskChip extends StatelessWidget {
  const RiskChip({super.key, this.score, this.band});

  final int? score;
  final RiskBand? band;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = bandColor(band);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(score == null ? t.riskNone : '$score · ${bandText(t, band)}',
          style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// Portfolio overview: weighted risk, cards per municipality and what needs
/// attention. Read-only; changes happen in the web admin.
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  String? orgId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final orgs = ref.watch(portfolioOrgsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.portfolioTitle)),
      body: orgs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(t.statusUnreachable)),
        data: (list) {
          if (list.isEmpty) return Center(child: Text(t.portfolioEmpty));
          final id = orgId ?? list.first.id;
          return Column(children: [
            if (list.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: id,
                  items: [for (final o in list) DropdownMenuItem(value: o.id, child: Text(o.name))],
                  onChanged: (v) => setState(() => orgId = v),
                ),
              ),
            Expanded(child: _Dashboard(orgId: id)),
          ]);
        },
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dash = ref.watch(portfolioProvider(orgId));
    return dash.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(t.portfolioEmpty)),
      data: (d) => RefreshIndicator(
        onRefresh: () => ref.refresh(portfolioProvider(orgId).future),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: ListTile(
              title: Text(t.portfolioWeighted),
              subtitle: Text(t.portfolioIncome(money(d.received, locale), money(d.expected, locale))),
              trailing: RiskChip(score: d.weightedRisk, band: d.band),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(t.portfolioCities, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final c in d.cities)
            Card(
              key: ValueKey('city-${c.name}'),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: bandColor(c.band), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(c.name.isEmpty ? t.portfolioUnknownCity : c.name),
                subtitle: Text(t.portfolioCityLine(c.leases, money(c.monthly, locale), (c.share * 100).round(),
                    money(c.debt, locale))),
                trailing: RiskChip(score: c.weightedRisk, band: c.band),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(t.portfolioAttention, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (d.attention.isEmpty) Text(t.portfolioNothing),
          for (final a in d.attention)
            ListTile(
              dense: true,
              leading: Icon(Icons.warning_amber, color: a.severity >= 3 ? Colors.red : Colors.orange),
              title: Text(attentionText(t, a.kind)),
              subtitle: Text('${a.label} · ${a.city}'),
              trailing: a.amount == null ? null : Text(money(a.amount!, locale)),
            ),
        ]),
      ),
    );
  }
}
