//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class UnitKind {
  /// Instantiate a new enum with the provided [value].
  const UnitKind._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const apartment = UnitKind._(r'apartment');
  static const house = UnitKind._(r'house');
  static const room = UnitKind._(r'room');
  static const parking = UnitKind._(r'parking');
  static const storage = UnitKind._(r'storage');
  static const commercial = UnitKind._(r'commercial');

  /// List of all possible values in this [enum][UnitKind].
  static const values = <UnitKind>[
    apartment,
    house,
    room,
    parking,
    storage,
    commercial,
  ];

  static UnitKind? fromJson(dynamic value) => UnitKindTypeTransformer().decode(value);

  static List<UnitKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnitKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnitKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UnitKind] to String,
/// and [decode] dynamic data back to [UnitKind].
class UnitKindTypeTransformer {
  factory UnitKindTypeTransformer() => _instance ??= const UnitKindTypeTransformer._();

  const UnitKindTypeTransformer._();

  String encode(UnitKind data) => data.value;

  /// Decodes a [dynamic value][data] to a UnitKind.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UnitKind? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'apartment': return UnitKind.apartment;
        case r'house': return UnitKind.house;
        case r'room': return UnitKind.room;
        case r'parking': return UnitKind.parking;
        case r'storage': return UnitKind.storage;
        case r'commercial': return UnitKind.commercial;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UnitKindTypeTransformer] instance.
  static UnitKindTypeTransformer? _instance;
}

