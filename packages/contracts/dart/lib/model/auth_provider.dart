//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuthProvider {
  /// Returns a new [AuthProvider] instance.
  AuthProvider({
    required this.id,
    required this.mock,
  });

  AuthProviderIdEnum id;

  /// True when the provider is the local mock IdP.
  bool mock;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthProvider &&
    other.id == id &&
    other.mock == mock;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (mock.hashCode);

  @override
  String toString() => 'AuthProvider[id=$id, mock=$mock]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'mock'] = this.mock;
    return json;
  }

  /// Returns a new [AuthProvider] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthProvider? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AuthProvider[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AuthProvider[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AuthProvider(
        id: AuthProviderIdEnum.fromJson(json[r'id'])!,
        mock: mapValueOfType<bool>(json, r'mock')!,
      );
    }
    return null;
  }

  static List<AuthProvider> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthProvider>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthProvider.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthProvider> mapFromJson(dynamic json) {
    final map = <String, AuthProvider>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthProvider.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthProvider-objects as value to a dart map
  static Map<String, List<AuthProvider>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuthProvider>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthProvider.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'mock',
  };
}


class AuthProviderIdEnum {
  /// Instantiate a new enum with the provided [value].
  const AuthProviderIdEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const google = AuthProviderIdEnum._(r'google');
  static const apple = AuthProviderIdEnum._(r'apple');

  /// List of all possible values in this [enum][AuthProviderIdEnum].
  static const values = <AuthProviderIdEnum>[
    google,
    apple,
  ];

  static AuthProviderIdEnum? fromJson(dynamic value) => AuthProviderIdEnumTypeTransformer().decode(value);

  static List<AuthProviderIdEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthProviderIdEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthProviderIdEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AuthProviderIdEnum] to String,
/// and [decode] dynamic data back to [AuthProviderIdEnum].
class AuthProviderIdEnumTypeTransformer {
  factory AuthProviderIdEnumTypeTransformer() => _instance ??= const AuthProviderIdEnumTypeTransformer._();

  const AuthProviderIdEnumTypeTransformer._();

  String encode(AuthProviderIdEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AuthProviderIdEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AuthProviderIdEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'google': return AuthProviderIdEnum.google;
        case r'apple': return AuthProviderIdEnum.apple;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AuthProviderIdEnumTypeTransformer] instance.
  static AuthProviderIdEnumTypeTransformer? _instance;
}


