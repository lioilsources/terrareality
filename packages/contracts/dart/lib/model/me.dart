//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Me {
  /// Returns a new [Me] instance.
  Me({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.displayName,
    required this.locale,
    this.phone,
    required this.phoneVerified,
    required this.verificationLevel,
    this.identity,
    required this.mfaEnabled,
    this.recoveryCodesLeft,
    this.hasPassword,
    required this.isStaff,
    required this.createdAt,
    this.impersonator,
    this.organizations = const [],
  });

  String id;

  String email;

  bool emailVerified;

  String displayName;

  UserLocale locale;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? phone;

  bool phoneVerified;

  VerificationLevel verificationLevel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  VerifiedIdentity? identity;

  bool mfaEnabled;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? recoveryCodesLeft;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hasPassword;

  bool isStaff;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UserRef? impersonator;

  List<OrgMembership> organizations;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Me &&
    other.id == id &&
    other.email == email &&
    other.emailVerified == emailVerified &&
    other.displayName == displayName &&
    other.locale == locale &&
    other.phone == phone &&
    other.phoneVerified == phoneVerified &&
    other.verificationLevel == verificationLevel &&
    other.identity == identity &&
    other.mfaEnabled == mfaEnabled &&
    other.recoveryCodesLeft == recoveryCodesLeft &&
    other.hasPassword == hasPassword &&
    other.isStaff == isStaff &&
    other.createdAt == createdAt &&
    other.impersonator == impersonator &&
    _deepEquality.equals(other.organizations, organizations);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (email.hashCode) +
    (emailVerified.hashCode) +
    (displayName.hashCode) +
    (locale.hashCode) +
    (phone == null ? 0 : phone!.hashCode) +
    (phoneVerified.hashCode) +
    (verificationLevel.hashCode) +
    (identity == null ? 0 : identity!.hashCode) +
    (mfaEnabled.hashCode) +
    (recoveryCodesLeft == null ? 0 : recoveryCodesLeft!.hashCode) +
    (hasPassword == null ? 0 : hasPassword!.hashCode) +
    (isStaff.hashCode) +
    (createdAt.hashCode) +
    (impersonator == null ? 0 : impersonator!.hashCode) +
    (organizations.hashCode);

  @override
  String toString() => 'Me[id=$id, email=$email, emailVerified=$emailVerified, displayName=$displayName, locale=$locale, phone=$phone, phoneVerified=$phoneVerified, verificationLevel=$verificationLevel, identity=$identity, mfaEnabled=$mfaEnabled, recoveryCodesLeft=$recoveryCodesLeft, hasPassword=$hasPassword, isStaff=$isStaff, createdAt=$createdAt, impersonator=$impersonator, organizations=$organizations]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'email'] = this.email;
      json[r'email_verified'] = this.emailVerified;
      json[r'display_name'] = this.displayName;
      json[r'locale'] = this.locale;
    if (this.phone != null) {
      json[r'phone'] = this.phone;
    } else {
      json[r'phone'] = null;
    }
      json[r'phone_verified'] = this.phoneVerified;
      json[r'verification_level'] = this.verificationLevel;
    if (this.identity != null) {
      json[r'identity'] = this.identity;
    } else {
      json[r'identity'] = null;
    }
      json[r'mfa_enabled'] = this.mfaEnabled;
    if (this.recoveryCodesLeft != null) {
      json[r'recovery_codes_left'] = this.recoveryCodesLeft;
    } else {
      json[r'recovery_codes_left'] = null;
    }
    if (this.hasPassword != null) {
      json[r'has_password'] = this.hasPassword;
    } else {
      json[r'has_password'] = null;
    }
      json[r'is_staff'] = this.isStaff;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    if (this.impersonator != null) {
      json[r'impersonator'] = this.impersonator;
    } else {
      json[r'impersonator'] = null;
    }
      json[r'organizations'] = this.organizations;
    return json;
  }

  /// Returns a new [Me] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Me? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Me[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Me[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Me(
        id: mapValueOfType<String>(json, r'id')!,
        email: mapValueOfType<String>(json, r'email')!,
        emailVerified: mapValueOfType<bool>(json, r'email_verified')!,
        displayName: mapValueOfType<String>(json, r'display_name')!,
        locale: UserLocale.fromJson(json[r'locale'])!,
        phone: mapValueOfType<String>(json, r'phone'),
        phoneVerified: mapValueOfType<bool>(json, r'phone_verified')!,
        verificationLevel: VerificationLevel.fromJson(json[r'verification_level'])!,
        identity: VerifiedIdentity.fromJson(json[r'identity']),
        mfaEnabled: mapValueOfType<bool>(json, r'mfa_enabled')!,
        recoveryCodesLeft: mapValueOfType<int>(json, r'recovery_codes_left'),
        hasPassword: mapValueOfType<bool>(json, r'has_password'),
        isStaff: mapValueOfType<bool>(json, r'is_staff')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        impersonator: UserRef.fromJson(json[r'impersonator']),
        organizations: OrgMembership.listFromJson(json[r'organizations']),
      );
    }
    return null;
  }

  static List<Me> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Me>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Me.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Me> mapFromJson(dynamic json) {
    final map = <String, Me>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Me.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Me-objects as value to a dart map
  static Map<String, List<Me>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Me>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Me.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'email',
    'email_verified',
    'display_name',
    'locale',
    'phone_verified',
    'verification_level',
    'mfa_enabled',
    'is_staff',
    'created_at',
    'organizations',
  };
}

