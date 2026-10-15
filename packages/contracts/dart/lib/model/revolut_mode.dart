//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class RevolutMode {
  /// Instantiate a new enum with the provided [value].
  const RevolutMode._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const sandbox = RevolutMode._(r'sandbox');
  static const live = RevolutMode._(r'live');

  /// List of all possible values in this [enum][RevolutMode].
  static const values = <RevolutMode>[
    sandbox,
    live,
  ];

  static RevolutMode? fromJson(dynamic value) => RevolutModeTypeTransformer().decode(value);

  static List<RevolutMode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RevolutMode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RevolutMode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RevolutMode] to String,
/// and [decode] dynamic data back to [RevolutMode].
class RevolutModeTypeTransformer {
  factory RevolutModeTypeTransformer() => _instance ??= const RevolutModeTypeTransformer._();

  const RevolutModeTypeTransformer._();

  String encode(RevolutMode data) => data.value;

  /// Decodes a [dynamic value][data] to a RevolutMode.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RevolutMode? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'sandbox': return RevolutMode.sandbox;
        case r'live': return RevolutMode.live;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RevolutModeTypeTransformer] instance.
  static RevolutModeTypeTransformer? _instance;
}

