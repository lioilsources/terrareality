//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PushDeviceInputKeys {
  /// Returns a new [PushDeviceInputKeys] instance.
  PushDeviceInputKeys({
    this.p256dh,
    this.auth,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? p256dh;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? auth;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PushDeviceInputKeys &&
    other.p256dh == p256dh &&
    other.auth == auth;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (p256dh == null ? 0 : p256dh!.hashCode) +
    (auth == null ? 0 : auth!.hashCode);

  @override
  String toString() => 'PushDeviceInputKeys[p256dh=$p256dh, auth=$auth]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.p256dh != null) {
      json[r'p256dh'] = this.p256dh;
    } else {
      json[r'p256dh'] = null;
    }
    if (this.auth != null) {
      json[r'auth'] = this.auth;
    } else {
      json[r'auth'] = null;
    }
    return json;
  }

  /// Returns a new [PushDeviceInputKeys] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PushDeviceInputKeys? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PushDeviceInputKeys[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PushDeviceInputKeys[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PushDeviceInputKeys(
        p256dh: mapValueOfType<String>(json, r'p256dh'),
        auth: mapValueOfType<String>(json, r'auth'),
      );
    }
    return null;
  }

  static List<PushDeviceInputKeys> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PushDeviceInputKeys>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PushDeviceInputKeys.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PushDeviceInputKeys> mapFromJson(dynamic json) {
    final map = <String, PushDeviceInputKeys>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PushDeviceInputKeys.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PushDeviceInputKeys-objects as value to a dart map
  static Map<String, List<PushDeviceInputKeys>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PushDeviceInputKeys>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PushDeviceInputKeys.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

