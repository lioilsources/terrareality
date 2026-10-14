//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MessageFlag {
  /// Instantiate a new enum with the provided [value].
  const MessageFlag._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const contactPhone = MessageFlag._(r'contact_phone');
  static const contactEmail = MessageFlag._(r'contact_email');
  static const contactBankAccount = MessageFlag._(r'contact_bank_account');
  static const advancePayment = MessageFlag._(r'advance_payment');

  /// List of all possible values in this [enum][MessageFlag].
  static const values = <MessageFlag>[
    contactPhone,
    contactEmail,
    contactBankAccount,
    advancePayment,
  ];

  static MessageFlag? fromJson(dynamic value) => MessageFlagTypeTransformer().decode(value);

  static List<MessageFlag> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MessageFlag>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MessageFlag.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MessageFlag] to String,
/// and [decode] dynamic data back to [MessageFlag].
class MessageFlagTypeTransformer {
  factory MessageFlagTypeTransformer() => _instance ??= const MessageFlagTypeTransformer._();

  const MessageFlagTypeTransformer._();

  String encode(MessageFlag data) => data.value;

  /// Decodes a [dynamic value][data] to a MessageFlag.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MessageFlag? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'contact_phone': return MessageFlag.contactPhone;
        case r'contact_email': return MessageFlag.contactEmail;
        case r'contact_bank_account': return MessageFlag.contactBankAccount;
        case r'advance_payment': return MessageFlag.advancePayment;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MessageFlagTypeTransformer] instance.
  static MessageFlagTypeTransformer? _instance;
}

