//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ConnectBankRequest {
  /// Returns a new [ConnectBankRequest] instance.
  ConnectBankRequest({
    this.institutionId,
    required this.redirectUri,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? institutionId;

  String redirectUri;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ConnectBankRequest &&
    other.institutionId == institutionId &&
    other.redirectUri == redirectUri;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (institutionId == null ? 0 : institutionId!.hashCode) +
    (redirectUri.hashCode);

  @override
  String toString() => 'ConnectBankRequest[institutionId=$institutionId, redirectUri=$redirectUri]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.institutionId != null) {
      json[r'institution_id'] = this.institutionId;
    } else {
      json[r'institution_id'] = null;
    }
      json[r'redirect_uri'] = this.redirectUri;
    return json;
  }

  /// Returns a new [ConnectBankRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConnectBankRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ConnectBankRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ConnectBankRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ConnectBankRequest(
        institutionId: mapValueOfType<String>(json, r'institution_id'),
        redirectUri: mapValueOfType<String>(json, r'redirect_uri')!,
      );
    }
    return null;
  }

  static List<ConnectBankRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConnectBankRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConnectBankRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConnectBankRequest> mapFromJson(dynamic json) {
    final map = <String, ConnectBankRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConnectBankRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConnectBankRequest-objects as value to a dart map
  static Map<String, List<ConnectBankRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ConnectBankRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConnectBankRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'redirect_uri',
  };
}

