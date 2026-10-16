import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../common/api_error.dart';
import '../common/paging.dart';
import 'messaging_repository.dart';

/// The inbox, page by page (`before` cursor, newest activity first).
class Conversations extends AsyncNotifier<CursorPage<Conversation>> {
  @override
  Future<CursorPage<Conversation>> build() async {
    final items = await ref.watch(messagingRepositoryProvider).conversations();
    return CursorPage.first(items, conversationsPageSize);
  }

  /// Fetches the page after the last conversation shown and appends it.
  Future<void> more() async {
    final cur = state.value;
    if (cur == null || cur.loadingMore || !cur.hasMore || cur.items.isEmpty) return;
    state = AsyncData(cur.loading());
    try {
      final page = await ref.read(messagingRepositoryProvider).conversations(before: cur.items.last.id);
      if (!ref.mounted || !identical(state.value?.items, cur.items)) return; // reloaded meanwhile
      state = AsyncData(cur.append(page, conversationsPageSize, (c) => c.id));
    } catch (e) {
      if (!ref.mounted || !identical(state.value?.items, cur.items)) return;
      state = AsyncData(cur.failed(e));
    }
  }
}

final conversationsProvider =
    AsyncNotifierProvider.autoDispose<Conversations, CursorPage<Conversation>>(Conversations.new);

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
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ApiErrorView(error: e, scrollable: true, onRetry: () => ref.invalidate(conversationsProvider)),
          data: (page) => page.items.isEmpty
              ? ListView(children: [ListTile(title: Text(t.messagesEmpty))])
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: page.items.length + 1,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    if (i == page.items.length) {
                      return LoadMoreFooter(
                        page: page,
                        onMore: () => ref.read(conversationsProvider.notifier).more(),
                      );
                    }
                    final c = page.items[i];
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
