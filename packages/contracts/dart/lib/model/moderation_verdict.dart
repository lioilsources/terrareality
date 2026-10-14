//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ModerationVerdict {
  /// Instantiate a new enum with the provided [value].
  const ModerationVerdict._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const dismiss = ModerationVerdict._(r'dismiss');
  static const warn = ModerationVerdict._(r'warn');
  static const removeMessage = ModerationVerdict._(r'remove_message');
  static const suspendUser = ModerationVerdict._(r'suspend_user');

  /// List of all possible values in this [enum][ModerationVerdict].
  static const values = <ModerationVerdict>[
    dismiss,
    warn,
    removeMessage,
    suspendUser,
  ];

  static ModerationVerdict? fromJson(dynamic value) => ModerationVerdictTypeTransformer().decode(value);

  static List<ModerationVerdict> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ModerationVerdict>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ModerationVerdict.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ModerationVerdict] to String,
/// and [decode] dynamic data back to [ModerationVerdict].
class ModerationVerdictTypeTransformer {
  factory ModerationVerdictTypeTransformer() => _instance ??= const ModerationVerdictTypeTransformer._();

  const ModerationVerdictTypeTransformer._();

  String encode(ModerationVerdict data) => data.value;

  /// Decodes a [dynamic value][data] to a ModerationVerdict.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ModerationVerdict? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'dismiss': return ModerationVerdict.dismiss;
        case r'warn': return ModerationVerdict.warn;
        case r'remove_message': return ModerationVerdict.removeMessage;
        case r'suspend_user': return ModerationVerdict.suspendUser;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ModerationVerdictTypeTransformer] instance.
  static ModerationVerdictTypeTransformer? _instance;
}

