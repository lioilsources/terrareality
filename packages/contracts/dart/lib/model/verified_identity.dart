//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VerifiedIdentity {
  /// Returns a new [VerifiedIdentity] instance.
  VerifiedIdentity({
    required this.provider,
    this.givenName,
    this.familyName,
    this.birthdate,
    required this.verifiedAt,
  });

  String provider;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? givenName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? familyName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? birthdate;

  DateTime verifiedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is VerifiedIdentity &&
    other.provider == provider &&
    other.givenName == givenName &&
    other.familyName == familyName &&
    other.birthdate == birthdate &&
    other.verifiedAt == verifiedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (provider.hashCode) +
    (givenName == null ? 0 : givenName!.hashCode) +
    (familyName == null ? 0 : familyName!.hashCode) +
    (birthdate == null ? 0 : birthdate!.hashCode) +
    (verifiedAt.hashCode);

  @override
  String toString() => 'VerifiedIdentity[provider=$provider, givenName=$givenName, familyName=$familyName, birthdate=$birthdate, verifiedAt=$verifiedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'provider'] = this.provider;
    if (this.givenName != null) {
      json[r'given_name'] = this.givenName;
    } else {
      json[r'given_name'] = null;
    }
    if (this.familyName != null) {
      json[r'family_name'] = this.familyName;
    } else {
      json[r'family_name'] = null;
    }
    if (this.birthdate != null) {
      json[r'birthdate'] = _dateFormatter.format(this.birthdate!.toUtc());
    } else {
      json[r'birthdate'] = null;
    }
      json[r'verified_at'] = this.verifiedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [VerifiedIdentity] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VerifiedIdentity? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "VerifiedIdentity[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "VerifiedIdentity[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return VerifiedIdentity(
        provider: mapValueOfType<String>(json, r'provider')!,
        givenName: mapValueOfType<String>(json, r'given_name'),
        familyName: mapValueOfType<String>(json, r'family_name'),
        birthdate: mapDateTime(json, r'birthdate', r''),
        verifiedAt: mapDateTime(json, r'verified_at', r'')!,
      );
    }
    return null;
  }

  static List<VerifiedIdentity> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VerifiedIdentity>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VerifiedIdentity.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VerifiedIdentity> mapFromJson(dynamic json) {
    final map = <String, VerifiedIdentity>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VerifiedIdentity.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VerifiedIdentity-objects as value to a dart map
  static Map<String, List<VerifiedIdentity>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<VerifiedIdentity>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VerifiedIdentity.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'provider',
    'verified_at',
  };
}

