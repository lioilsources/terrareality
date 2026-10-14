//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class UserLocale {
  /// Instantiate a new enum with the provided [value].
  const UserLocale._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const cs = UserLocale._(r'cs');
  static const en = UserLocale._(r'en');

  /// List of all possible values in this [enum][UserLocale].
  static const values = <UserLocale>[
    cs,
    en,
  ];

  static UserLocale? fromJson(dynamic value) => UserLocaleTypeTransformer().decode(value);

  static List<UserLocale> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserLocale>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserLocale.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UserLocale] to String,
/// and [decode] dynamic data back to [UserLocale].
class UserLocaleTypeTransformer {
  factory UserLocaleTypeTransformer() => _instance ??= const UserLocaleTypeTransformer._();

  const UserLocaleTypeTransformer._();

  String encode(UserLocale data) => data.value;

  /// Decodes a [dynamic value][data] to a UserLocale.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UserLocale? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'cs': return UserLocale.cs;
        case r'en': return UserLocale.en;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UserLocaleTypeTransformer] instance.
  static UserLocaleTypeTransformer? _instance;
}

