//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GroupSummary {
  /// Returns a new [GroupSummary] instance.
  GroupSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.joined,
    required this.members,
    required this.createdAt,
  });

  String id;

  String name;

  GroupSummaryRoleEnum role;

  /// False while the invitation is pending.
  bool joined;

  int members;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GroupSummary &&
    other.id == id &&
    other.name == name &&
    other.role == role &&
    other.joined == joined &&
    other.members == members &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (role.hashCode) +
    (joined.hashCode) +
    (members.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'GroupSummary[id=$id, name=$name, role=$role, joined=$joined, members=$members, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'role'] = this.role;
      json[r'joined'] = this.joined;
      json[r'members'] = this.members;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [GroupSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GroupSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GroupSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GroupSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GroupSummary(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        role: GroupSummaryRoleEnum.fromJson(json[r'role'])!,
        joined: mapValueOfType<bool>(json, r'joined')!,
        members: mapValueOfType<int>(json, r'members')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<GroupSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GroupSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GroupSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GroupSummary> mapFromJson(dynamic json) {
    final map = <String, GroupSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GroupSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GroupSummary-objects as value to a dart map
  static Map<String, List<GroupSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GroupSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GroupSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'role',
    'joined',
    'members',
    'created_at',
  };
}


class GroupSummaryRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const GroupSummaryRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const admin = GroupSummaryRoleEnum._(r'admin');
  static const member = GroupSummaryRoleEnum._(r'member');

  /// List of all possible values in this [enum][GroupSummaryRoleEnum].
  static const values = <GroupSummaryRoleEnum>[
    admin,
    member,
  ];

  static GroupSummaryRoleEnum? fromJson(dynamic value) => GroupSummaryRoleEnumTypeTransformer().decode(value);

  static List<GroupSummaryRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GroupSummaryRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GroupSummaryRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [GroupSummaryRoleEnum] to String,
/// and [decode] dynamic data back to [GroupSummaryRoleEnum].
class GroupSummaryRoleEnumTypeTransformer {
  factory GroupSummaryRoleEnumTypeTransformer() => _instance ??= const GroupSummaryRoleEnumTypeTransformer._();

  const GroupSummaryRoleEnumTypeTransformer._();

  String encode(GroupSummaryRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a GroupSummaryRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  GroupSummaryRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'admin': return GroupSummaryRoleEnum.admin;
        case r'member': return GroupSummaryRoleEnum.member;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [GroupSummaryRoleEnumTypeTransformer] instance.
  static GroupSummaryRoleEnumTypeTransformer? _instance;
}


