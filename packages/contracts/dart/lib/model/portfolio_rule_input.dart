//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioRuleInput {
  /// Returns a new [PortfolioRuleInput] instance.
  PortfolioRuleInput({
    this.municipality,
    this.groupId,
    required this.rules,
  });

  /// Admin path of the municipality.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? municipality;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? groupId;

  PortfolioRules rules;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioRuleInput &&
    other.municipality == municipality &&
    other.groupId == groupId &&
    other.rules == rules;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (municipality == null ? 0 : municipality!.hashCode) +
    (groupId == null ? 0 : groupId!.hashCode) +
    (rules.hashCode);

  @override
  String toString() => 'PortfolioRuleInput[municipality=$municipality, groupId=$groupId, rules=$rules]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.municipality != null) {
      json[r'municipality'] = this.municipality;
    } else {
      json[r'municipality'] = null;
    }
    if (this.groupId != null) {
      json[r'group_id'] = this.groupId;
    } else {
      json[r'group_id'] = null;
    }
      json[r'rules'] = this.rules;
    return json;
  }

  /// Returns a new [PortfolioRuleInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioRuleInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioRuleInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioRuleInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioRuleInput(
        municipality: mapValueOfType<String>(json, r'municipality'),
        groupId: mapValueOfType<String>(json, r'group_id'),
        rules: PortfolioRules.fromJson(json[r'rules'])!,
      );
    }
    return null;
  }

  static List<PortfolioRuleInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioRuleInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioRuleInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioRuleInput> mapFromJson(dynamic json) {
    final map = <String, PortfolioRuleInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioRuleInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioRuleInput-objects as value to a dart map
  static Map<String, List<PortfolioRuleInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioRuleInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioRuleInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'rules',
  };
}

