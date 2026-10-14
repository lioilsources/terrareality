//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PrescreenAnswerQuestion {
  /// Returns a new [PrescreenAnswerQuestion] instance.
  PrescreenAnswerQuestion({
    this.cs,
    this.en,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? cs;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? en;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PrescreenAnswerQuestion &&
    other.cs == cs &&
    other.en == en;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (cs == null ? 0 : cs!.hashCode) +
    (en == null ? 0 : en!.hashCode);

  @override
  String toString() => 'PrescreenAnswerQuestion[cs=$cs, en=$en]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.cs != null) {
      json[r'cs'] = this.cs;
    } else {
      json[r'cs'] = null;
    }
    if (this.en != null) {
      json[r'en'] = this.en;
    } else {
      json[r'en'] = null;
    }
    return json;
  }

  /// Returns a new [PrescreenAnswerQuestion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PrescreenAnswerQuestion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PrescreenAnswerQuestion[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PrescreenAnswerQuestion[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PrescreenAnswerQuestion(
        cs: mapValueOfType<String>(json, r'cs'),
        en: mapValueOfType<String>(json, r'en'),
      );
    }
    return null;
  }

  static List<PrescreenAnswerQuestion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrescreenAnswerQuestion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrescreenAnswerQuestion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PrescreenAnswerQuestion> mapFromJson(dynamic json) {
    final map = <String, PrescreenAnswerQuestion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PrescreenAnswerQuestion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PrescreenAnswerQuestion-objects as value to a dart map
  static Map<String, List<PrescreenAnswerQuestion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PrescreenAnswerQuestion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PrescreenAnswerQuestion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

