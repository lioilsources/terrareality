//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OidcCallbackRequest {
  /// Returns a new [OidcCallbackRequest] instance.
  OidcCallbackRequest({
    required this.code,
    required this.state,
    required this.redirectUri,
    this.client,
  });

  String code;

  String state;

  String redirectUri;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ClientKind? client;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OidcCallbackRequest &&
    other.code == code &&
    other.state == state &&
    other.redirectUri == redirectUri &&
    other.client == client;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code.hashCode) +
    (state.hashCode) +
    (redirectUri.hashCode) +
    (client == null ? 0 : client!.hashCode);

  @override
  String toString() => 'OidcCallbackRequest[code=$code, state=$state, redirectUri=$redirectUri, client=$client]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'code'] = this.code;
      json[r'state'] = this.state;
      json[r'redirect_uri'] = this.redirectUri;
    if (this.client != null) {
      json[r'client'] = this.client;
    } else {
      json[r'client'] = null;
    }
    return json;
  }

  /// Returns a new [OidcCallbackRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OidcCallbackRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "OidcCallbackRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "OidcCallbackRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return OidcCallbackRequest(
        code: mapValueOfType<String>(json, r'code')!,
        state: mapValueOfType<String>(json, r'state')!,
        redirectUri: mapValueOfType<String>(json, r'redirect_uri')!,
        client: ClientKind.fromJson(json[r'client']),
      );
    }
    return null;
  }

  static List<OidcCallbackRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OidcCallbackRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OidcCallbackRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OidcCallbackRequest> mapFromJson(dynamic json) {
    final map = <String, OidcCallbackRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OidcCallbackRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OidcCallbackRequest-objects as value to a dart map
  static Map<String, List<OidcCallbackRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OidcCallbackRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OidcCallbackRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'state',
    'redirect_uri',
  };
}

