//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ListingCreate {
  /// Returns a new [ListingCreate] instance.
  ListingCreate({
    required this.ruianId,
    required this.unitKind,
    this.unitLabel,
    this.floor,
    this.floorArea,
    this.layout,
    this.parentUnitId,
    this.parentLayout,
    this.parentFloorArea,
  });

  int ruianId;

  UnitKind unitKind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitLabel;

  /// Minimum value: -5
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? floor;

  /// Minimum value: 1
  /// Maximum value: 100000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? floorArea;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? layout;

  /// Rooms only – an existing apartment at the same address.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? parentUnitId;

  /// Rooms only – layout of the apartment to create.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? parentLayout;

  /// Minimum value: 1
  /// Maximum value: 100000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? parentFloorArea;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListingCreate &&
    other.ruianId == ruianId &&
    other.unitKind == unitKind &&
    other.unitLabel == unitLabel &&
    other.floor == floor &&
    other.floorArea == floorArea &&
    other.layout == layout &&
    other.parentUnitId == parentUnitId &&
    other.parentLayout == parentLayout &&
    other.parentFloorArea == parentFloorArea;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ruianId.hashCode) +
    (unitKind.hashCode) +
    (unitLabel == null ? 0 : unitLabel!.hashCode) +
    (floor == null ? 0 : floor!.hashCode) +
    (floorArea == null ? 0 : floorArea!.hashCode) +
    (layout == null ? 0 : layout!.hashCode) +
    (parentUnitId == null ? 0 : parentUnitId!.hashCode) +
    (parentLayout == null ? 0 : parentLayout!.hashCode) +
    (parentFloorArea == null ? 0 : parentFloorArea!.hashCode);

  @override
  String toString() => 'ListingCreate[ruianId=$ruianId, unitKind=$unitKind, unitLabel=$unitLabel, floor=$floor, floorArea=$floorArea, layout=$layout, parentUnitId=$parentUnitId, parentLayout=$parentLayout, parentFloorArea=$parentFloorArea]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ruian_id'] = this.ruianId;
      json[r'unit_kind'] = this.unitKind;
    if (this.unitLabel != null) {
      json[r'unit_label'] = this.unitLabel;
    } else {
      json[r'unit_label'] = null;
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
    if (this.layout != null) {
      json[r'layout'] = this.layout;
    } else {
      json[r'layout'] = null;
    }
    if (this.parentUnitId != null) {
      json[r'parent_unit_id'] = this.parentUnitId;
    } else {
      json[r'parent_unit_id'] = null;
    }
    if (this.parentLayout != null) {
      json[r'parent_layout'] = this.parentLayout;
    } else {
      json[r'parent_layout'] = null;
    }
    if (this.parentFloorArea != null) {
      json[r'parent_floor_area'] = this.parentFloorArea;
    } else {
      json[r'parent_floor_area'] = null;
    }
    return json;
  }

  /// Returns a new [ListingCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListingCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ListingCreate[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ListingCreate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ListingCreate(
        ruianId: mapValueOfType<int>(json, r'ruian_id')!,
        unitKind: UnitKind.fromJson(json[r'unit_kind'])!,
        unitLabel: mapValueOfType<String>(json, r'unit_label'),
        floor: mapValueOfType<int>(json, r'floor'),
        floorArea: mapValueOfType<double>(json, r'floor_area'),
        layout: mapValueOfType<String>(json, r'layout'),
        parentUnitId: mapValueOfType<String>(json, r'parent_unit_id'),
        parentLayout: mapValueOfType<String>(json, r'parent_layout'),
        parentFloorArea: mapValueOfType<double>(json, r'parent_floor_area'),
      );
    }
    return null;
  }

  static List<ListingCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListingCreate> mapFromJson(dynamic json) {
    final map = <String, ListingCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListingCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListingCreate-objects as value to a dart map
  static Map<String, List<ListingCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListingCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListingCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ruian_id',
    'unit_kind',
  };
}

