//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GetPushConfig200Response {
  /// Returns a new [GetPushConfig200Response] instance.
  GetPushConfig200Response({
    required this.vapidPublicKey,
  });

  /// Uncompressed P-256 point, base64url.
  String vapidPublicKey;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GetPushConfig200Response &&
    other.vapidPublicKey == vapidPublicKey;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (vapidPublicKey.hashCode);

  @override
  String toString() => 'GetPushConfig200Response[vapidPublicKey=$vapidPublicKey]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'vapid_public_key'] = this.vapidPublicKey;
    return json;
  }

  /// Returns a new [GetPushConfig200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetPushConfig200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GetPushConfig200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GetPushConfig200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetPushConfig200Response(
        vapidPublicKey: mapValueOfType<String>(json, r'vapid_public_key')!,
      );
    }
    return null;
  }

  static List<GetPushConfig200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GetPushConfig200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetPushConfig200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetPushConfig200Response> mapFromJson(dynamic json) {
    final map = <String, GetPushConfig200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetPushConfig200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetPushConfig200Response-objects as value to a dart map
  static Map<String, List<GetPushConfig200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GetPushConfig200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetPushConfig200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'vapid_public_key',
  };
}

