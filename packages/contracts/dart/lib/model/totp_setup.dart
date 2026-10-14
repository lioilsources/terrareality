//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TotpSetup {
  /// Returns a new [TotpSetup] instance.
  TotpSetup({
    required this.secret,
    required this.otpauthUri,
  });

  /// Base32 secret for manual entry.
  String secret;

  /// otpauth:// URI to render as a QR code.
  String otpauthUri;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TotpSetup &&
    other.secret == secret &&
    other.otpauthUri == otpauthUri;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (secret.hashCode) +
    (otpauthUri.hashCode);

  @override
  String toString() => 'TotpSetup[secret=$secret, otpauthUri=$otpauthUri]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'secret'] = this.secret;
      json[r'otpauth_uri'] = this.otpauthUri;
    return json;
  }

  /// Returns a new [TotpSetup] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TotpSetup? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TotpSetup[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TotpSetup[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TotpSetup(
        secret: mapValueOfType<String>(json, r'secret')!,
        otpauthUri: mapValueOfType<String>(json, r'otpauth_uri')!,
      );
    }
    return null;
  }

  static List<TotpSetup> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TotpSetup>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TotpSetup.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TotpSetup> mapFromJson(dynamic json) {
    final map = <String, TotpSetup>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TotpSetup.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TotpSetup-objects as value to a dart map
  static Map<String, List<TotpSetup>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TotpSetup>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TotpSetup.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'secret',
    'otpauth_uri',
  };
}

