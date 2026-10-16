import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import 'api_error.dart';

/// Items of a cursor-paged list (`before` + `limit`, newest first): a full
/// page may have more, a short one ends the list.
class CursorPage<T> {
  const CursorPage({required this.items, required this.hasMore, this.loadingMore = false, this.moreError});

  final List<T> items;
  final bool hasMore;
  final bool loadingMore;
  final Object? moreError;

  /// The first page of a list served [limit] at a time.
  factory CursorPage.first(List<T> items, int limit) => CursorPage(items: items, hasMore: items.length >= limit);

  CursorPage<T> loading() => CursorPage(items: items, hasMore: hasMore, loadingMore: true);

  CursorPage<T> failed(Object error) => CursorPage(items: items, hasMore: hasMore, moreError: error);

  /// Appends [page] (asked for with [limit]), skipping items already shown:
  /// a list ordered by activity can move an item onto a later page.
  CursorPage<T> append(List<T> page, int limit, String Function(T) id) {
    final seen = {for (final x in items) id(x)};
    final fresh = [for (final x in page) if (seen.add(id(x))) x];
    return CursorPage(items: [...items, ...fresh], hasMore: page.length >= limit && fresh.isNotEmpty);
  }
}

/// The end of a paged list: loads the next page when it scrolls into view,
/// shows a spinner meanwhile and the shared error view (with retry) when the
/// page failed. Nothing once the list is complete.
class LoadMoreFooter extends StatefulWidget {
  const LoadMoreFooter({super.key, required this.page, required this.onMore});

  final CursorPage<Object?> page;
  final VoidCallback onMore;

  @override
  State<LoadMoreFooter> createState() => _LoadMoreFooterState();
}

class _LoadMoreFooterState extends State<LoadMoreFooter> {
  @override
  void initState() {
    super.initState();
    _autoLoad();
  }

  @override
  void didUpdateWidget(LoadMoreFooter old) {
    super.didUpdateWidget(old);
    if (old.page.items.length != widget.page.items.length) _autoLoad();
  }

  /// Built means scrolled into view (a lazy list builds it only then).
  /// A failed page waits for the retry button instead of looping.
  void _autoLoad() {
    final p = widget.page;
    if (!p.hasMore || p.loadingMore || p.moreError != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.page;
    if (p.moreError != null) {
      return ApiErrorView(key: const Key('load-more-error'), error: p.moreError!, onRetry: widget.onMore, inline: true);
    }
    if (!p.hasMore) return const SizedBox.shrink();
    if (p.loadingMore) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    return Center(
      child: TextButton(
        key: const Key('load-more'),
        onPressed: widget.onMore,
        child: Text(AppLocalizations.of(context).loadMore),
      ),
    );
  }
}
