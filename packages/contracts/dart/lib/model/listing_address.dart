//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ListingAddress {
  /// Returns a new [ListingAddress] instance.
  ListingAddress({
    required this.label,
    required this.city,
    this.cityPart,
    required this.postalCode,
    required this.lat,
    required this.lng,
  });

  String label;

  String city;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? cityPart;

  String postalCode;

  double lat;

  double lng;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListingAddress &&
    other.label == label &&
    other.city == city &&
    other.cityPart == cityPart &&
    other.postalCode == postalCode &&
    other.lat == lat &&
    other.lng == lng;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (label.hashCode) +
    (city.hashCode) +
    (cityPart == null ? 0 : cityPart!.hashCode) +
    (postalCode.hashCode) +
    (lat.hashCode) +
    (lng.hashCode);

  @override
  String toString() => 'ListingAddress[label=$label, city=$city, cityPart=$cityPart, postalCode=$postalCode, lat=$lat, lng=$lng]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'label'] = this.label;
      json[r'city'] = this.city;
    if (this.cityPart != null) {
      json[r'city_part'] = this.cityPart;
    } else {
      json[r'city_part'] = null;
    }
      json[r'postal_code'] = this.postalCode;
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
    return json;
  }

  /// Returns a new [ListingAddress] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListingAddress? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ListingAddress[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ListingAddress[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ListingAddress(
        label: mapValueOfType<String>(json, r'label')!,
        city: mapValueOfType<String>(json, r'city')!,
        cityPart: mapValueOfType<String>(json, r'city_part'),
        postalCode: mapValueOfType<String>(json, r'postal_code')!,
        lat: mapValueOfType<double>(json, r'lat')!,
        lng: mapValueOfType<double>(json, r'lng')!,
      );
    }
    return null;
  }

  static List<ListingAddress> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingAddress>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingAddress.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListingAddress> mapFromJson(dynamic json) {
    final map = <String, ListingAddress>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListingAddress.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListingAddress-objects as value to a dart map
  static Map<String, List<ListingAddress>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListingAddress>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListingAddress.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'label',
    'city',
    'postal_code',
    'lat',
    'lng',
  };
}

