//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SearchQuery {
  /// Returns a new [SearchQuery] instance.
  SearchQuery({
    this.text,
    this.kinds = const [],
    this.rentMin,
    this.rentMax,
    this.areaMin,
    this.areaMax,
    this.layouts = const [],
    this.adminPath,
    this.bbox = const [],
    this.attributes = const {},
    this.sort,
    this.limit,
    this.offset,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? text;

  List<UnitKind> kinds;

  /// Minor units.
  ///
  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rentMin;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rentMax;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? areaMin;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? areaMax;

  List<String> layouts;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? adminPath;

  /// west, south, east, north
  List<double> bbox;

  Map<String, AttrFilter> attributes;

  SearchQuerySortEnum? sort;

  /// Minimum value: 1
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? limit;

  /// Minimum value: 0
  /// Maximum value: 10000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? offset;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SearchQuery &&
    other.text == text &&
    _deepEquality.equals(other.kinds, kinds) &&
    other.rentMin == rentMin &&
    other.rentMax == rentMax &&
    other.areaMin == areaMin &&
    other.areaMax == areaMax &&
    _deepEquality.equals(other.layouts, layouts) &&
    other.adminPath == adminPath &&
    _deepEquality.equals(other.bbox, bbox) &&
    _deepEquality.equals(other.attributes, attributes) &&
    other.sort == sort &&
    other.limit == limit &&
    other.offset == offset;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (text == null ? 0 : text!.hashCode) +
    (kinds.hashCode) +
    (rentMin == null ? 0 : rentMin!.hashCode) +
    (rentMax == null ? 0 : rentMax!.hashCode) +
    (areaMin == null ? 0 : areaMin!.hashCode) +
    (areaMax == null ? 0 : areaMax!.hashCode) +
    (layouts.hashCode) +
    (adminPath == null ? 0 : adminPath!.hashCode) +
    (bbox.hashCode) +
    (attributes.hashCode) +
    (sort == null ? 0 : sort!.hashCode) +
    (limit == null ? 0 : limit!.hashCode) +
    (offset == null ? 0 : offset!.hashCode);

  @override
  String toString() => 'SearchQuery[text=$text, kinds=$kinds, rentMin=$rentMin, rentMax=$rentMax, areaMin=$areaMin, areaMax=$areaMax, layouts=$layouts, adminPath=$adminPath, bbox=$bbox, attributes=$attributes, sort=$sort, limit=$limit, offset=$offset]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.text != null) {
      json[r'text'] = this.text;
    } else {
      json[r'text'] = null;
    }
      json[r'kinds'] = this.kinds;
    if (this.rentMin != null) {
      json[r'rent_min'] = this.rentMin;
    } else {
      json[r'rent_min'] = null;
    }
    if (this.rentMax != null) {
      json[r'rent_max'] = this.rentMax;
    } else {
      json[r'rent_max'] = null;
    }
    if (this.areaMin != null) {
      json[r'area_min'] = this.areaMin;
    } else {
      json[r'area_min'] = null;
    }
    if (this.areaMax != null) {
      json[r'area_max'] = this.areaMax;
    } else {
      json[r'area_max'] = null;
    }
      json[r'layouts'] = this.layouts;
    if (this.adminPath != null) {
      json[r'admin_path'] = this.adminPath;
    } else {
      json[r'admin_path'] = null;
    }
      json[r'bbox'] = this.bbox;
      json[r'attributes'] = this.attributes;
    if (this.sort != null) {
      json[r'sort'] = this.sort;
    } else {
      json[r'sort'] = null;
    }
    if (this.limit != null) {
      json[r'limit'] = this.limit;
    } else {
      json[r'limit'] = null;
    }
    if (this.offset != null) {
      json[r'offset'] = this.offset;
    } else {
      json[r'offset'] = null;
    }
    return json;
  }

  /// Returns a new [SearchQuery] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SearchQuery? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SearchQuery[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SearchQuery[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SearchQuery(
        text: mapValueOfType<String>(json, r'text'),
        kinds: UnitKind.listFromJson(json[r'kinds']),
        rentMin: mapValueOfType<int>(json, r'rent_min'),
        rentMax: mapValueOfType<int>(json, r'rent_max'),
        areaMin: mapValueOfType<double>(json, r'area_min'),
        areaMax: mapValueOfType<double>(json, r'area_max'),
        layouts: json[r'layouts'] is Iterable
            ? (json[r'layouts'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        adminPath: mapValueOfType<String>(json, r'admin_path'),
        bbox: json[r'bbox'] is Iterable
            ? (json[r'bbox'] as Iterable).cast<double>().toList(growable: false)
            : const [],
        attributes: AttrFilter.mapFromJson(json[r'attributes']),
        sort: SearchQuerySortEnum.fromJson(json[r'sort']),
        limit: mapValueOfType<int>(json, r'limit'),
        offset: mapValueOfType<int>(json, r'offset'),
      );
    }
    return null;
  }

  static List<SearchQuery> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SearchQuery>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SearchQuery.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SearchQuery> mapFromJson(dynamic json) {
    final map = <String, SearchQuery>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SearchQuery.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SearchQuery-objects as value to a dart map
  static Map<String, List<SearchQuery>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SearchQuery>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SearchQuery.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class SearchQuerySortEnum {
  /// Instantiate a new enum with the provided [value].
  const SearchQuerySortEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const relevance = SearchQuerySortEnum._(r'relevance');
  static const priceAsc = SearchQuerySortEnum._(r'price_asc');
  static const priceDesc = SearchQuerySortEnum._(r'price_desc');
  static const newest = SearchQuerySortEnum._(r'newest');
  static const areaDesc = SearchQuerySortEnum._(r'area_desc');

  /// List of all possible values in this [enum][SearchQuerySortEnum].
  static const values = <SearchQuerySortEnum>[
    relevance,
    priceAsc,
    priceDesc,
    newest,
    areaDesc,
  ];

  static SearchQuerySortEnum? fromJson(dynamic value) => SearchQuerySortEnumTypeTransformer().decode(value);

  static List<SearchQuerySortEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SearchQuerySortEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SearchQuerySortEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SearchQuerySortEnum] to String,
/// and [decode] dynamic data back to [SearchQuerySortEnum].
class SearchQuerySortEnumTypeTransformer {
  factory SearchQuerySortEnumTypeTransformer() => _instance ??= const SearchQuerySortEnumTypeTransformer._();

  const SearchQuerySortEnumTypeTransformer._();

  String encode(SearchQuerySortEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SearchQuerySortEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SearchQuerySortEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'relevance': return SearchQuerySortEnum.relevance;
        case r'price_asc': return SearchQuerySortEnum.priceAsc;
        case r'price_desc': return SearchQuerySortEnum.priceDesc;
        case r'newest': return SearchQuerySortEnum.newest;
        case r'area_desc': return SearchQuerySortEnum.areaDesc;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SearchQuerySortEnumTypeTransformer] instance.
  static SearchQuerySortEnumTypeTransformer? _instance;
}


