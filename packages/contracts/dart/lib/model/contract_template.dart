//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ContractTemplate {
  /// Returns a new [ContractTemplate] instance.
  ContractTemplate({
    required this.name,
    required this.title,
    required this.reviewed,
  });

  String name;

  String title;

  /// Reviewed by a lawyer for this version.
  bool reviewed;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ContractTemplate &&
    other.name == name &&
    other.title == title &&
    other.reviewed == reviewed;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (title.hashCode) +
    (reviewed.hashCode);

  @override
  String toString() => 'ContractTemplate[name=$name, title=$title, reviewed=$reviewed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'title'] = this.title;
      json[r'reviewed'] = this.reviewed;
    return json;
  }

  /// Returns a new [ContractTemplate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContractTemplate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ContractTemplate[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ContractTemplate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ContractTemplate(
        name: mapValueOfType<String>(json, r'name')!,
        title: mapValueOfType<String>(json, r'title')!,
        reviewed: mapValueOfType<bool>(json, r'reviewed')!,
      );
    }
    return null;
  }

  static List<ContractTemplate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ContractTemplate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContractTemplate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContractTemplate> mapFromJson(dynamic json) {
    final map = <String, ContractTemplate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContractTemplate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContractTemplate-objects as value to a dart map
  static Map<String, List<ContractTemplate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ContractTemplate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ContractTemplate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'title',
    'reviewed',
  };
}

