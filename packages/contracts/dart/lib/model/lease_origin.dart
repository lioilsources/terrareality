//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// platform: drafted and signed here; imported: signed on paper before the landlord joined.
class LeaseOrigin {
  /// Instantiate a new enum with the provided [value].
  const LeaseOrigin._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const platform = LeaseOrigin._(r'platform');
  static const imported = LeaseOrigin._(r'imported');

  /// List of all possible values in this [enum][LeaseOrigin].
  static const values = <LeaseOrigin>[
    platform,
    imported,
  ];

  static LeaseOrigin? fromJson(dynamic value) => LeaseOriginTypeTransformer().decode(value);

  static List<LeaseOrigin> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseOrigin>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseOrigin.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeaseOrigin] to String,
/// and [decode] dynamic data back to [LeaseOrigin].
class LeaseOriginTypeTransformer {
  factory LeaseOriginTypeTransformer() => _instance ??= const LeaseOriginTypeTransformer._();

  const LeaseOriginTypeTransformer._();

  String encode(LeaseOrigin data) => data.value;

  /// Decodes a [dynamic value][data] to a LeaseOrigin.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeaseOrigin? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'platform': return LeaseOrigin.platform;
        case r'imported': return LeaseOrigin.imported;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LeaseOriginTypeTransformer] instance.
  static LeaseOriginTypeTransformer? _instance;
}

