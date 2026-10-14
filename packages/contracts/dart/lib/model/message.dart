//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Message {
  /// Returns a new [Message] instance.
  Message({
    required this.id,
    required this.conversationId,
    this.senderId,
    required this.kind,
    required this.body,
    this.flags = const [],
    required this.removed,
    required this.createdAt,
    this.attachments = const [],
  });

  String id;

  String conversationId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? senderId;

  MessageKindEnum kind;

  /// Contact details are masked as [•••]. Empty when removed by a moderator.
  String body;

  List<MessageFlag> flags;

  bool removed;

  DateTime createdAt;

  List<Attachment> attachments;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Message &&
    other.id == id &&
    other.conversationId == conversationId &&
    other.senderId == senderId &&
    other.kind == kind &&
    other.body == body &&
    _deepEquality.equals(other.flags, flags) &&
    other.removed == removed &&
    other.createdAt == createdAt &&
    _deepEquality.equals(other.attachments, attachments);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (conversationId.hashCode) +
    (senderId == null ? 0 : senderId!.hashCode) +
    (kind.hashCode) +
    (body.hashCode) +
    (flags.hashCode) +
    (removed.hashCode) +
    (createdAt.hashCode) +
    (attachments.hashCode);

  @override
  String toString() => 'Message[id=$id, conversationId=$conversationId, senderId=$senderId, kind=$kind, body=$body, flags=$flags, removed=$removed, createdAt=$createdAt, attachments=$attachments]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'conversation_id'] = this.conversationId;
    if (this.senderId != null) {
      json[r'sender_id'] = this.senderId;
    } else {
      json[r'sender_id'] = null;
    }
      json[r'kind'] = this.kind;
      json[r'body'] = this.body;
      json[r'flags'] = this.flags;
      json[r'removed'] = this.removed;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
      json[r'attachments'] = this.attachments;
    return json;
  }

  /// Returns a new [Message] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Message? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Message[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Message[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Message(
        id: mapValueOfType<String>(json, r'id')!,
        conversationId: mapValueOfType<String>(json, r'conversation_id')!,
        senderId: mapValueOfType<String>(json, r'sender_id'),
        kind: MessageKindEnum.fromJson(json[r'kind'])!,
        body: mapValueOfType<String>(json, r'body')!,
        flags: MessageFlag.listFromJson(json[r'flags']),
        removed: mapValueOfType<bool>(json, r'removed')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        attachments: Attachment.listFromJson(json[r'attachments']),
      );
    }
    return null;
  }

  static List<Message> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Message>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Message.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Message> mapFromJson(dynamic json) {
    final map = <String, Message>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Message.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Message-objects as value to a dart map
  static Map<String, List<Message>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Message>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Message.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'conversation_id',
    'kind',
    'body',
    'flags',
    'removed',
    'created_at',
    'attachments',
  };
}


class MessageKindEnum {
  /// Instantiate a new enum with the provided [value].
  const MessageKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const text = MessageKindEnum._(r'text');
  static const prescreen = MessageKindEnum._(r'prescreen');
  static const system = MessageKindEnum._(r'system');

  /// List of all possible values in this [enum][MessageKindEnum].
  static const values = <MessageKindEnum>[
    text,
    prescreen,
    system,
  ];

  static MessageKindEnum? fromJson(dynamic value) => MessageKindEnumTypeTransformer().decode(value);

  static List<MessageKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MessageKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MessageKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MessageKindEnum] to String,
/// and [decode] dynamic data back to [MessageKindEnum].
class MessageKindEnumTypeTransformer {
  factory MessageKindEnumTypeTransformer() => _instance ??= const MessageKindEnumTypeTransformer._();

  const MessageKindEnumTypeTransformer._();

  String encode(MessageKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MessageKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MessageKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'text': return MessageKindEnum.text;
        case r'prescreen': return MessageKindEnum.prescreen;
        case r'system': return MessageKindEnum.system;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MessageKindEnumTypeTransformer] instance.
  static MessageKindEnumTypeTransformer? _instance;
}


