import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../api/api_provider.dart';

/// Layouts offered as filters (same list as the web, apps/web/src/lib/catalog.ts).
const layoutOptions = ['1+kk', '1+1', '2+kk', '2+1', '3+kk', '3+1', '4+kk', '4+1', '5+kk', '5+1', '6+'];

/// Unit kinds offered as filters.
const kindOptions = [UnitKind.apartment, UnitKind.house, UnitKind.room];

/// The seeker's search filters. Rent is in whole crowns in the UI and
/// becomes minor units in the query (POST /v1/search).
class SearchFilters {
  const SearchFilters({
    this.kinds = const {},
    this.layouts = const {},
    this.rentMin,
    this.rentMax,
    this.bbox,
    this.adminPath,
    this.limit = pageSize,
  });

  static const pageSize = 30;

  final Set<UnitKind> kinds;
  final Set<String> layouts;
  final int? rentMin;
  final int? rentMax;

  /// west, south, east, north of the visible map area (null = anywhere).
  final List<double>? bbox;
  final String? adminPath;
  final int limit;

  bool get isEmpty => kinds.isEmpty && layouts.isEmpty && rentMin == null && rentMax == null;

  SearchFilters copyWith({
    Set<UnitKind>? kinds,
    Set<String>? layouts,
    int? Function()? rentMin,
    int? Function()? rentMax,
    List<double>? Function()? bbox,
    String? Function()? adminPath,
    int? limit,
  }) =>
      SearchFilters(
        kinds: kinds ?? this.kinds,
        layouts: layouts ?? this.layouts,
        rentMin: rentMin != null ? rentMin() : this.rentMin,
        rentMax: rentMax != null ? rentMax() : this.rentMax,
        bbox: bbox != null ? bbox() : this.bbox,
        adminPath: adminPath != null ? adminPath() : this.adminPath,
        limit: limit ?? pageSize,
      );

  SearchQuery toQuery() => SearchQuery(
        kinds: kinds.toList(),
        layouts: layouts.toList(),
        rentMin: rentMin == null ? null : rentMin! * 100,
        rentMax: rentMax == null ? null : rentMax! * 100,
        bbox: bbox ?? const [],
        adminPath: adminPath,
        limit: limit,
      );
}

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void set(SearchFilters f) => state = f;
  void more() => state = state.copyWith(limit: state.limit + SearchFilters.pageSize);
  void area(List<double>? bbox) => state = state.copyWith(bbox: () => bbox, limit: state.limit);
}

final searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(SearchFiltersNotifier.new);

/// Public search, listing detail and the seeker's first steps on a listing.
abstract class SearchRepository {
  Future<SearchResult> search(SearchQuery q);
  Future<PublicListing> listing(String id);

  /// Sends the first message about a listing and returns the conversation id.
  Future<String> startChat(String listingId, String body, Map<String, String> prescreen);

  /// The seeker's existing application for the listing, if any.
  Future<String?> applicationFor(String listingId);

  /// Creates an application and returns its id.
  Future<String> apply(String listingId, {String? message, int? householdSize, Map<String, String> prescreen});
}

class ApiSearchRepository implements SearchRepository {
  ApiSearchRepository(this.client);

  final ApiClient client;

  @override
  Future<SearchResult> search(SearchQuery q) async => (await SearchApi(client).search(q))!;

  @override
  Future<PublicListing> listing(String id) async => (await SearchApi(client).getPublicListing(id))!;

  @override
  Future<String> startChat(String listingId, String body, Map<String, String> prescreen) async =>
      (await MessagingApi(client).startConversation(
        StartConversation(listingId: listingId, body: body, prescreenAnswers: prescreen),
      ))!
          .conversationId;

  @override
  Future<String?> applicationFor(String listingId) async {
    final mine = await ApplicationsApi(client).listMyApplications() ?? [];
    return mine
        .where((a) => a.listingId == listingId && a.status != ApplicationStatus.withdrawn)
        .map((a) => a.id)
        .firstOrNull;
  }

  @override
  Future<String> apply(String listingId,
          {String? message, int? householdSize, Map<String, String> prescreen = const {}}) async =>
      (await ApplicationsApi(client).createApplication(ApplicationInput(
        listingId: listingId,
        message: message,
        householdSize: householdSize,
        prescreenAnswers: prescreen,
      )))!
          .application
          .id;
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => ApiSearchRepository(ref.watch(apiClientProvider)),
);

final searchResultProvider = FutureProvider.autoDispose<SearchResult>(
  (ref) => ref.watch(searchRepositoryProvider).search(ref.watch(searchFiltersProvider).toQuery()),
);

final publicListingProvider = FutureProvider.autoDispose.family<PublicListing, String>(
  (ref, id) => ref.watch(searchRepositoryProvider).listing(id),
);
