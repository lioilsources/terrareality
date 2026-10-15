//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// top = boost in search order (topování), highlight = visual highlight (zvýraznění), bundle = both.
class PromoProductKind {
  /// Instantiate a new enum with the provided [value].
  const PromoProductKind._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const top = PromoProductKind._(r'top');
  static const highlight = PromoProductKind._(r'highlight');
  static const bundle = PromoProductKind._(r'bundle');

  /// List of all possible values in this [enum][PromoProductKind].
  static const values = <PromoProductKind>[
    top,
    highlight,
    bundle,
  ];

  static PromoProductKind? fromJson(dynamic value) => PromoProductKindTypeTransformer().decode(value);

  static List<PromoProductKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PromoProductKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PromoProductKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PromoProductKind] to String,
/// and [decode] dynamic data back to [PromoProductKind].
class PromoProductKindTypeTransformer {
  factory PromoProductKindTypeTransformer() => _instance ??= const PromoProductKindTypeTransformer._();

  const PromoProductKindTypeTransformer._();

  String encode(PromoProductKind data) => data.value;

  /// Decodes a [dynamic value][data] to a PromoProductKind.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PromoProductKind? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'top': return PromoProductKind.top;
        case r'highlight': return PromoProductKind.highlight;
        case r'bundle': return PromoProductKind.bundle;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PromoProductKindTypeTransformer] instance.
  static PromoProductKindTypeTransformer? _instance;
}

