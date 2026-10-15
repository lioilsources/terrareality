//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioGroupInput {
  /// Returns a new [PortfolioGroupInput] instance.
  PortfolioGroupInput({
    required this.name,
    this.color,
    this.propertyIds = const [],
    this.leaseIds = const [],
  });

  String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? color;

  List<String> propertyIds;

  List<String> leaseIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioGroupInput &&
    other.name == name &&
    other.color == color &&
    _deepEquality.equals(other.propertyIds, propertyIds) &&
    _deepEquality.equals(other.leaseIds, leaseIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (color == null ? 0 : color!.hashCode) +
    (propertyIds.hashCode) +
    (leaseIds.hashCode);

  @override
  String toString() => 'PortfolioGroupInput[name=$name, color=$color, propertyIds=$propertyIds, leaseIds=$leaseIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
    if (this.color != null) {
      json[r'color'] = this.color;
    } else {
      json[r'color'] = null;
    }
      json[r'property_ids'] = this.propertyIds;
      json[r'lease_ids'] = this.leaseIds;
    return json;
  }

  /// Returns a new [PortfolioGroupInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioGroupInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioGroupInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioGroupInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioGroupInput(
        name: mapValueOfType<String>(json, r'name')!,
        color: mapValueOfType<String>(json, r'color'),
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

  static List<PortfolioGroupInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioGroupInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioGroupInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioGroupInput> mapFromJson(dynamic json) {
    final map = <String, PortfolioGroupInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioGroupInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioGroupInput-objects as value to a dart map
  static Map<String, List<PortfolioGroupInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioGroupInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioGroupInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}

