//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ListingCard {
  /// Returns a new [ListingCard] instance.
  ListingCard({
    required this.id,
    required this.unitKind,
    this.layout,
    required this.rentAmount,
    required this.currency,
    this.floorArea,
    required this.title,
    required this.city,
    this.cityPart,
    required this.lat,
    required this.lng,
    this.coverUrl,
    required this.publishedAt,
  });

  String id;

  UnitKind unitKind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? layout;

  int rentAmount;

  String currency;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? floorArea;

  I18nText title;

  String city;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? cityPart;

  double lat;

  double lng;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? coverUrl;

  DateTime publishedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListingCard &&
    other.id == id &&
    other.unitKind == unitKind &&
    other.layout == layout &&
    other.rentAmount == rentAmount &&
    other.currency == currency &&
    other.floorArea == floorArea &&
    other.title == title &&
    other.city == city &&
    other.cityPart == cityPart &&
    other.lat == lat &&
    other.lng == lng &&
    other.coverUrl == coverUrl &&
    other.publishedAt == publishedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (unitKind.hashCode) +
    (layout == null ? 0 : layout!.hashCode) +
    (rentAmount.hashCode) +
    (currency.hashCode) +
    (floorArea == null ? 0 : floorArea!.hashCode) +
    (title.hashCode) +
    (city.hashCode) +
    (cityPart == null ? 0 : cityPart!.hashCode) +
    (lat.hashCode) +
    (lng.hashCode) +
    (coverUrl == null ? 0 : coverUrl!.hashCode) +
    (publishedAt.hashCode);

  @override
  String toString() => 'ListingCard[id=$id, unitKind=$unitKind, layout=$layout, rentAmount=$rentAmount, currency=$currency, floorArea=$floorArea, title=$title, city=$city, cityPart=$cityPart, lat=$lat, lng=$lng, coverUrl=$coverUrl, publishedAt=$publishedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'unit_kind'] = this.unitKind;
    if (this.layout != null) {
      json[r'layout'] = this.layout;
    } else {
      json[r'layout'] = null;
    }
      json[r'rent_amount'] = this.rentAmount;
      json[r'currency'] = this.currency;
    if (this.floorArea != null) {
      json[r'floor_area'] = this.floorArea;
    } else {
      json[r'floor_area'] = null;
    }
      json[r'title'] = this.title;
      json[r'city'] = this.city;
    if (this.cityPart != null) {
      json[r'city_part'] = this.cityPart;
    } else {
      json[r'city_part'] = null;
    }
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
    if (this.coverUrl != null) {
      json[r'cover_url'] = this.coverUrl;
    } else {
      json[r'cover_url'] = null;
    }
      json[r'published_at'] = this.publishedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [ListingCard] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListingCard? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ListingCard[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ListingCard[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ListingCard(
        id: mapValueOfType<String>(json, r'id')!,
        unitKind: UnitKind.fromJson(json[r'unit_kind'])!,
        layout: mapValueOfType<String>(json, r'layout'),
        rentAmount: mapValueOfType<int>(json, r'rent_amount')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        floorArea: mapValueOfType<double>(json, r'floor_area'),
        title: I18nText.fromJson(json[r'title'])!,
        city: mapValueOfType<String>(json, r'city')!,
        cityPart: mapValueOfType<String>(json, r'city_part'),
        lat: mapValueOfType<double>(json, r'lat')!,
        lng: mapValueOfType<double>(json, r'lng')!,
        coverUrl: mapValueOfType<String>(json, r'cover_url'),
        publishedAt: mapDateTime(json, r'published_at', r'')!,
      );
    }
    return null;
  }

  static List<ListingCard> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingCard>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingCard.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListingCard> mapFromJson(dynamic json) {
    final map = <String, ListingCard>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListingCard.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListingCard-objects as value to a dart map
  static Map<String, List<ListingCard>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListingCard>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListingCard.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'unit_kind',
    'rent_amount',
    'currency',
    'title',
    'city',
    'lat',
    'lng',
    'published_at',
  };
}

