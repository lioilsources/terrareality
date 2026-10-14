import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../messaging/conversations_screen.dart' show titleOf;
import 'applications_repository.dart';

final myApplicationsProvider = FutureProvider.autoDispose<List<Application>>(
  (ref) => ref.watch(applicationsRepositoryProvider).mine(),
);

String statusText(AppLocalizations t, ApplicationStatus s) => switch (s) {
      ApplicationStatus.pendingConsent => t.appPendingConsent,
      ApplicationStatus.submitted => t.appSubmitted,
      ApplicationStatus.invited => t.appInvited,
      ApplicationStatus.accepted => t.appAccepted,
      ApplicationStatus.rejected => t.appRejected,
      _ => t.appWithdrawn,
    };

/// The seeker's applications.
class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final list = ref.watch(myApplicationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.applicationsTitle)),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(t.statusUnreachable)),
        data: (items) => items.isEmpty
            ? Center(child: Text(t.applicationsEmpty))
            : ListView(
                children: [
                  for (final a in items)
                    ListTile(
                      title: Text(titleOf(a.listingTitle, locale)),
                      subtitle: Text(statusText(t, a.status)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/zadosti/${a.id}');
                        ref.invalidate(myApplicationsProvider);
                      },
                    ),
                ],
              ),
      ),
    );
  }
}

final applicationDetailProvider = FutureProvider.autoDispose.family<ApplicationDetail, String>(
  (ref, id) => ref.watch(applicationsRepositoryProvider).detail(id),
);

/// One application: status, consent and viewing slots to book.
class ApplicationScreen extends ConsumerWidget {
  const ApplicationScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = DateFormat.yMMMEd(locale).add_Hm();
    final detail = ref.watch(applicationDetailProvider(id));
    final repo = ref.read(applicationsRepositoryProvider);
    Future<void> run(Future<void> Function() action, String done) async {
      try {
        await action();
        ref.invalidate(applicationDetailProvider(id));
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      } on ApiException catch (_) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.actionFailed)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.applicationTitle)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(t.statusUnreachable)),
        data: (d) {
          final a = d.application;
          final waitingForMe = a.status == ApplicationStatus.pendingConsent && a.consentNeeded && a.myConsentAt == null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(titleOf(a.listingTitle, Localizations.localeOf(context).languageCode),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Chip(label: Text(statusText(t, a.status))),
              if (waitingForMe)
                FilledButton(
                  onPressed: () => run(() => repo.consent(id), t.consentGiven),
                  child: Text(t.consent),
                ),
              if (d.booking != null) ...[
                const SizedBox(height: 16),
                Text(t.yourViewing, style: Theme.of(context).textTheme.titleMedium),
                ListTile(
                  key: const Key('booking'),
                  leading: const Icon(Icons.event_available),
                  title: Text(fmt.format(d.booking!.startsAt.toLocal())),
                  subtitle: d.booking!.note.isEmpty ? null : Text(d.booking!.note),
                  trailing: TextButton(
                    onPressed: () => run(() => repo.cancel(d.booking!.id), t.bookingCancelled),
                    child: Text(t.cancelBooking),
                  ),
                ),
              ],
              if (a.status == ApplicationStatus.submitted || a.status == ApplicationStatus.invited) ...[
                const SizedBox(height: 16),
                Text(t.viewingSlots, style: Theme.of(context).textTheme.titleMedium),
                if (d.slots.isEmpty) Text(t.noSlots),
                for (final s in d.slots)
                  ListTile(
                    title: Text(fmt.format(s.startsAt.toLocal())),
                    subtitle: Text('${s.durationMin} min${s.note.isEmpty ? '' : ' · ${s.note}'}'),
                    trailing: s.booked < s.capacity
                        ? FilledButton.tonal(
                            onPressed: () => run(() => repo.book(id, s.id), t.booked),
                            child: Text(t.book),
                          )
                        : Text(t.slotFull),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
