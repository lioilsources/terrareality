//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GroupMember {
  /// Returns a new [GroupMember] instance.
  GroupMember({
    required this.id,
    this.userId,
    required this.invitedEmail,
    required this.role,
    required this.joined,
    required this.displayName,
    required this.verificationLevel,
  });

  String id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? userId;

  String invitedEmail;

  GroupMemberRoleEnum role;

  bool joined;

  String displayName;

  VerificationLevel verificationLevel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GroupMember &&
    other.id == id &&
    other.userId == userId &&
    other.invitedEmail == invitedEmail &&
    other.role == role &&
    other.joined == joined &&
    other.displayName == displayName &&
    other.verificationLevel == verificationLevel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (userId == null ? 0 : userId!.hashCode) +
    (invitedEmail.hashCode) +
    (role.hashCode) +
    (joined.hashCode) +
    (displayName.hashCode) +
    (verificationLevel.hashCode);

  @override
  String toString() => 'GroupMember[id=$id, userId=$userId, invitedEmail=$invitedEmail, role=$role, joined=$joined, displayName=$displayName, verificationLevel=$verificationLevel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.userId != null) {
      json[r'user_id'] = this.userId;
    } else {
      json[r'user_id'] = null;
    }
      json[r'invited_email'] = this.invitedEmail;
      json[r'role'] = this.role;
      json[r'joined'] = this.joined;
      json[r'display_name'] = this.displayName;
      json[r'verification_level'] = this.verificationLevel;
    return json;
  }

  /// Returns a new [GroupMember] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GroupMember? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GroupMember[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GroupMember[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GroupMember(
        id: mapValueOfType<String>(json, r'id')!,
        userId: mapValueOfType<String>(json, r'user_id'),
        invitedEmail: mapValueOfType<String>(json, r'invited_email')!,
        role: GroupMemberRoleEnum.fromJson(json[r'role'])!,
        joined: mapValueOfType<bool>(json, r'joined')!,
        displayName: mapValueOfType<String>(json, r'display_name')!,
        verificationLevel: VerificationLevel.fromJson(json[r'verification_level'])!,
      );
    }
    return null;
  }

  static List<GroupMember> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GroupMember>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GroupMember.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GroupMember> mapFromJson(dynamic json) {
    final map = <String, GroupMember>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GroupMember.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GroupMember-objects as value to a dart map
  static Map<String, List<GroupMember>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GroupMember>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GroupMember.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'invited_email',
    'role',
    'joined',
    'display_name',
    'verification_level',
  };
}


class GroupMemberRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const GroupMemberRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const admin = GroupMemberRoleEnum._(r'admin');
  static const member = GroupMemberRoleEnum._(r'member');

  /// List of all possible values in this [enum][GroupMemberRoleEnum].
  static const values = <GroupMemberRoleEnum>[
    admin,
    member,
  ];

  static GroupMemberRoleEnum? fromJson(dynamic value) => GroupMemberRoleEnumTypeTransformer().decode(value);

  static List<GroupMemberRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GroupMemberRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GroupMemberRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [GroupMemberRoleEnum] to String,
/// and [decode] dynamic data back to [GroupMemberRoleEnum].
class GroupMemberRoleEnumTypeTransformer {
  factory GroupMemberRoleEnumTypeTransformer() => _instance ??= const GroupMemberRoleEnumTypeTransformer._();

  const GroupMemberRoleEnumTypeTransformer._();

  String encode(GroupMemberRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a GroupMemberRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  GroupMemberRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'admin': return GroupMemberRoleEnum.admin;
        case r'member': return GroupMemberRoleEnum.member;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [GroupMemberRoleEnumTypeTransformer] instance.
  static GroupMemberRoleEnumTypeTransformer? _instance;
}


