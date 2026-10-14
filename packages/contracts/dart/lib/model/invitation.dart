//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Invitation {
  /// Returns a new [Invitation] instance.
  Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.expiresAt,
    required this.createdAt,
  });

  String id;

  String email;

  Role role;

  DateTime expiresAt;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Invitation &&
    other.id == id &&
    other.email == email &&
    other.role == role &&
    other.expiresAt == expiresAt &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (email.hashCode) +
    (role.hashCode) +
    (expiresAt.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'Invitation[id=$id, email=$email, role=$role, expiresAt=$expiresAt, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'email'] = this.email;
      json[r'role'] = this.role;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Invitation] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Invitation? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Invitation[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Invitation[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Invitation(
        id: mapValueOfType<String>(json, r'id')!,
        email: mapValueOfType<String>(json, r'email')!,
        role: Role.fromJson(json[r'role'])!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<Invitation> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Invitation>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Invitation.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Invitation> mapFromJson(dynamic json) {
    final map = <String, Invitation>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Invitation.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Invitation-objects as value to a dart map
  static Map<String, List<Invitation>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Invitation>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Invitation.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'email',
    'role',
    'expires_at',
    'created_at',
  };
}

