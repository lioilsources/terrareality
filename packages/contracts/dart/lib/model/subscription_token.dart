//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SubscriptionToken {
  /// Returns a new [SubscriptionToken] instance.
  SubscriptionToken({
    required this.channel,
    required this.token,
    required this.expiresAt,
  });

  String channel;

  String token;

  DateTime expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubscriptionToken &&
    other.channel == channel &&
    other.token == token &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (channel.hashCode) +
    (token.hashCode) +
    (expiresAt.hashCode);

  @override
  String toString() => 'SubscriptionToken[channel=$channel, token=$token, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'channel'] = this.channel;
      json[r'token'] = this.token;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [SubscriptionToken] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubscriptionToken? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SubscriptionToken[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SubscriptionToken[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SubscriptionToken(
        channel: mapValueOfType<String>(json, r'channel')!,
        token: mapValueOfType<String>(json, r'token')!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
      );
    }
    return null;
  }

  static List<SubscriptionToken> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubscriptionToken>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubscriptionToken.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubscriptionToken> mapFromJson(dynamic json) {
    final map = <String, SubscriptionToken>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubscriptionToken.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubscriptionToken-objects as value to a dart map
  static Map<String, List<SubscriptionToken>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubscriptionToken>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubscriptionToken.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'channel',
    'token',
    'expires_at',
  };
}

