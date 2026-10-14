//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RealtimeToken {
  /// Returns a new [RealtimeToken] instance.
  RealtimeToken({
    required this.url,
    required this.token,
    required this.expiresAt,
    required this.channel,
  });

  /// Centrifugo websocket URL.
  String url;

  String token;

  DateTime expiresAt;

  /// The caller's user channel (joined automatically).
  String channel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RealtimeToken &&
    other.url == url &&
    other.token == token &&
    other.expiresAt == expiresAt &&
    other.channel == channel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (url.hashCode) +
    (token.hashCode) +
    (expiresAt.hashCode) +
    (channel.hashCode);

  @override
  String toString() => 'RealtimeToken[url=$url, token=$token, expiresAt=$expiresAt, channel=$channel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'url'] = this.url;
      json[r'token'] = this.token;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
      json[r'channel'] = this.channel;
    return json;
  }

  /// Returns a new [RealtimeToken] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RealtimeToken? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RealtimeToken[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RealtimeToken[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RealtimeToken(
        url: mapValueOfType<String>(json, r'url')!,
        token: mapValueOfType<String>(json, r'token')!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
        channel: mapValueOfType<String>(json, r'channel')!,
      );
    }
    return null;
  }

  static List<RealtimeToken> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RealtimeToken>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RealtimeToken.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RealtimeToken> mapFromJson(dynamic json) {
    final map = <String, RealtimeToken>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RealtimeToken.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RealtimeToken-objects as value to a dart map
  static Map<String, List<RealtimeToken>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RealtimeToken>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RealtimeToken.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'url',
    'token',
    'expires_at',
    'channel',
  };
}

