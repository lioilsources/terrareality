//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicListingUnit {
  /// Returns a new [PublicListingUnit] instance.
  PublicListingUnit({
    required this.kind,
    this.layout,
    this.floor,
    this.floorArea,
  });

  UnitKind kind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? layout;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? floor;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? floorArea;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PublicListingUnit &&
    other.kind == kind &&
    other.layout == layout &&
    other.floor == floor &&
    other.floorArea == floorArea;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (layout == null ? 0 : layout!.hashCode) +
    (floor == null ? 0 : floor!.hashCode) +
    (floorArea == null ? 0 : floorArea!.hashCode);

  @override
  String toString() => 'PublicListingUnit[kind=$kind, layout=$layout, floor=$floor, floorArea=$floorArea]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
    if (this.layout != null) {
      json[r'layout'] = this.layout;
    } else {
      json[r'layout'] = null;
    }
    if (this.floor != null) {
      json[r'floor'] = this.floor;
    } else {
      json[r'floor'] = null;
    }
    if (this.floorArea != null) {
      json[r'floor_area'] = this.floorArea;
    } else {
      json[r'floor_area'] = null;
    }
    return json;
  }

  /// Returns a new [PublicListingUnit] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicListingUnit? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PublicListingUnit[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PublicListingUnit[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicListingUnit(
        kind: UnitKind.fromJson(json[r'kind'])!,
        layout: mapValueOfType<String>(json, r'layout'),
        floor: mapValueOfType<int>(json, r'floor'),
        floorArea: mapValueOfType<double>(json, r'floor_area'),
      );
    }
    return null;
  }

  static List<PublicListingUnit> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicListingUnit>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicListingUnit.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicListingUnit> mapFromJson(dynamic json) {
    final map = <String, PublicListingUnit>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicListingUnit.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicListingUnit-objects as value to a dart map
  static Map<String, List<PublicListingUnit>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PublicListingUnit>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicListingUnit.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
  };
}

