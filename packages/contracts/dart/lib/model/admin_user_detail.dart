//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminUserDetail {
  /// Returns a new [AdminUserDetail] instance.
  AdminUserDetail({
    required this.user,
    this.organizations = const [],
  });

  AdminUser user;

  List<OrgMembership> organizations;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminUserDetail &&
    other.user == user &&
    _deepEquality.equals(other.organizations, organizations);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (user.hashCode) +
    (organizations.hashCode);

  @override
  String toString() => 'AdminUserDetail[user=$user, organizations=$organizations]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user'] = this.user;
      json[r'organizations'] = this.organizations;
    return json;
  }

  /// Returns a new [AdminUserDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminUserDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AdminUserDetail[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AdminUserDetail[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AdminUserDetail(
        user: AdminUser.fromJson(json[r'user'])!,
        organizations: OrgMembership.listFromJson(json[r'organizations']),
      );
    }
    return null;
  }

  static List<AdminUserDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminUserDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminUserDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminUserDetail> mapFromJson(dynamic json) {
    final map = <String, AdminUserDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminUserDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminUserDetail-objects as value to a dart map
  static Map<String, List<AdminUserDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminUserDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminUserDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user',
    'organizations',
  };
}

