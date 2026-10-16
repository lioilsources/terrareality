//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Member {
  /// Returns a new [Member] instance.
  Member({
    required this.userId,
    this.email,
    required this.displayName,
    required this.role,
    required this.verificationLevel,
    required this.joinedAt,
  });

  String userId;

  /// Omitted for callers with the viewer or investor role (except their own row).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  String displayName;

  Role role;

  VerificationLevel verificationLevel;

  DateTime joinedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Member &&
    other.userId == userId &&
    other.email == email &&
    other.displayName == displayName &&
    other.role == role &&
    other.verificationLevel == verificationLevel &&
    other.joinedAt == joinedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (displayName.hashCode) +
    (role.hashCode) +
    (verificationLevel.hashCode) +
    (joinedAt.hashCode);

  @override
  String toString() => 'Member[userId=$userId, email=$email, displayName=$displayName, role=$role, verificationLevel=$verificationLevel, joinedAt=$joinedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user_id'] = this.userId;
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
      json[r'display_name'] = this.displayName;
      json[r'role'] = this.role;
      json[r'verification_level'] = this.verificationLevel;
      json[r'joined_at'] = this.joinedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Member] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Member? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Member[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Member[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Member(
        userId: mapValueOfType<String>(json, r'user_id')!,
        email: mapValueOfType<String>(json, r'email'),
        displayName: mapValueOfType<String>(json, r'display_name')!,
        role: Role.fromJson(json[r'role'])!,
        verificationLevel: VerificationLevel.fromJson(json[r'verification_level'])!,
        joinedAt: mapDateTime(json, r'joined_at', r'')!,
      );
    }
    return null;
  }

  static List<Member> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Member>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Member.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Member> mapFromJson(dynamic json) {
    final map = <String, Member>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Member.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Member-objects as value to a dart map
  static Map<String, List<Member>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Member>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Member.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user_id',
    'display_name',
    'role',
    'verification_level',
    'joined_at',
  };
}

