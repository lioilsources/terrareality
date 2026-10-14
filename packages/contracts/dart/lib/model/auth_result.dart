//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuthResult {
  /// Returns a new [AuthResult] instance.
  AuthResult({
    required this.status,
    this.session,
    this.mfaToken,
  });

  AuthResultStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  SessionToken? session;

  /// Present when status is mfa_required; valid for 5 minutes.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mfaToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthResult &&
    other.status == status &&
    other.session == session &&
    other.mfaToken == mfaToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode) +
    (session == null ? 0 : session!.hashCode) +
    (mfaToken == null ? 0 : mfaToken!.hashCode);

  @override
  String toString() => 'AuthResult[status=$status, session=$session, mfaToken=$mfaToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
    if (this.session != null) {
      json[r'session'] = this.session;
    } else {
      json[r'session'] = null;
    }
    if (this.mfaToken != null) {
      json[r'mfa_token'] = this.mfaToken;
    } else {
      json[r'mfa_token'] = null;
    }
    return json;
  }

  /// Returns a new [AuthResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AuthResult[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AuthResult[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AuthResult(
        status: AuthResultStatusEnum.fromJson(json[r'status'])!,
        session: SessionToken.fromJson(json[r'session']),
        mfaToken: mapValueOfType<String>(json, r'mfa_token'),
      );
    }
    return null;
  }

  static List<AuthResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthResult> mapFromJson(dynamic json) {
    final map = <String, AuthResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthResult-objects as value to a dart map
  static Map<String, List<AuthResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuthResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
  };
}


class AuthResultStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const AuthResultStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const authenticated = AuthResultStatusEnum._(r'authenticated');
  static const mfaRequired = AuthResultStatusEnum._(r'mfa_required');

  /// List of all possible values in this [enum][AuthResultStatusEnum].
  static const values = <AuthResultStatusEnum>[
    authenticated,
    mfaRequired,
  ];

  static AuthResultStatusEnum? fromJson(dynamic value) => AuthResultStatusEnumTypeTransformer().decode(value);

  static List<AuthResultStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthResultStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthResultStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AuthResultStatusEnum] to String,
/// and [decode] dynamic data back to [AuthResultStatusEnum].
class AuthResultStatusEnumTypeTransformer {
  factory AuthResultStatusEnumTypeTransformer() => _instance ??= const AuthResultStatusEnumTypeTransformer._();

  const AuthResultStatusEnumTypeTransformer._();

  String encode(AuthResultStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AuthResultStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AuthResultStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'authenticated': return AuthResultStatusEnum.authenticated;
        case r'mfa_required': return AuthResultStatusEnum.mfaRequired;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AuthResultStatusEnumTypeTransformer] instance.
  static AuthResultStatusEnumTypeTransformer? _instance;
}


