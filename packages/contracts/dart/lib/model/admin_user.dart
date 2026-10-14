//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminUser {
  /// Returns a new [AdminUser] instance.
  AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.verificationLevel,
    required this.mfaEnabled,
    required this.isStaff,
    this.pseudonymized,
    required this.createdAt,
  });

  String id;

  String email;

  String displayName;

  VerificationLevel verificationLevel;

  bool mfaEnabled;

  bool isStaff;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? pseudonymized;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminUser &&
    other.id == id &&
    other.email == email &&
    other.displayName == displayName &&
    other.verificationLevel == verificationLevel &&
    other.mfaEnabled == mfaEnabled &&
    other.isStaff == isStaff &&
    other.pseudonymized == pseudonymized &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (email.hashCode) +
    (displayName.hashCode) +
    (verificationLevel.hashCode) +
    (mfaEnabled.hashCode) +
    (isStaff.hashCode) +
    (pseudonymized == null ? 0 : pseudonymized!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'AdminUser[id=$id, email=$email, displayName=$displayName, verificationLevel=$verificationLevel, mfaEnabled=$mfaEnabled, isStaff=$isStaff, pseudonymized=$pseudonymized, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'email'] = this.email;
      json[r'display_name'] = this.displayName;
      json[r'verification_level'] = this.verificationLevel;
      json[r'mfa_enabled'] = this.mfaEnabled;
      json[r'is_staff'] = this.isStaff;
    if (this.pseudonymized != null) {
      json[r'pseudonymized'] = this.pseudonymized;
    } else {
      json[r'pseudonymized'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [AdminUser] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminUser? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AdminUser[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AdminUser[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AdminUser(
        id: mapValueOfType<String>(json, r'id')!,
        email: mapValueOfType<String>(json, r'email')!,
        displayName: mapValueOfType<String>(json, r'display_name')!,
        verificationLevel: VerificationLevel.fromJson(json[r'verification_level'])!,
        mfaEnabled: mapValueOfType<bool>(json, r'mfa_enabled')!,
        isStaff: mapValueOfType<bool>(json, r'is_staff')!,
        pseudonymized: mapValueOfType<bool>(json, r'pseudonymized'),
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<AdminUser> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminUser>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminUser.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminUser> mapFromJson(dynamic json) {
    final map = <String, AdminUser>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminUser.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminUser-objects as value to a dart map
  static Map<String, List<AdminUser>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminUser>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminUser.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'email',
    'display_name',
    'verification_level',
    'mfa_enabled',
    'is_staff',
    'created_at',
  };
}

