//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class Locale {
  /// Instantiate a new enum with the provided [value].
  const Locale._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const cs = Locale._(r'cs');
  static const en = Locale._(r'en');

  /// List of all possible values in this [enum][Locale].
  static const values = <Locale>[
    cs,
    en,
  ];

  static Locale? fromJson(dynamic value) => LocaleTypeTransformer().decode(value);

  static List<Locale> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Locale>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Locale.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [Locale] to String,
/// and [decode] dynamic data back to [Locale].
class LocaleTypeTransformer {
  factory LocaleTypeTransformer() => _instance ??= const LocaleTypeTransformer._();

  const LocaleTypeTransformer._();

  String encode(Locale data) => data.value;

  /// Decodes a [dynamic value][data] to a Locale.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  Locale? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'cs': return Locale.cs;
        case r'en': return Locale.en;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LocaleTypeTransformer] instance.
  static LocaleTypeTransformer? _instance;
}

