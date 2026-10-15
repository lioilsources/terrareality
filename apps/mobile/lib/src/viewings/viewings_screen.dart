import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../messaging/conversations_screen.dart' show titleOf;
import 'viewings_repository.dart';

/// My upcoming viewings: cancel one, or open the application to pick
/// another slot.
class ViewingsScreen extends ConsumerWidget {
  const ViewingsScreen({super.key});

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
      } on ApiException catch (_) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.actionFailed)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.viewingsTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myViewingsProvider.future),
        child: list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [ListTile(title: Text(t.statusUnreachable))]),
          data: (items) => items.isEmpty
              ? ListView(children: [ListTile(title: Text(t.viewingsEmpty))])
              : ListView(children: [
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
