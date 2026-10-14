//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Group {
  /// Returns a new [Group] instance.
  Group({
    required this.id,
    required this.name,
    required this.joined,
    this.members = const [],
    this.messages = const [],
    required this.createdAt,
  });

  String id;

  String name;

  bool joined;

  List<GroupMember> members;

  List<GroupMessage> messages;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Group &&
    other.id == id &&
    other.name == name &&
    other.joined == joined &&
    _deepEquality.equals(other.members, members) &&
    _deepEquality.equals(other.messages, messages) &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (joined.hashCode) +
    (members.hashCode) +
    (messages.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'Group[id=$id, name=$name, joined=$joined, members=$members, messages=$messages, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'joined'] = this.joined;
      json[r'members'] = this.members;
      json[r'messages'] = this.messages;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Group] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Group? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Group[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Group[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Group(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        joined: mapValueOfType<bool>(json, r'joined')!,
        members: GroupMember.listFromJson(json[r'members']),
        messages: GroupMessage.listFromJson(json[r'messages']),
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<Group> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Group>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Group.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Group> mapFromJson(dynamic json) {
    final map = <String, Group>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Group.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Group-objects as value to a dart map
  static Map<String, List<Group>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Group>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Group.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'joined',
    'members',
    'messages',
    'created_at',
  };
}

