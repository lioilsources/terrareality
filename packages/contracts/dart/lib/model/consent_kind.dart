//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ConsentKind {
  /// Instantiate a new enum with the provided [value].
  const ConsentKind._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const terms = ConsentKind._(r'terms');
  static const privacy = ConsentKind._(r'privacy');
  static const marketing = ConsentKind._(r'marketing');

  /// List of all possible values in this [enum][ConsentKind].
  static const values = <ConsentKind>[
    terms,
    privacy,
    marketing,
  ];

  static ConsentKind? fromJson(dynamic value) => ConsentKindTypeTransformer().decode(value);

  static List<ConsentKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConsentKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConsentKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ConsentKind] to String,
/// and [decode] dynamic data back to [ConsentKind].
class ConsentKindTypeTransformer {
  factory ConsentKindTypeTransformer() => _instance ??= const ConsentKindTypeTransformer._();

  const ConsentKindTypeTransformer._();

  String encode(ConsentKind data) => data.value;

  /// Decodes a [dynamic value][data] to a ConsentKind.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ConsentKind? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'terms': return ConsentKind.terms;
        case r'privacy': return ConsentKind.privacy;
        case r'marketing': return ConsentKind.marketing;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ConsentKindTypeTransformer] instance.
  static ConsentKindTypeTransformer? _instance;
}

