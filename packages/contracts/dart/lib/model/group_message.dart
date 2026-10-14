//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GroupMessage {
  /// Returns a new [GroupMessage] instance.
  GroupMessage({
    required this.id,
    this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  String id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? senderId;

  String senderName;

  String body;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GroupMessage &&
    other.id == id &&
    other.senderId == senderId &&
    other.senderName == senderName &&
    other.body == body &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (senderId == null ? 0 : senderId!.hashCode) +
    (senderName.hashCode) +
    (body.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'GroupMessage[id=$id, senderId=$senderId, senderName=$senderName, body=$body, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.senderId != null) {
      json[r'sender_id'] = this.senderId;
    } else {
      json[r'sender_id'] = null;
    }
      json[r'sender_name'] = this.senderName;
      json[r'body'] = this.body;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [GroupMessage] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GroupMessage? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GroupMessage[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GroupMessage[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GroupMessage(
        id: mapValueOfType<String>(json, r'id')!,
        senderId: mapValueOfType<String>(json, r'sender_id'),
        senderName: mapValueOfType<String>(json, r'sender_name')!,
        body: mapValueOfType<String>(json, r'body')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<GroupMessage> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GroupMessage>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GroupMessage.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GroupMessage> mapFromJson(dynamic json) {
    final map = <String, GroupMessage>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GroupMessage.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GroupMessage-objects as value to a dart map
  static Map<String, List<GroupMessage>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GroupMessage>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GroupMessage.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'sender_name',
    'body',
    'created_at',
  };
}

