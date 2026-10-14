//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserRef {
  /// Returns a new [UserRef] instance.
  UserRef({
    required this.id,
    required this.email,
    this.displayName,
  });

  String id;

  String email;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? displayName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserRef &&
    other.id == id &&
    other.email == email &&
    other.displayName == displayName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (email.hashCode) +
    (displayName == null ? 0 : displayName!.hashCode);

  @override
  String toString() => 'UserRef[id=$id, email=$email, displayName=$displayName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'email'] = this.email;
    if (this.displayName != null) {
      json[r'display_name'] = this.displayName;
    } else {
      json[r'display_name'] = null;
    }
    return json;
  }

  /// Returns a new [UserRef] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserRef? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UserRef[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UserRef[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserRef(
        id: mapValueOfType<String>(json, r'id')!,
        email: mapValueOfType<String>(json, r'email')!,
        displayName: mapValueOfType<String>(json, r'display_name'),
      );
    }
    return null;
  }

  static List<UserRef> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserRef>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserRef.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserRef> mapFromJson(dynamic json) {
    final map = <String, UserRef>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserRef.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserRef-objects as value to a dart map
  static Map<String, List<UserRef>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserRef>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserRef.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'email',
  };
}

