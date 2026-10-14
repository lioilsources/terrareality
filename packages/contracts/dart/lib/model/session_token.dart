//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SessionToken {
  /// Returns a new [SessionToken] instance.
  SessionToken({
    required this.token,
    required this.expiresAt,
  });

  String token;

  DateTime expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SessionToken &&
    other.token == token &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (token.hashCode) +
    (expiresAt.hashCode);

  @override
  String toString() => 'SessionToken[token=$token, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'token'] = this.token;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [SessionToken] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SessionToken? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SessionToken[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SessionToken[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SessionToken(
        token: mapValueOfType<String>(json, r'token')!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
      );
    }
    return null;
  }

  static List<SessionToken> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SessionToken>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionToken.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SessionToken> mapFromJson(dynamic json) {
    final map = <String, SessionToken>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SessionToken.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SessionToken-objects as value to a dart map
  static Map<String, List<SessionToken>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SessionToken>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SessionToken.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'token',
    'expires_at',
  };
}

