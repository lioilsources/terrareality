//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// none → email → phone → identity (BankID). Features require a minimum level.
class VerificationLevel {
  /// Instantiate a new enum with the provided [value].
  const VerificationLevel._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const none = VerificationLevel._(r'none');
  static const email = VerificationLevel._(r'email');
  static const phone = VerificationLevel._(r'phone');
  static const identity = VerificationLevel._(r'identity');

  /// List of all possible values in this [enum][VerificationLevel].
  static const values = <VerificationLevel>[
    none,
    email,
    phone,
    identity,
  ];

  static VerificationLevel? fromJson(dynamic value) => VerificationLevelTypeTransformer().decode(value);

  static List<VerificationLevel> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VerificationLevel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VerificationLevel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [VerificationLevel] to String,
/// and [decode] dynamic data back to [VerificationLevel].
class VerificationLevelTypeTransformer {
  factory VerificationLevelTypeTransformer() => _instance ??= const VerificationLevelTypeTransformer._();

  const VerificationLevelTypeTransformer._();

  String encode(VerificationLevel data) => data.value;

  /// Decodes a [dynamic value][data] to a VerificationLevel.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  VerificationLevel? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'none': return VerificationLevel.none;
        case r'email': return VerificationLevel.email;
        case r'phone': return VerificationLevel.phone;
        case r'identity': return VerificationLevel.identity;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [VerificationLevelTypeTransformer] instance.
  static VerificationLevelTypeTransformer? _instance;
}

