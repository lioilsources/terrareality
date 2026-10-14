//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Conversation {
  /// Returns a new [Conversation] instance.
  Conversation({
    required this.id,
    required this.listingId,
    required this.orgId,
    required this.orgName,
    required this.seekerId,
    required this.seekerName,
    required this.listingTitle,
    this.coverUrl,
    required this.role,
    required this.lastMessageAt,
    required this.lastMessage,
    this.lastSenderId,
    required this.unread,
    required this.blocked,
    required this.blockedByMe,
    required this.createdAt,
  });

  String id;

  String listingId;

  String orgId;

  String orgName;

  String seekerId;

  String seekerName;

  I18nText listingTitle;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? coverUrl;

  ConversationRole role;

  DateTime lastMessageAt;

  /// Preview of the latest message.
  String lastMessage;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? lastSenderId;

  int unread;

  bool blocked;

  bool blockedByMe;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Conversation &&
    other.id == id &&
    other.listingId == listingId &&
    other.orgId == orgId &&
    other.orgName == orgName &&
    other.seekerId == seekerId &&
    other.seekerName == seekerName &&
    other.listingTitle == listingTitle &&
    other.coverUrl == coverUrl &&
    other.role == role &&
    other.lastMessageAt == lastMessageAt &&
    other.lastMessage == lastMessage &&
    other.lastSenderId == lastSenderId &&
    other.unread == unread &&
    other.blocked == blocked &&
    other.blockedByMe == blockedByMe &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (listingId.hashCode) +
    (orgId.hashCode) +
    (orgName.hashCode) +
    (seekerId.hashCode) +
    (seekerName.hashCode) +
    (listingTitle.hashCode) +
    (coverUrl == null ? 0 : coverUrl!.hashCode) +
    (role.hashCode) +
    (lastMessageAt.hashCode) +
    (lastMessage.hashCode) +
    (lastSenderId == null ? 0 : lastSenderId!.hashCode) +
    (unread.hashCode) +
    (blocked.hashCode) +
    (blockedByMe.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'Conversation[id=$id, listingId=$listingId, orgId=$orgId, orgName=$orgName, seekerId=$seekerId, seekerName=$seekerName, listingTitle=$listingTitle, coverUrl=$coverUrl, role=$role, lastMessageAt=$lastMessageAt, lastMessage=$lastMessage, lastSenderId=$lastSenderId, unread=$unread, blocked=$blocked, blockedByMe=$blockedByMe, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'listing_id'] = this.listingId;
      json[r'org_id'] = this.orgId;
      json[r'org_name'] = this.orgName;
      json[r'seeker_id'] = this.seekerId;
      json[r'seeker_name'] = this.seekerName;
      json[r'listing_title'] = this.listingTitle;
    if (this.coverUrl != null) {
      json[r'cover_url'] = this.coverUrl;
    } else {
      json[r'cover_url'] = null;
    }
      json[r'role'] = this.role;
      json[r'last_message_at'] = this.lastMessageAt.toUtc().toIso8601String();
      json[r'last_message'] = this.lastMessage;
    if (this.lastSenderId != null) {
      json[r'last_sender_id'] = this.lastSenderId;
    } else {
      json[r'last_sender_id'] = null;
    }
      json[r'unread'] = this.unread;
      json[r'blocked'] = this.blocked;
      json[r'blocked_by_me'] = this.blockedByMe;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Conversation] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Conversation? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Conversation[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Conversation[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Conversation(
        id: mapValueOfType<String>(json, r'id')!,
        listingId: mapValueOfType<String>(json, r'listing_id')!,
        orgId: mapValueOfType<String>(json, r'org_id')!,
        orgName: mapValueOfType<String>(json, r'org_name')!,
        seekerId: mapValueOfType<String>(json, r'seeker_id')!,
        seekerName: mapValueOfType<String>(json, r'seeker_name')!,
        listingTitle: I18nText.fromJson(json[r'listing_title'])!,
        coverUrl: mapValueOfType<String>(json, r'cover_url'),
        role: ConversationRole.fromJson(json[r'role'])!,
        lastMessageAt: mapDateTime(json, r'last_message_at', r'')!,
        lastMessage: mapValueOfType<String>(json, r'last_message')!,
        lastSenderId: mapValueOfType<String>(json, r'last_sender_id'),
        unread: mapValueOfType<int>(json, r'unread')!,
        blocked: mapValueOfType<bool>(json, r'blocked')!,
        blockedByMe: mapValueOfType<bool>(json, r'blocked_by_me')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<Conversation> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Conversation>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Conversation.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Conversation> mapFromJson(dynamic json) {
    final map = <String, Conversation>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Conversation.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Conversation-objects as value to a dart map
  static Map<String, List<Conversation>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Conversation>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Conversation.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'listing_id',
    'org_id',
    'org_name',
    'seeker_id',
    'seeker_name',
    'listing_title',
    'role',
    'last_message_at',
    'last_message',
    'unread',
    'blocked',
    'blocked_by_me',
    'created_at',
  };
}

