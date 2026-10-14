//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AddressSuggestion {
  /// Returns a new [AddressSuggestion] instance.
  AddressSuggestion({
    required this.ruianId,
    required this.label,
    required this.municipality,
    this.district,
    this.cityPart,
    this.street,
    required this.postalCode,
    required this.lat,
    required this.lng,
  });

  int ruianId;

  String label;

  String municipality;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? district;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? cityPart;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? street;

  String postalCode;

  double lat;

  double lng;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AddressSuggestion &&
    other.ruianId == ruianId &&
    other.label == label &&
    other.municipality == municipality &&
    other.district == district &&
    other.cityPart == cityPart &&
    other.street == street &&
    other.postalCode == postalCode &&
    other.lat == lat &&
    other.lng == lng;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ruianId.hashCode) +
    (label.hashCode) +
    (municipality.hashCode) +
    (district == null ? 0 : district!.hashCode) +
    (cityPart == null ? 0 : cityPart!.hashCode) +
    (street == null ? 0 : street!.hashCode) +
    (postalCode.hashCode) +
    (lat.hashCode) +
    (lng.hashCode);

  @override
  String toString() => 'AddressSuggestion[ruianId=$ruianId, label=$label, municipality=$municipality, district=$district, cityPart=$cityPart, street=$street, postalCode=$postalCode, lat=$lat, lng=$lng]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ruian_id'] = this.ruianId;
      json[r'label'] = this.label;
      json[r'municipality'] = this.municipality;
    if (this.district != null) {
      json[r'district'] = this.district;
    } else {
      json[r'district'] = null;
    }
    if (this.cityPart != null) {
      json[r'city_part'] = this.cityPart;
    } else {
      json[r'city_part'] = null;
    }
    if (this.street != null) {
      json[r'street'] = this.street;
    } else {
      json[r'street'] = null;
    }
      json[r'postal_code'] = this.postalCode;
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
    return json;
  }

  /// Returns a new [AddressSuggestion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AddressSuggestion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AddressSuggestion[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AddressSuggestion[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AddressSuggestion(
        ruianId: mapValueOfType<int>(json, r'ruian_id')!,
        label: mapValueOfType<String>(json, r'label')!,
        municipality: mapValueOfType<String>(json, r'municipality')!,
        district: mapValueOfType<String>(json, r'district'),
        cityPart: mapValueOfType<String>(json, r'city_part'),
        street: mapValueOfType<String>(json, r'street'),
        postalCode: mapValueOfType<String>(json, r'postal_code')!,
        lat: mapValueOfType<double>(json, r'lat')!,
        lng: mapValueOfType<double>(json, r'lng')!,
      );
    }
    return null;
  }

  static List<AddressSuggestion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AddressSuggestion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AddressSuggestion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AddressSuggestion> mapFromJson(dynamic json) {
    final map = <String, AddressSuggestion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AddressSuggestion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AddressSuggestion-objects as value to a dart map
  static Map<String, List<AddressSuggestion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AddressSuggestion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AddressSuggestion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ruian_id',
    'label',
    'municipality',
    'postal_code',
    'lat',
    'lng',
  };
}

