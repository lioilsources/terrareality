//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseEventLog {
  /// Returns a new [LeaseEventLog] instance.
  LeaseEventLog({
    this.events = const [],
    required this.valid,
    required this.verified,
    this.error,
    required this.head,
  });

  List<LeaseEvent> events;

  bool valid;

  /// Events that verified before the first break.
  int verified;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? error;

  /// Hash of the last event.
  String head;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseEventLog &&
    _deepEquality.equals(other.events, events) &&
    other.valid == valid &&
    other.verified == verified &&
    other.error == error &&
    other.head == head;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (events.hashCode) +
    (valid.hashCode) +
    (verified.hashCode) +
    (error == null ? 0 : error!.hashCode) +
    (head.hashCode);

  @override
  String toString() => 'LeaseEventLog[events=$events, valid=$valid, verified=$verified, error=$error, head=$head]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'events'] = this.events;
      json[r'valid'] = this.valid;
      json[r'verified'] = this.verified;
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
      json[r'head'] = this.head;
    return json;
  }

  /// Returns a new [LeaseEventLog] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseEventLog? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseEventLog[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseEventLog[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseEventLog(
        events: LeaseEvent.listFromJson(json[r'events']),
        valid: mapValueOfType<bool>(json, r'valid')!,
        verified: mapValueOfType<int>(json, r'verified')!,
        error: mapValueOfType<String>(json, r'error'),
        head: mapValueOfType<String>(json, r'head')!,
      );
    }
    return null;
  }

  static List<LeaseEventLog> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseEventLog>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseEventLog.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseEventLog> mapFromJson(dynamic json) {
    final map = <String, LeaseEventLog>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseEventLog.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseEventLog-objects as value to a dart map
  static Map<String, List<LeaseEventLog>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseEventLog>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseEventLog.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'events',
    'valid',
    'verified',
    'head',
  };
}

