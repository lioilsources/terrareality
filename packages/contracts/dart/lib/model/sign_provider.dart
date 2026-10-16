//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SignProvider {
  /// Returns a new [SignProvider] instance.
  SignProvider({
    required this.id,
    required this.level,
  });

  SignProviderIdEnum id;

  /// simple: prostý elektronický podpis (simple electronic signature); qualified: kvalifikovaný podpis (Bank iD SIGN).
  SignProviderLevelEnum level;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SignProvider &&
    other.id == id &&
    other.level == level;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (level.hashCode);

  @override
  String toString() => 'SignProvider[id=$id, level=$level]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'level'] = this.level;
    return json;
  }

  /// Returns a new [SignProvider] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SignProvider? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SignProvider[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SignProvider[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SignProvider(
        id: SignProviderIdEnum.fromJson(json[r'id'])!,
        level: SignProviderLevelEnum.fromJson(json[r'level'])!,
      );
    }
    return null;
  }

  static List<SignProvider> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SignProvider>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SignProvider.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SignProvider> mapFromJson(dynamic json) {
    final map = <String, SignProvider>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SignProvider.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SignProvider-objects as value to a dart map
  static Map<String, List<SignProvider>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SignProvider>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SignProvider.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'level',
  };
}


class SignProviderIdEnum {
  /// Instantiate a new enum with the provided [value].
  const SignProviderIdEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const mock = SignProviderIdEnum._(r'mock');
  static const bankidSign = SignProviderIdEnum._(r'bankid_sign');

  /// List of all possible values in this [enum][SignProviderIdEnum].
  static const values = <SignProviderIdEnum>[
    mock,
    bankidSign,
  ];

  static SignProviderIdEnum? fromJson(dynamic value) => SignProviderIdEnumTypeTransformer().decode(value);

  static List<SignProviderIdEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SignProviderIdEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SignProviderIdEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SignProviderIdEnum] to String,
/// and [decode] dynamic data back to [SignProviderIdEnum].
class SignProviderIdEnumTypeTransformer {
  factory SignProviderIdEnumTypeTransformer() => _instance ??= const SignProviderIdEnumTypeTransformer._();

  const SignProviderIdEnumTypeTransformer._();

  String encode(SignProviderIdEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SignProviderIdEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SignProviderIdEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'mock': return SignProviderIdEnum.mock;
        case r'bankid_sign': return SignProviderIdEnum.bankidSign;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SignProviderIdEnumTypeTransformer] instance.
  static SignProviderIdEnumTypeTransformer? _instance;
}


/// simple: prostý elektronický podpis (simple electronic signature); qualified: kvalifikovaný podpis (Bank iD SIGN).
class SignProviderLevelEnum {
  /// Instantiate a new enum with the provided [value].
  const SignProviderLevelEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const simple = SignProviderLevelEnum._(r'simple');
  static const qualified = SignProviderLevelEnum._(r'qualified');

  /// List of all possible values in this [enum][SignProviderLevelEnum].
  static const values = <SignProviderLevelEnum>[
    simple,
    qualified,
  ];

  static SignProviderLevelEnum? fromJson(dynamic value) => SignProviderLevelEnumTypeTransformer().decode(value);

  static List<SignProviderLevelEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SignProviderLevelEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SignProviderLevelEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SignProviderLevelEnum] to String,
/// and [decode] dynamic data back to [SignProviderLevelEnum].
class SignProviderLevelEnumTypeTransformer {
  factory SignProviderLevelEnumTypeTransformer() => _instance ??= const SignProviderLevelEnumTypeTransformer._();

  const SignProviderLevelEnumTypeTransformer._();

  String encode(SignProviderLevelEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SignProviderLevelEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SignProviderLevelEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'simple': return SignProviderLevelEnum.simple;
        case r'qualified': return SignProviderLevelEnum.qualified;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SignProviderLevelEnumTypeTransformer] instance.
  static SignProviderLevelEnumTypeTransformer? _instance;
}


