//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ClientKind {
  /// Instantiate a new enum with the provided [value].
  const ClientKind._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const web = ClientKind._(r'web');
  static const mobile = ClientKind._(r'mobile');

  /// List of all possible values in this [enum][ClientKind].
  static const values = <ClientKind>[
    web,
    mobile,
  ];

  static ClientKind? fromJson(dynamic value) => ClientKindTypeTransformer().decode(value);

  static List<ClientKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ClientKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ClientKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ClientKind] to String,
/// and [decode] dynamic data back to [ClientKind].
class ClientKindTypeTransformer {
  factory ClientKindTypeTransformer() => _instance ??= const ClientKindTypeTransformer._();

  const ClientKindTypeTransformer._();

  String encode(ClientKind data) => data.value;

  /// Decodes a [dynamic value][data] to a ClientKind.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ClientKind? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'web': return ClientKind.web;
        case r'mobile': return ClientKind.mobile;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ClientKindTypeTransformer] instance.
  static ClientKindTypeTransformer? _instance;
}

