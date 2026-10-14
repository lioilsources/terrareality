//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequest {
  /// Returns a new [RegisterRequest] instance.
  RegisterRequest({
    required this.email,
    required this.password,
    required this.displayName,
    this.locale,
    required this.acceptTermsVersion,
    required this.acceptPrivacyVersion,
    this.marketing = false,
    this.client,
  });

  String email;

  String password;

  String displayName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UserLocale? locale;

  String acceptTermsVersion;

  String acceptPrivacyVersion;

  bool marketing;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ClientKind? client;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequest &&
    other.email == email &&
    other.password == password &&
    other.displayName == displayName &&
    other.locale == locale &&
    other.acceptTermsVersion == acceptTermsVersion &&
    other.acceptPrivacyVersion == acceptPrivacyVersion &&
    other.marketing == marketing &&
    other.client == client;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (password.hashCode) +
    (displayName.hashCode) +
    (locale == null ? 0 : locale!.hashCode) +
    (acceptTermsVersion.hashCode) +
    (acceptPrivacyVersion.hashCode) +
    (marketing.hashCode) +
    (client == null ? 0 : client!.hashCode);

  @override
  String toString() => 'RegisterRequest[email=$email, password=$password, displayName=$displayName, locale=$locale, acceptTermsVersion=$acceptTermsVersion, acceptPrivacyVersion=$acceptPrivacyVersion, marketing=$marketing, client=$client]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'password'] = this.password;
      json[r'display_name'] = this.displayName;
    if (this.locale != null) {
      json[r'locale'] = this.locale;
    } else {
      json[r'locale'] = null;
    }
      json[r'accept_terms_version'] = this.acceptTermsVersion;
      json[r'accept_privacy_version'] = this.acceptPrivacyVersion;
      json[r'marketing'] = this.marketing;
    if (this.client != null) {
      json[r'client'] = this.client;
    } else {
      json[r'client'] = null;
    }
    return json;
  }

  /// Returns a new [RegisterRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RegisterRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RegisterRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RegisterRequest(
        email: mapValueOfType<String>(json, r'email')!,
        password: mapValueOfType<String>(json, r'password')!,
        displayName: mapValueOfType<String>(json, r'display_name')!,
        locale: UserLocale.fromJson(json[r'locale']),
        acceptTermsVersion: mapValueOfType<String>(json, r'accept_terms_version')!,
        acceptPrivacyVersion: mapValueOfType<String>(json, r'accept_privacy_version')!,
        marketing: mapValueOfType<bool>(json, r'marketing') ?? false,
        client: ClientKind.fromJson(json[r'client']),
      );
    }
    return null;
  }

  static List<RegisterRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequest> mapFromJson(dynamic json) {
    final map = <String, RegisterRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequest-objects as value to a dart map
  static Map<String, List<RegisterRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'password',
    'display_name',
    'accept_terms_version',
    'accept_privacy_version',
  };
}

