//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateIncomeUpload201Response {
  /// Returns a new [CreateIncomeUpload201Response] instance.
  CreateIncomeUpload201Response({
    required this.key,
    required this.uploadUrl,
  });

  String key;

  String uploadUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateIncomeUpload201Response &&
    other.key == key &&
    other.uploadUrl == uploadUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (key.hashCode) +
    (uploadUrl.hashCode);

  @override
  String toString() => 'CreateIncomeUpload201Response[key=$key, uploadUrl=$uploadUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'key'] = this.key;
      json[r'upload_url'] = this.uploadUrl;
    return json;
  }

  /// Returns a new [CreateIncomeUpload201Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateIncomeUpload201Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateIncomeUpload201Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateIncomeUpload201Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateIncomeUpload201Response(
        key: mapValueOfType<String>(json, r'key')!,
        uploadUrl: mapValueOfType<String>(json, r'upload_url')!,
      );
    }
    return null;
  }

  static List<CreateIncomeUpload201Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateIncomeUpload201Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateIncomeUpload201Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateIncomeUpload201Response> mapFromJson(dynamic json) {
    final map = <String, CreateIncomeUpload201Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateIncomeUpload201Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateIncomeUpload201Response-objects as value to a dart map
  static Map<String, List<CreateIncomeUpload201Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateIncomeUpload201Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateIncomeUpload201Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'key',
    'upload_url',
  };
}

