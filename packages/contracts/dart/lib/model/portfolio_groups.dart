//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioGroups {
  /// Returns a new [PortfolioGroups] instance.
  PortfolioGroups({
    this.groups = const [],
    this.properties = const [],
  });

  List<PortfolioGroup> groups;

  List<PortfolioGroupsPropertiesInner> properties;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioGroups &&
    _deepEquality.equals(other.groups, groups) &&
    _deepEquality.equals(other.properties, properties);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (groups.hashCode) +
    (properties.hashCode);

  @override
  String toString() => 'PortfolioGroups[groups=$groups, properties=$properties]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'groups'] = this.groups;
      json[r'properties'] = this.properties;
    return json;
  }

  /// Returns a new [PortfolioGroups] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioGroups? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioGroups[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioGroups[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioGroups(
        groups: PortfolioGroup.listFromJson(json[r'groups']),
        properties: PortfolioGroupsPropertiesInner.listFromJson(json[r'properties']),
      );
    }
    return null;
  }

  static List<PortfolioGroups> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioGroups>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioGroups.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioGroups> mapFromJson(dynamic json) {
    final map = <String, PortfolioGroups>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioGroups.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioGroups-objects as value to a dart map
  static Map<String, List<PortfolioGroups>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioGroups>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioGroups.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'groups',
    'properties',
  };
}

