import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../common/api_error.dart';
import 'messaging_repository.dart';

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>(
  (ref) => ref.watch(messagingRepositoryProvider).conversations(),
);

String titleOf(I18nText text, String locale) => (locale == 'en' && text.en.isNotEmpty) ? text.en : text.cs;

/// Inbox: conversations as a seeker and for the user's organizations.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final list = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.messagesTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(conversationsProvider.future),
        child: list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ApiErrorView(error: e, scrollable: true, onRetry: () => ref.invalidate(conversationsProvider)),
          data: (items) => items.isEmpty
              ? ListView(children: [ListTile(title: Text(t.messagesEmpty))])
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = items[i];
                    final peer = c.role == ConversationRole.seeker ? c.orgName : c.seekerName;
                    return ListTile(
                      title: Text(peer),
                      subtitle: Text(
                        '${titleOf(c.listingTitle, locale)}\n${c.lastMessage}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: c.unread > 0
                          ? Semantics(
                              label: t.unreadCount(c.unread),
                              child: Badge(label: Text('${c.unread}')),
                            )
                          : null,
                      onTap: () async {
                        await context.push('/zpravy/${c.id}');
                        ref.invalidate(conversationsProvider);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
