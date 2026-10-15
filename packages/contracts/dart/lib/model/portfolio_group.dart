//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioGroup {
  /// Returns a new [PortfolioGroup] instance.
  PortfolioGroup({
    required this.id,
    required this.name,
    required this.color,
    this.propertyIds = const [],
    this.leaseIds = const [],
  });

  String id;

  String name;

  String color;

  List<String> propertyIds;

  List<String> leaseIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioGroup &&
    other.id == id &&
    other.name == name &&
    other.color == color &&
    _deepEquality.equals(other.propertyIds, propertyIds) &&
    _deepEquality.equals(other.leaseIds, leaseIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (color.hashCode) +
    (propertyIds.hashCode) +
    (leaseIds.hashCode);

  @override
  String toString() => 'PortfolioGroup[id=$id, name=$name, color=$color, propertyIds=$propertyIds, leaseIds=$leaseIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'color'] = this.color;
      json[r'property_ids'] = this.propertyIds;
      json[r'lease_ids'] = this.leaseIds;
    return json;
  }

  /// Returns a new [PortfolioGroup] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioGroup? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioGroup[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioGroup[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioGroup(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        color: mapValueOfType<String>(json, r'color')!,
        propertyIds: json[r'property_ids'] is Iterable
            ? (json[r'property_ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        leaseIds: json[r'lease_ids'] is Iterable
            ? (json[r'lease_ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<PortfolioGroup> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioGroup>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioGroup.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioGroup> mapFromJson(dynamic json) {
    final map = <String, PortfolioGroup>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioGroup.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioGroup-objects as value to a dart map
  static Map<String, List<PortfolioGroup>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioGroup>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioGroup.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'color',
    'property_ids',
    'lease_ids',
  };
}

