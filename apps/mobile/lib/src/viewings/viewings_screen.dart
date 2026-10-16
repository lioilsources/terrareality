import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../common/api_error.dart';
import '../messaging/conversations_screen.dart' show titleOf;
import 'viewings_repository.dart';

/// My upcoming viewings: cancel one, or open the application to pick
/// another slot. [cancelledApplicationId] (from a `viewing_cancelled` push)
/// shows that the landlord cancelled the viewing of that application.
class ViewingsScreen extends ConsumerWidget {
  const ViewingsScreen({super.key, this.cancelledApplicationId});

  final String? cancelledApplicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final fmt = DateFormat.yMMMEd(locale.toString()).add_Hm();
    final list = ref.watch(myViewingsProvider);

    Future<void> cancel(Viewing v) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(t.cancelViewingConfirm),
          content: Text('${titleOf(v.listingTitle, locale.languageCode)}\n${fmt.format(v.startsAt.toLocal())}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.back)),
            FilledButton(key: const Key('confirm-cancel'), onPressed: () => Navigator.pop(c, true), child: Text(t.cancelBooking)),
          ],
        ),
      );
      if (ok != true) return;
      try {
        await ref.read(viewingsRepositoryProvider).cancel(v.id);
        ref.invalidate(myViewingsProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.bookingCancelled)));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(t, e))));
      }
    }

    final cancelledFor = cancelledApplicationId;
    final notice = cancelledFor == null
        ? null
        : Card(
            key: const Key('viewing-cancelled'),
            margin: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.event_busy),
              title: Text(t.viewingCancelledByLandlord),
              trailing: TextButton(
                key: const Key('open-cancelled-application'),
                onPressed: () async {
                  await context.push('/zadosti/$cancelledFor');
                  ref.invalidate(myViewingsProvider);
                },
                child: Text(t.openApplication),
              ),
            ),
          );

    return Scaffold(
      appBar: AppBar(title: Text(t.viewingsTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myViewingsProvider.future),
        child: list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ApiErrorView(error: e, scrollable: true, onRetry: () => ref.invalidate(myViewingsProvider)),
          data: (items) => items.isEmpty
              ? ListView(children: [?notice, ListTile(title: Text(t.viewingsEmpty))])
              : ListView(children: [
                  ?notice,
                  for (final v in items)
                    ListTile(
                      key: Key('viewing-${v.id}'),
                      leading: const Icon(Icons.event_available),
                      title: Text(titleOf(v.listingTitle, locale.languageCode)),
                      subtitle: Text([
                        fmt.format(v.startsAt.toLocal()),
                        '${v.durationMin} min',
                        if (v.city != null) v.city!,
                        if (v.note.isNotEmpty) v.note,
                      ].join(' · ')),
                      isThreeLine: v.note.isNotEmpty,
                      onTap: () async {
                        await context.push('/zadosti/${v.applicationId}');
                        ref.invalidate(myViewingsProvider);
                      },
                      trailing: TextButton(
                        key: Key('cancel-${v.id}'),
                        onPressed: () => cancel(v),
                        child: Text(t.cancelBooking),
                      ),
                    ),
                ]),
        ),
      ),
    );
  }
}
