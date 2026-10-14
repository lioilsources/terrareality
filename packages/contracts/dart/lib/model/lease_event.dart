//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseEvent {
  /// Returns a new [LeaseEvent] instance.
  LeaseEvent({
    required this.seq,
    required this.kind,
    this.payload = const {},
    required this.prevHash,
    required this.hash,
    required this.createdAt,
  });

  int seq;

  String kind;

  Map<String, Object> payload;

  String prevHash;

  String hash;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseEvent &&
    other.seq == seq &&
    other.kind == kind &&
    _deepEquality.equals(other.payload, payload) &&
    other.prevHash == prevHash &&
    other.hash == hash &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (seq.hashCode) +
    (kind.hashCode) +
    (payload.hashCode) +
    (prevHash.hashCode) +
    (hash.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'LeaseEvent[seq=$seq, kind=$kind, payload=$payload, prevHash=$prevHash, hash=$hash, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'seq'] = this.seq;
      json[r'kind'] = this.kind;
      json[r'payload'] = this.payload;
      json[r'prev_hash'] = this.prevHash;
      json[r'hash'] = this.hash;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [LeaseEvent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseEvent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseEvent[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseEvent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseEvent(
        seq: mapValueOfType<int>(json, r'seq')!,
        kind: mapValueOfType<String>(json, r'kind')!,
        payload: mapCastOfType<String, Object>(json, r'payload')!,
        prevHash: mapValueOfType<String>(json, r'prev_hash')!,
        hash: mapValueOfType<String>(json, r'hash')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<LeaseEvent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseEvent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseEvent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseEvent> mapFromJson(dynamic json) {
    final map = <String, LeaseEvent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseEvent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseEvent-objects as value to a dart map
  static Map<String, List<LeaseEvent>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseEvent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseEvent.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'seq',
    'kind',
    'payload',
    'prev_hash',
    'hash',
    'created_at',
  };
}

