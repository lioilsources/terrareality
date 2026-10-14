//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ListingUnit {
  /// Returns a new [ListingUnit] instance.
  ListingUnit({
    required this.id,
    required this.kind,
    required this.label,
    this.floor,
    this.floorArea,
    this.layout,
    this.parentId,
    this.parentLabel,
  });

  String id;

  UnitKind kind;

  String label;

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
  String? parentId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? parentLabel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListingUnit &&
    other.id == id &&
    other.kind == kind &&
    other.label == label &&
    other.floor == floor &&
    other.floorArea == floorArea &&
    other.layout == layout &&
    other.parentId == parentId &&
    other.parentLabel == parentLabel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (kind.hashCode) +
    (label.hashCode) +
    (floor == null ? 0 : floor!.hashCode) +
    (floorArea == null ? 0 : floorArea!.hashCode) +
    (layout == null ? 0 : layout!.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (parentLabel == null ? 0 : parentLabel!.hashCode);

  @override
  String toString() => 'ListingUnit[id=$id, kind=$kind, label=$label, floor=$floor, floorArea=$floorArea, layout=$layout, parentId=$parentId, parentLabel=$parentLabel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'kind'] = this.kind;
      json[r'label'] = this.label;
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
    if (this.parentId != null) {
      json[r'parent_id'] = this.parentId;
    } else {
      json[r'parent_id'] = null;
    }
    if (this.parentLabel != null) {
      json[r'parent_label'] = this.parentLabel;
    } else {
      json[r'parent_label'] = null;
    }
    return json;
  }

  /// Returns a new [ListingUnit] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListingUnit? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ListingUnit[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ListingUnit[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ListingUnit(
        id: mapValueOfType<String>(json, r'id')!,
        kind: UnitKind.fromJson(json[r'kind'])!,
        label: mapValueOfType<String>(json, r'label')!,
        floor: mapValueOfType<int>(json, r'floor'),
        floorArea: mapValueOfType<double>(json, r'floor_area'),
        layout: mapValueOfType<String>(json, r'layout'),
        parentId: mapValueOfType<String>(json, r'parent_id'),
        parentLabel: mapValueOfType<String>(json, r'parent_label'),
      );
    }
    return null;
  }

  static List<ListingUnit> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingUnit>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingUnit.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListingUnit> mapFromJson(dynamic json) {
    final map = <String, ListingUnit>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListingUnit.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListingUnit-objects as value to a dart map
  static Map<String, List<ListingUnit>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListingUnit>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListingUnit.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'kind',
    'label',
  };
}

