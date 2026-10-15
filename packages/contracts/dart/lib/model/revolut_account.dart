//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RevolutAccount {
  /// Returns a new [RevolutAccount] instance.
  RevolutAccount({
    required this.connected,
    this.mode,
    this.connectedAt,
  });

  bool connected;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  RevolutMode? mode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? connectedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RevolutAccount &&
    other.connected == connected &&
    other.mode == mode &&
    other.connectedAt == connectedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (connected.hashCode) +
    (mode == null ? 0 : mode!.hashCode) +
    (connectedAt == null ? 0 : connectedAt!.hashCode);

  @override
  String toString() => 'RevolutAccount[connected=$connected, mode=$mode, connectedAt=$connectedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'connected'] = this.connected;
    if (this.mode != null) {
      json[r'mode'] = this.mode;
    } else {
      json[r'mode'] = null;
    }
    if (this.connectedAt != null) {
      json[r'connected_at'] = this.connectedAt!.toUtc().toIso8601String();
    } else {
      json[r'connected_at'] = null;
    }
    return json;
  }

  /// Returns a new [RevolutAccount] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RevolutAccount? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RevolutAccount[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RevolutAccount[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RevolutAccount(
        connected: mapValueOfType<bool>(json, r'connected')!,
        mode: RevolutMode.fromJson(json[r'mode']),
        connectedAt: mapDateTime(json, r'connected_at', r''),
      );
    }
    return null;
  }

  static List<RevolutAccount> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RevolutAccount>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RevolutAccount.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RevolutAccount> mapFromJson(dynamic json) {
    final map = <String, RevolutAccount>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RevolutAccount.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RevolutAccount-objects as value to a dart map
  static Map<String, List<RevolutAccount>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RevolutAccount>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RevolutAccount.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'connected',
  };
}

