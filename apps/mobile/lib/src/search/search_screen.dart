import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../common/api_error.dart';
import '../common/money.dart';
import '../messaging/conversations_screen.dart' show titleOf;
import 'listing_map.dart';
import 'search_repository.dart';

String kindText(AppLocalizations t, UnitKind k) => switch (k) {
      UnitKind.apartment => t.kindApartment,
      UnitKind.house => t.kindHouse,
      UnitKind.room => t.kindRoom,
      UnitKind.parking => t.kindParking,
      UnitKind.storage => t.kindStorage,
      _ => t.kindCommercial,
    };

/// Search with filters and a list/map toggle. The map falls back to the
/// list when the style cannot be loaded.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _showMap = false;
  bool _mapFailed = false;
  SearchResult? _markersFor;
  List<MapMarker> _markers = const [];

  /// Markers change only with a new response, not on every rebuild.
  List<MapMarker> _markersOf(SearchResult r) {
    if (!identical(r, _markersFor)) {
      _markersFor = r;
      _markers = r.points.isNotEmpty
          ? [for (final p in r.points) MapMarker(id: p.id, lat: p.lat, lng: p.lng)]
          : [for (final a in r.areas) MapMarker(id: a.path, lat: a.lat, lng: a.lng, count: a.count, areaPath: a.path)];
    }
    return _markers;
  }

  void _mapUnavailable() {
    if (!mounted || _mapFailed) return;
    setState(() {
      _mapFailed = true;
      _showMap = false;
    });
  }

  void _openMarker(MapMarker m) {
    final filters = ref.read(searchFiltersProvider.notifier);
    if (m.isArea) {
      filters.set(ref.read(searchFiltersProvider).copyWith(adminPath: () => m.areaPath, bbox: () => null));
    } else {
      context.push('/inzerat/${m.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final filters = ref.watch(searchFiltersProvider);
    final result = ref.watch(searchResultProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.searchTitle),
        actions: [
          IconButton(
            key: const Key('open-filters'),
            tooltip: t.filters,
            icon: Badge(isLabelVisible: !filters.isEmpty, child: const Icon(Icons.tune)),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => FilterSheet(initial: filters),
            ),
          ),
          if (!_mapFailed)
            IconButton(
              key: const Key('toggle-map'),
              tooltip: _showMap ? t.showList : t.showMap,
              icon: Icon(_showMap ? Icons.view_list : Icons.map_outlined),
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
        ],
      ),
      body: result.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ApiErrorView(error: e, onRetry: () => ref.invalidate(searchResultProvider)),
        data: (r) => _showMap ? _map(t, r.first, filters) : _list(t, r, filters),
      ),
    );
  }

  Widget _areaChips(AppLocalizations t, SearchFilters filters) {
    final notifier = ref.read(searchFiltersProvider.notifier);
    return Wrap(spacing: 8, children: [
      if (filters.bbox != null)
        InputChip(
          label: Text(t.mapAreaFilter),
          onDeleted: () => notifier.area(null),
          deleteButtonTooltipMessage: t.clearFilter,
        ),
      if (filters.adminPath != null)
        InputChip(
          label: Text(t.areaFilter),
          onDeleted: () => notifier.set(filters.copyWith(adminPath: () => null)),
          deleteButtonTooltipMessage: t.clearFilter,
        ),
    ]);
  }

  Widget _list(AppLocalizations t, SearchPage r, SearchFilters filters) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(searchResultProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_mapFailed)
            Card(
              key: const Key('map-unavailable'),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(leading: const Icon(Icons.map_outlined), title: Text(t.mapUnavailable)),
            ),
          Text(t.searchTotal(r.total), style: Theme.of(context).textTheme.titleMedium),
          _areaChips(t, filters),
          const SizedBox(height: 8),
          if (r.items.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text(t.searchEmpty)),
          for (final c in r.items) ListingCardTile(card: c),
          if (r.moreError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(errorMessage(t, r.moreError!), textAlign: TextAlign.center),
            ),
          if (r.hasMore)
            Center(
              child: r.loadingMore
                  ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())
                  : TextButton(
                      key: const Key('load-more'),
                      onPressed: () => ref.read(searchResultProvider.notifier).more(),
                      child: Text(r.moreError != null ? t.retry : t.loadMore),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _map(AppLocalizations t, SearchResult r, SearchFilters filters) {
    final markers = _markersOf(r);
    return Column(children: [
      Expanded(
        child: Semantics(
          label: t.mapLabel(r.total),
          child: ref.watch(listingMapProvider).build(
                key: const Key('search-map'),
                markers: markers,
                onTap: _openMarker,
                onBoundsChanged: (b) => ref.read(searchFiltersProvider.notifier).area(b),
                onUnavailable: _mapUnavailable,
              ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(child: Text(t.searchTotal(r.total))),
          _areaChips(t, filters),
        ]),
      ),
    ]);
  }
}

/// A listing card in the results, with the transparent "Promoted" label.
class ListingCardTile extends StatelessWidget {
  const ListingCardTile({super.key, required this.card});

  final ListingCard card;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final title = titleOf(card.title, locale.languageCode);
    final facts = [
      if (card.layout != null) card.layout!,
      if (card.floorArea != null) '${card.floorArea!.round()} m²',
      [card.city, if (card.cityPart != null) card.cityPart!].join(' – '),
    ].join(' · ');
    final rent = t.perMonth(money(card.rentAmount, locale.toString(), currency: card.currency));
    return Card(
      key: Key('card-${card.id}'),
      clipBehavior: Clip.antiAlias,
      shape: card.highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), side: BorderSide(color: scheme.primary, width: 2))
          : null,
      child: InkWell(
        onTap: () => context.push('/inzerat/${card.id}'),
        child: Semantics(
          button: true,
          label: [title, rent, facts, if (card.promoted) t.promoted].join(', '),
          excludeSemantics: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (card.coverUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  card.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(color: scheme.surfaceContainerHighest),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (card.promoted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      key: Key('promoted-${card.id}'),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(t.promoted,
                          style: TextStyle(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w600)),
                    ),
                  ),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(facts),
                const SizedBox(height: 4),
                Text(rent, style: Theme.of(context).textTheme.titleSmall),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Kind, layout and rent range filters.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key, required this.initial});

  final SearchFilters initial;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late final Set<UnitKind> _kinds = {...widget.initial.kinds};
  late final Set<String> _layouts = {...widget.initial.layouts};
  late final _min = TextEditingController(text: widget.initial.rentMin?.toString() ?? '');
  late final _max = TextEditingController(text: widget.initial.rentMax?.toString() ?? '');

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _apply() {
    int? parse(String s) => int.tryParse(s.replaceAll(RegExp(r'\s'), ''));
    ref.read(searchFiltersProvider.notifier).set(widget.initial.copyWith(
          kinds: _kinds,
          layouts: _layouts,
          rentMin: () => parse(_min.text),
          rentMax: () => parse(_max.text),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.filters, style: text.titleLarge),
            const SizedBox(height: 12),
            Text(t.filterKind, style: text.titleSmall),
            Wrap(spacing: 8, children: [
              for (final k in kindOptions)
                FilterChip(
                  label: Text(kindText(t, k)),
                  selected: _kinds.contains(k),
                  onSelected: (on) => setState(() => on ? _kinds.add(k) : _kinds.remove(k)),
                ),
            ]),
            const SizedBox(height: 12),
            Text(t.filterLayout, style: text.titleSmall),
            Wrap(spacing: 8, children: [
              for (final l in layoutOptions)
                FilterChip(
                  label: Text(l),
                  selected: _layouts.contains(l),
                  onSelected: (on) => setState(() => on ? _layouts.add(l) : _layouts.remove(l)),
                ),
            ]),
            const SizedBox(height: 12),
            Text(t.filterRent, style: text.titleSmall),
            Row(children: [
              Expanded(
                child: TextField(
                  key: const Key('rent-min'),
                  controller: _min,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: t.rentFrom, suffixText: 'Kč'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('rent-max'),
                  controller: _max,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: t.rentTo, suffixText: 'Kč'),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => setState(() {
                  _kinds.clear();
                  _layouts.clear();
                  _min.clear();
                  _max.clear();
                }),
                child: Text(t.clearFilters),
              ),
              const SizedBox(width: 8),
              FilledButton(key: const Key('apply-filters'), onPressed: _apply, child: Text(t.showResults)),
            ]),
          ]),
        ),
      ),
    );
  }
}
