//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ConsentInput {
  /// Returns a new [ConsentInput] instance.
  ConsentInput({
    required this.kind,
    required this.version,
    required this.granted,
  });

  ConsentKind kind;

  String version;

  bool granted;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ConsentInput &&
    other.kind == kind &&
    other.version == version &&
    other.granted == granted;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (version.hashCode) +
    (granted.hashCode);

  @override
  String toString() => 'ConsentInput[kind=$kind, version=$version, granted=$granted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'version'] = this.version;
      json[r'granted'] = this.granted;
    return json;
  }

  /// Returns a new [ConsentInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConsentInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ConsentInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ConsentInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ConsentInput(
        kind: ConsentKind.fromJson(json[r'kind'])!,
        version: mapValueOfType<String>(json, r'version')!,
        granted: mapValueOfType<bool>(json, r'granted')!,
      );
    }
    return null;
  }

  static List<ConsentInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConsentInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConsentInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConsentInput> mapFromJson(dynamic json) {
    final map = <String, ConsentInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConsentInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConsentInput-objects as value to a dart map
  static Map<String, List<ConsentInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ConsentInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConsentInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'version',
    'granted',
  };
}

