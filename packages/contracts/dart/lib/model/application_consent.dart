//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApplicationConsent {
  /// Returns a new [ApplicationConsent] instance.
  ApplicationConsent({
    required this.userId,
    required this.displayName,
    this.consentedAt,
  });

  String userId;

  String displayName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? consentedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ApplicationConsent &&
    other.userId == userId &&
    other.displayName == displayName &&
    other.consentedAt == consentedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (displayName.hashCode) +
    (consentedAt == null ? 0 : consentedAt!.hashCode);

  @override
  String toString() => 'ApplicationConsent[userId=$userId, displayName=$displayName, consentedAt=$consentedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user_id'] = this.userId;
      json[r'display_name'] = this.displayName;
    if (this.consentedAt != null) {
      json[r'consented_at'] = this.consentedAt!.toUtc().toIso8601String();
    } else {
      json[r'consented_at'] = null;
    }
    return json;
  }

  /// Returns a new [ApplicationConsent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApplicationConsent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ApplicationConsent[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ApplicationConsent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ApplicationConsent(
        userId: mapValueOfType<String>(json, r'user_id')!,
        displayName: mapValueOfType<String>(json, r'display_name')!,
        consentedAt: mapDateTime(json, r'consented_at', r''),
      );
    }
    return null;
  }

  static List<ApplicationConsent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplicationConsent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicationConsent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApplicationConsent> mapFromJson(dynamic json) {
    final map = <String, ApplicationConsent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApplicationConsent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApplicationConsent-objects as value to a dart map
  static Map<String, List<ApplicationConsent>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ApplicationConsent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApplicationConsent.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user_id',
    'display_name',
  };
}

