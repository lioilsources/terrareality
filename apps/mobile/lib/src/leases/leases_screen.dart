import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../common/api_error.dart';
import '../common/money.dart';
import '../platform/url_opener.dart';
import 'leases_repository.dart';
import 'payments_repository.dart';

final myLeasesProvider = FutureProvider.autoDispose<List<LeaseSummary>>(
  (ref) => ref.watch(leasesRepositoryProvider).mine(),
);

final leaseProvider = FutureProvider.autoDispose.family<LeaseView, String>(
  (ref, id) => ref.watch(leasesRepositoryProvider).lease(id),
);

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
        error: (e, _) => ApiErrorView(error: e, onRetry: () => ref.invalidate(myLeasesProvider)),
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
        error: (e, _) => ApiErrorView(error: e, onRetry: () => ref.invalidate(leaseProvider(id))),
        data: (v) {
          final l = v.detail.lease;
          String m(int minor, String currency) => money(minor, locale, currency: currency);
          final me = v.detail.parties.where((p) => p.me).firstOrNull;
          final mine = v.shares.where((s) => s.mine).toList();
          final open = mine.where((s) => s.paidAmount < s.amount).toList();
          final paid = mine.where((s) => s.paidAmount >= s.amount).toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(l.propertyAddress, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${t.leaseCode}: ${l.code} · ${stateText(t, l.state)}'),
            Text(v.detail.totalDebt > 0 ? '${t.leaseDebt}: ${m(v.detail.totalDebt, l.currency)}' : t.leaseNoDebt,
                key: const Key('debt')),
            Text(v.chainValid ? t.leaseChainOk : t.leaseChainBroken,
                style: TextStyle(color: v.chainValid ? Colors.green.shade700 : Colors.red)),
            if (l.state == LeaseState.proposed && me != null && me.signedAt == null) ...[
              const SizedBox(height: 12),
              SignLeaseButton(leaseId: id, address: l.propertyAddress, providers: v.detail.signProviders),
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
                      Text(m(s.amount - s.paidAmount, s.currency), style: Theme.of(context).textTheme.titleMedium),
                      if (s.spayd != null) ...[
                        const SizedBox(height: 8),
                        Text(t.payByQr, style: Theme.of(context).textTheme.labelLarge),
                        Center(
                          child: Semantics(
                            image: true,
                            label: t.qrLabel(m(s.amount - s.paidAmount, s.currency)),
                            child: QrImageView(key: Key('qr-${s.id}'), data: s.spayd!, size: 180),
                          ),
                        ),
                      ],
                      RevolutButton(shareId: s.id),
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
                  title: Text('${s.period.isEmpty ? t.leaseDeposit : s.period} · ${m(s.amount, s.currency)}'),
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

/// The label of a signature method, by its legal level.
String signMethodText(AppLocalizations t, SignProvider p) =>
    p.level == SignProviderLevelEnum.qualified ? t.signMethodQualified : t.signMethodSimple;

/// "Sign" with a confirmation naming the address and the signature method.
/// The methods are the server's enabled [providers] in order of preference:
/// one is used as is, several are offered to choose from. A provider that
/// needs its own page opens in the browser (https only).
class SignLeaseButton extends ConsumerStatefulWidget {
  const SignLeaseButton({super.key, required this.leaseId, required this.address, required this.providers});

  final String leaseId;
  final String address;
  final List<SignProvider> providers;

  @override
  ConsumerState<SignLeaseButton> createState() => _SignLeaseButtonState();
}

class _SignLeaseButtonState extends ConsumerState<SignLeaseButton> {
  bool _busy = false;
  SignProviderIdEnum? _chosen;

  /// The chosen method; the first (preferred) one until the user picks.
  SignProvider? get _provider {
    final ps = widget.providers;
    if (ps.isEmpty) return null;
    return ps.where((p) => p.id == _chosen).firstOrNull ?? ps.first;
  }

  Future<void> _sign() async {
    final provider = _provider;
    if (provider == null) return;
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.signConfirmTitle),
        content: Text(t.signConfirmBody(widget.address, signMethodText(t, provider))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
          FilledButton(key: const Key('confirm-sign'), onPressed: () => Navigator.pop(c, true), child: Text(t.leaseSign)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final res = await ref.read(leasesRepositoryProvider).sign(widget.leaseId, provider.id);
      if (res.redirect != null) {
        final opened = await ref.read(urlOpenerProvider).open(res.redirect!);
        messenger.showSnackBar(SnackBar(content: Text(opened ? t.signContinue : t.actionFailed)));
      } else if (res.signed) {
        messenger.showSnackBar(SnackBar(content: Text(t.signDone)));
      }
      ref.invalidate(leaseProvider(widget.leaseId));
      ref.invalidate(myLeasesProvider);
    } catch (e) {
      final code = errorCode(e);
      messenger.showSnackBar(SnackBar(
        key: const Key('sign-error'),
        content: Text(switch (code) {
          'invalid_provider' => t.signUnavailable,
          'document_changed' => t.signDocumentChanged,
          _ => errorMessage(t, e),
        }),
      ));
      // The enabled methods or the document changed meanwhile: reload the
      // lease so the tenant reviews what they would sign.
      if (code == 'invalid_provider' || code == 'document_changed') {
        ref.invalidate(leaseProvider(widget.leaseId));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = _provider;
    if (provider == null) {
      return Text(t.signUnavailable, key: const Key('sign-unavailable'));
    }
    final ps = widget.providers;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (ps.length > 1) ...[
        Text(t.signMethodChoose, style: Theme.of(context).textTheme.labelLarge),
        RadioGroup<SignProviderIdEnum>(
          groupValue: provider.id,
          onChanged: (id) {
            if (!_busy && id != null) setState(() => _chosen = id);
          },
          child: Column(children: [
            for (final p in ps)
              RadioListTile<SignProviderIdEnum>(
                key: Key('sign-provider-${p.id.value}'),
                value: p.id,
                contentPadding: EdgeInsets.zero,
                title: Text(signMethodText(t, p)),
              ),
          ]),
        ),
      ],
      FilledButton(key: const Key('sign-lease'), onPressed: _busy ? null : _sign, child: Text(t.leaseSign)),
      if (ps.length == 1) ...[
        const SizedBox(height: 4),
        Text(t.signMethodLabel(signMethodText(t, provider)), style: Theme.of(context).textTheme.bodySmall),
      ],
    ]);
  }
}

/// The second payment option: a card payment link in the landlord's own
/// Revolut account. Hidden when unavailable (401/403); the link is created
/// only on tap, never on load.
class RevolutButton extends ConsumerStatefulWidget {
  const RevolutButton({super.key, required this.shareId});

  final String shareId;

  @override
  ConsumerState<RevolutButton> createState() => _RevolutButtonState();
}

class _RevolutButtonState extends ConsumerState<RevolutButton> {
  bool _busy = false;
  bool _hidden = false;
  String? _message;

  Future<void> _pay(CardPayment p, AppLocalizations t) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      var link = p.link;
      if (link == null || link.status != PaymentLinkStatusEnum.created) {
        link = await ref.read(paymentsRepositoryProvider).createLink(widget.shareId);
      }
      // Only an https page of the provider leaves the app.
      final url = safeExternalUrl(link.url);
      final ok = url != null && await ref.read(urlOpenerProvider).open(url);
      if (!ok && mounted) setState(() => _message = t.actionFailed);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 409) {
          _message = t.cardPaymentUnavailable;
        } else if (e.code == 401 || e.code == 403 || e.code == 404) {
          _hidden = true;
        } else {
          _message = errorMessage(t, e);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _message = errorMessage(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = ref.watch(cardPaymentProvider(widget.shareId)).asData?.value;
    if (p == null || _hidden) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OutlinedButton.icon(
          key: Key('revolut-${widget.shareId}'),
          icon: const Icon(Icons.credit_card),
          label: Text(t.payByCard),
          onPressed: _busy ? null : () => _pay(p, t),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_message!,
                key: Key('revolut-message-${widget.shareId}'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ]),
    );
  }
}
