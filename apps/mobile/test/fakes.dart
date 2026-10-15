import 'package:flutter/material.dart';
import 'package:terra_api/api.dart';
import 'package:terrareality/src/search/listing_map.dart';
import 'package:terrareality/src/search/search_repository.dart';

/// A map that renders markers as buttons; MapLibre needs a platform view.
class FakeMap extends ListingMapFactory {
  FakeMap({this.fail = false});

  final bool fail;
  List<MapMarker> markers = [];

  @override
  Widget build({
    Key? key,
    required List<MapMarker> markers,
    ValueChanged<MapMarker>? onTap,
    ValueChanged<List<double>>? onBoundsChanged,
    VoidCallback? onUnavailable,
    bool interactive = true,
  }) {
    this.markers = markers;
    if (fail) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onUnavailable?.call());
      return const SizedBox.shrink();
    }
    return ListView(key: key, children: [
      for (final m in markers)
        TextButton(key: Key('marker-${m.id}'), onPressed: () => onTap?.call(m), child: Text('pin ${m.id}')),
      TextButton(
        key: const Key('move-map'),
        onPressed: () => onBoundsChanged?.call([14.3, 50.0, 14.5, 50.1]),
        child: const Text('move'),
      ),
    ]);
  }
}

ListingCard card(String id, String title, {bool promoted = false, String layout = '3+kk'}) => ListingCard(
      id: id,
      unitKind: UnitKind.apartment,
      layout: layout,
      rentAmount: 1850000,
      currency: 'CZK',
      floorArea: 64,
      title: I18nText(cs: title, en: ''),
      city: 'Praha',
      cityPart: 'Dejvice',
      lat: 50.1,
      lng: 14.39,
      publishedAt: DateTime(2026, 10, 1),
      promoted: promoted,
    );

PublicListing publicListing({List<PrescreenQuestion> prescreen = const []}) => PublicListing(
      id: 'l1',
      title: I18nText(cs: 'Byt 3+kk Dejvice', en: ''),
      description: I18nText(cs: 'Světlý byt u metra.', en: ''),
      rentAmount: 1850000,
      depositAmount: 3700000,
      currency: 'CZK',
      minTermMonths: 12,
      attributes: {'balcony': true},
      unit: PublicListingUnit(kind: UnitKind.apartment, layout: '3+kk', floor: 3, floorArea: 64),
      location: PublicListingLocation(lat: 50.1, lng: 14.39, precision: PublicListingLocationPrecisionEnum.approximate),
      areaNames: ['Praha 6', 'Dejvice'],
      photos: [],
      prescreen: prescreen,
      publishedAt: DateTime(2026, 10, 1),
    );

class FakeSearch implements SearchRepository {
  final queries = <SearchQuery>[];
  final chats = <String>[];
  final applied = <String?>[];
  String? existingApplication;
  ApiException? failWith;

  @override
  Future<SearchResult> search(SearchQuery q) async {
    queries.add(q);
    return SearchResult(
      total: 2,
      rentMin: 1500000,
      rentMax: 2500000,
      items: [card('l1', 'Byt 3+kk Dejvice', promoted: true), card('l2', 'Byt 3+kk Holešovice')],
      points: [
        MapPoint(id: 'l1', lat: 50.1, lng: 14.39, rentAmount: 1850000),
        MapPoint(id: 'l2', lat: 50.1, lng: 14.44, rentAmount: 1850000),
      ],
    );
  }

  @override
  Future<PublicListing> listing(String id) async => publicListing();

  @override
  Future<String> startChat(String listingId, String body, Map<String, String> prescreen) async {
    if (failWith != null) throw failWith!;
    chats.add(body);
    return 'c9';
  }

  @override
  Future<String?> applicationFor(String listingId) async => existingApplication;

  @override
  Future<String> apply(String listingId,
      {String? message, int? householdSize, Map<String, String> prescreen = const {}}) async {
    applied.add(message);
    return 'a1';
  }
}
