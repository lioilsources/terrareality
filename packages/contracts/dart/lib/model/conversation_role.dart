//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ConversationRole {
  /// Instantiate a new enum with the provided [value].
  const ConversationRole._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const seeker = ConversationRole._(r'seeker');
  static const owner = ConversationRole._(r'owner');

  /// List of all possible values in this [enum][ConversationRole].
  static const values = <ConversationRole>[
    seeker,
    owner,
  ];

  static ConversationRole? fromJson(dynamic value) => ConversationRoleTypeTransformer().decode(value);

  static List<ConversationRole> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConversationRole>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConversationRole.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ConversationRole] to String,
/// and [decode] dynamic data back to [ConversationRole].
class ConversationRoleTypeTransformer {
  factory ConversationRoleTypeTransformer() => _instance ??= const ConversationRoleTypeTransformer._();

  const ConversationRoleTypeTransformer._();

  String encode(ConversationRole data) => data.value;

  /// Decodes a [dynamic value][data] to a ConversationRole.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ConversationRole? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'seeker': return ConversationRole.seeker;
        case r'owner': return ConversationRole.owner;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ConversationRoleTypeTransformer] instance.
  static ConversationRoleTypeTransformer? _instance;
}

