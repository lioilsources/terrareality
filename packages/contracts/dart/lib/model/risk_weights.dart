//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RiskWeights {
  /// Returns a new [RiskWeights] instance.
  RiskWeights({
    this.weights = const {},
    this.defaults = const {},
  });

  Map<String, int> weights;

  Map<String, int> defaults;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RiskWeights &&
    _deepEquality.equals(other.weights, weights) &&
    _deepEquality.equals(other.defaults, defaults);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (weights.hashCode) +
    (defaults.hashCode);

  @override
  String toString() => 'RiskWeights[weights=$weights, defaults=$defaults]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'weights'] = this.weights;
      json[r'defaults'] = this.defaults;
    return json;
  }

  /// Returns a new [RiskWeights] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RiskWeights? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RiskWeights[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RiskWeights[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RiskWeights(
        weights: mapCastOfType<String, int>(json, r'weights')!,
        defaults: mapCastOfType<String, int>(json, r'defaults')!,
      );
    }
    return null;
  }

  static List<RiskWeights> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RiskWeights>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RiskWeights.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RiskWeights> mapFromJson(dynamic json) {
    final map = <String, RiskWeights>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RiskWeights.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RiskWeights-objects as value to a dart map
  static Map<String, List<RiskWeights>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RiskWeights>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RiskWeights.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'weights',
    'defaults',
  };
}

