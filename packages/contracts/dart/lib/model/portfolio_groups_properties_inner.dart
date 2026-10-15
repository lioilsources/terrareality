//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioGroupsPropertiesInner {
  /// Returns a new [PortfolioGroupsPropertiesInner] instance.
  PortfolioGroupsPropertiesInner({
    required this.id,
    required this.name,
    required this.address,
  });

  String id;

  String name;

  String address;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioGroupsPropertiesInner &&
    other.id == id &&
    other.name == name &&
    other.address == address;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (address.hashCode);

  @override
  String toString() => 'PortfolioGroupsPropertiesInner[id=$id, name=$name, address=$address]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'address'] = this.address;
    return json;
  }

  /// Returns a new [PortfolioGroupsPropertiesInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioGroupsPropertiesInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioGroupsPropertiesInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioGroupsPropertiesInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioGroupsPropertiesInner(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        address: mapValueOfType<String>(json, r'address')!,
      );
    }
    return null;
  }

  static List<PortfolioGroupsPropertiesInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioGroupsPropertiesInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioGroupsPropertiesInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioGroupsPropertiesInner> mapFromJson(dynamic json) {
    final map = <String, PortfolioGroupsPropertiesInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioGroupsPropertiesInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioGroupsPropertiesInner-objects as value to a dart map
  static Map<String, List<PortfolioGroupsPropertiesInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioGroupsPropertiesInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioGroupsPropertiesInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'address',
  };
}

