//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ChangePasswordRequest {
  /// Returns a new [ChangePasswordRequest] instance.
  ChangePasswordRequest({
    this.currentPassword,
    required this.newPassword,
  });

  /// Required when the account already has a password.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? currentPassword;

  /// At least 12 characters; checked against breached-password lists (error code password_breached).
  String newPassword;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChangePasswordRequest &&
    other.currentPassword == currentPassword &&
    other.newPassword == newPassword;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (currentPassword == null ? 0 : currentPassword!.hashCode) +
    (newPassword.hashCode);

  @override
  String toString() => 'ChangePasswordRequest[currentPassword=$currentPassword, newPassword=$newPassword]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.currentPassword != null) {
      json[r'current_password'] = this.currentPassword;
    } else {
      json[r'current_password'] = null;
    }
      json[r'new_password'] = this.newPassword;
    return json;
  }

  /// Returns a new [ChangePasswordRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ChangePasswordRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ChangePasswordRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ChangePasswordRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ChangePasswordRequest(
        currentPassword: mapValueOfType<String>(json, r'current_password'),
        newPassword: mapValueOfType<String>(json, r'new_password')!,
      );
    }
    return null;
  }

  static List<ChangePasswordRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ChangePasswordRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ChangePasswordRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ChangePasswordRequest> mapFromJson(dynamic json) {
    final map = <String, ChangePasswordRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ChangePasswordRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ChangePasswordRequest-objects as value to a dart map
  static Map<String, List<ChangePasswordRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ChangePasswordRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ChangePasswordRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'new_password',
  };
}

