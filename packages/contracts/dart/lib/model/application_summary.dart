//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApplicationSummary {
  /// Returns a new [ApplicationSummary] instance.
  ApplicationSummary({
    required this.summary,
    this.strengths = const [],
    this.gaps = const [],
    this.model,
  });

  String summary;

  List<String> strengths;

  List<String> gaps;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? model;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ApplicationSummary &&
    other.summary == summary &&
    _deepEquality.equals(other.strengths, strengths) &&
    _deepEquality.equals(other.gaps, gaps) &&
    other.model == model;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (summary.hashCode) +
    (strengths.hashCode) +
    (gaps.hashCode) +
    (model == null ? 0 : model!.hashCode);

  @override
  String toString() => 'ApplicationSummary[summary=$summary, strengths=$strengths, gaps=$gaps, model=$model]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'summary'] = this.summary;
      json[r'strengths'] = this.strengths;
      json[r'gaps'] = this.gaps;
    if (this.model != null) {
      json[r'model'] = this.model;
    } else {
      json[r'model'] = null;
    }
    return json;
  }

  /// Returns a new [ApplicationSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApplicationSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ApplicationSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ApplicationSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ApplicationSummary(
        summary: mapValueOfType<String>(json, r'summary')!,
        strengths: json[r'strengths'] is Iterable
            ? (json[r'strengths'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        gaps: json[r'gaps'] is Iterable
            ? (json[r'gaps'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        model: mapValueOfType<String>(json, r'model'),
      );
    }
    return null;
  }

  static List<ApplicationSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplicationSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicationSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApplicationSummary> mapFromJson(dynamic json) {
    final map = <String, ApplicationSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApplicationSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApplicationSummary-objects as value to a dart map
  static Map<String, List<ApplicationSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ApplicationSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApplicationSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'summary',
    'strengths',
    'gaps',
  };
}

