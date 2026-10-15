//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioRuleList {
  /// Returns a new [PortfolioRuleList] instance.
  PortfolioRuleList({
    this.rules = const [],
    this.municipalities = const [],
    required this.defaults,
  });

  List<PortfolioRule> rules;

  List<PortfolioRuleListMunicipalitiesInner> municipalities;

  PortfolioRules defaults;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioRuleList &&
    _deepEquality.equals(other.rules, rules) &&
    _deepEquality.equals(other.municipalities, municipalities) &&
    other.defaults == defaults;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rules.hashCode) +
    (municipalities.hashCode) +
    (defaults.hashCode);

  @override
  String toString() => 'PortfolioRuleList[rules=$rules, municipalities=$municipalities, defaults=$defaults]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'rules'] = this.rules;
      json[r'municipalities'] = this.municipalities;
      json[r'defaults'] = this.defaults;
    return json;
  }

  /// Returns a new [PortfolioRuleList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioRuleList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioRuleList[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioRuleList[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioRuleList(
        rules: PortfolioRule.listFromJson(json[r'rules']),
        municipalities: PortfolioRuleListMunicipalitiesInner.listFromJson(json[r'municipalities']),
        defaults: PortfolioRules.fromJson(json[r'defaults'])!,
      );
    }
    return null;
  }

  static List<PortfolioRuleList> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioRuleList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioRuleList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioRuleList> mapFromJson(dynamic json) {
    final map = <String, PortfolioRuleList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioRuleList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioRuleList-objects as value to a dart map
  static Map<String, List<PortfolioRuleList>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioRuleList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioRuleList.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'rules',
    'municipalities',
    'defaults',
  };
}

