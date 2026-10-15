//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioSummary {
  /// Returns a new [PortfolioSummary] instance.
  PortfolioSummary({
    required this.summary,
    this.changes = const [],
    this.actions = const [],
    required this.model,
    required this.createdAt,
  });

  String summary;

  List<String> changes;

  List<String> actions;

  String model;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioSummary &&
    other.summary == summary &&
    _deepEquality.equals(other.changes, changes) &&
    _deepEquality.equals(other.actions, actions) &&
    other.model == model &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (summary.hashCode) +
    (changes.hashCode) +
    (actions.hashCode) +
    (model.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'PortfolioSummary[summary=$summary, changes=$changes, actions=$actions, model=$model, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'summary'] = this.summary;
      json[r'changes'] = this.changes;
      json[r'actions'] = this.actions;
      json[r'model'] = this.model;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [PortfolioSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioSummary(
        summary: mapValueOfType<String>(json, r'summary')!,
        changes: json[r'changes'] is Iterable
            ? (json[r'changes'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        actions: json[r'actions'] is Iterable
            ? (json[r'actions'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        model: mapValueOfType<String>(json, r'model')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<PortfolioSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioSummary> mapFromJson(dynamic json) {
    final map = <String, PortfolioSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioSummary-objects as value to a dart map
  static Map<String, List<PortfolioSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'summary',
    'changes',
    'actions',
    'model',
    'created_at',
  };
}

