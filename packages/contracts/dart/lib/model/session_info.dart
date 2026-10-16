//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SessionInfo {
  /// Returns a new [SessionInfo] instance.
  SessionInfo({
    required this.id,
    required this.client,
    required this.expiresAt,
    this.userAgent,
    this.ip,
    required this.createdAt,
    required this.lastSeenAt,
    required this.current,
    this.impersonated,
  });

  String id;

  String client;

  /// When the session ends unless it is used again (impersonation sessions do not slide).
  DateTime expiresAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? userAgent;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? ip;

  DateTime createdAt;

  DateTime lastSeenAt;

  bool current;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? impersonated;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SessionInfo &&
    other.id == id &&
    other.client == client &&
    other.expiresAt == expiresAt &&
    other.userAgent == userAgent &&
    other.ip == ip &&
    other.createdAt == createdAt &&
    other.lastSeenAt == lastSeenAt &&
    other.current == current &&
    other.impersonated == impersonated;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (client.hashCode) +
    (expiresAt.hashCode) +
    (userAgent == null ? 0 : userAgent!.hashCode) +
    (ip == null ? 0 : ip!.hashCode) +
    (createdAt.hashCode) +
    (lastSeenAt.hashCode) +
    (current.hashCode) +
    (impersonated == null ? 0 : impersonated!.hashCode);

  @override
  String toString() => 'SessionInfo[id=$id, client=$client, expiresAt=$expiresAt, userAgent=$userAgent, ip=$ip, createdAt=$createdAt, lastSeenAt=$lastSeenAt, current=$current, impersonated=$impersonated]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'client'] = this.client;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
    if (this.userAgent != null) {
      json[r'user_agent'] = this.userAgent;
    } else {
      json[r'user_agent'] = null;
    }
    if (this.ip != null) {
      json[r'ip'] = this.ip;
    } else {
      json[r'ip'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
      json[r'last_seen_at'] = this.lastSeenAt.toUtc().toIso8601String();
      json[r'current'] = this.current;
    if (this.impersonated != null) {
      json[r'impersonated'] = this.impersonated;
    } else {
      json[r'impersonated'] = null;
    }
    return json;
  }

  /// Returns a new [SessionInfo] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SessionInfo? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SessionInfo[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SessionInfo[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SessionInfo(
        id: mapValueOfType<String>(json, r'id')!,
        client: mapValueOfType<String>(json, r'client')!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
        userAgent: mapValueOfType<String>(json, r'user_agent'),
        ip: mapValueOfType<String>(json, r'ip'),
        createdAt: mapDateTime(json, r'created_at', r'')!,
        lastSeenAt: mapDateTime(json, r'last_seen_at', r'')!,
        current: mapValueOfType<bool>(json, r'current')!,
        impersonated: mapValueOfType<bool>(json, r'impersonated'),
      );
    }
    return null;
  }

  static List<SessionInfo> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SessionInfo>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionInfo.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SessionInfo> mapFromJson(dynamic json) {
    final map = <String, SessionInfo>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SessionInfo.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SessionInfo-objects as value to a dart map
  static Map<String, List<SessionInfo>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SessionInfo>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SessionInfo.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'client',
    'expires_at',
    'created_at',
    'last_seen_at',
    'current',
  };
}

