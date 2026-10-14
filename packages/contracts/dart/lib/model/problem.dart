//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Problem {
  /// Returns a new [Problem] instance.
  Problem({
    required this.type,
    required this.title,
    required this.status,
    this.detail,
    this.instance,
    this.code,
    this.errors = const [],
  });

  String type;

  String title;

  int status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? detail;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? instance;

  /// Stable machine-readable error code for client-side translation, e.g. invalid_credentials.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? code;

  /// Field errors (code invalid_fields).
  List<FieldError> errors;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Problem &&
    other.type == type &&
    other.title == title &&
    other.status == status &&
    other.detail == detail &&
    other.instance == instance &&
    other.code == code &&
    _deepEquality.equals(other.errors, errors);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (title.hashCode) +
    (status.hashCode) +
    (detail == null ? 0 : detail!.hashCode) +
    (instance == null ? 0 : instance!.hashCode) +
    (code == null ? 0 : code!.hashCode) +
    (errors.hashCode);

  @override
  String toString() => 'Problem[type=$type, title=$title, status=$status, detail=$detail, instance=$instance, code=$code, errors=$errors]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
      json[r'title'] = this.title;
      json[r'status'] = this.status;
    if (this.detail != null) {
      json[r'detail'] = this.detail;
    } else {
      json[r'detail'] = null;
    }
    if (this.instance != null) {
      json[r'instance'] = this.instance;
    } else {
      json[r'instance'] = null;
    }
    if (this.code != null) {
      json[r'code'] = this.code;
    } else {
      json[r'code'] = null;
    }
      json[r'errors'] = this.errors;
    return json;
  }

  /// Returns a new [Problem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Problem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Problem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Problem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Problem(
        type: mapValueOfType<String>(json, r'type')!,
        title: mapValueOfType<String>(json, r'title')!,
        status: mapValueOfType<int>(json, r'status')!,
        detail: mapValueOfType<String>(json, r'detail'),
        instance: mapValueOfType<String>(json, r'instance'),
        code: mapValueOfType<String>(json, r'code'),
        errors: FieldError.listFromJson(json[r'errors']),
      );
    }
    return null;
  }

  static List<Problem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Problem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Problem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Problem> mapFromJson(dynamic json) {
    final map = <String, Problem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Problem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Problem-objects as value to a dart map
  static Map<String, List<Problem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Problem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Problem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
    'title',
    'status',
  };
}

