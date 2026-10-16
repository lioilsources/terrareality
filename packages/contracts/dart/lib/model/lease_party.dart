//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseParty {
  /// Returns a new [LeaseParty] instance.
  LeaseParty({
    required this.id,
    required this.role,
    required this.name,
    this.email,
    required this.shareBps,
    required this.position,
    required this.me,
    this.signedAt,
    this.debt,
  });

  String id;

  LeasePartyRoleEnum role;

  String name;

  /// Shown to the landlord side for every party; a tenant-side caller sees only their own and the landlord's.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  int shareBps;

  /// Specific symbol of this party's payments.
  int position;

  bool me;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? signedAt;

  /// Due and unpaid amount today.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? debt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseParty &&
    other.id == id &&
    other.role == role &&
    other.name == name &&
    other.email == email &&
    other.shareBps == shareBps &&
    other.position == position &&
    other.me == me &&
    other.signedAt == signedAt &&
    other.debt == debt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (role.hashCode) +
    (name.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (shareBps.hashCode) +
    (position.hashCode) +
    (me.hashCode) +
    (signedAt == null ? 0 : signedAt!.hashCode) +
    (debt == null ? 0 : debt!.hashCode);

  @override
  String toString() => 'LeaseParty[id=$id, role=$role, name=$name, email=$email, shareBps=$shareBps, position=$position, me=$me, signedAt=$signedAt, debt=$debt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'role'] = this.role;
      json[r'name'] = this.name;
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
      json[r'share_bps'] = this.shareBps;
      json[r'position'] = this.position;
      json[r'me'] = this.me;
    if (this.signedAt != null) {
      json[r'signed_at'] = this.signedAt!.toUtc().toIso8601String();
    } else {
      json[r'signed_at'] = null;
    }
    if (this.debt != null) {
      json[r'debt'] = this.debt;
    } else {
      json[r'debt'] = null;
    }
    return json;
  }

  /// Returns a new [LeaseParty] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseParty? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseParty[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseParty[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseParty(
        id: mapValueOfType<String>(json, r'id')!,
        role: LeasePartyRoleEnum.fromJson(json[r'role'])!,
        name: mapValueOfType<String>(json, r'name')!,
        email: mapValueOfType<String>(json, r'email'),
        shareBps: mapValueOfType<int>(json, r'share_bps')!,
        position: mapValueOfType<int>(json, r'position')!,
        me: mapValueOfType<bool>(json, r'me')!,
        signedAt: mapDateTime(json, r'signed_at', r''),
        debt: mapValueOfType<int>(json, r'debt'),
      );
    }
    return null;
  }

  static List<LeaseParty> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseParty>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseParty.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseParty> mapFromJson(dynamic json) {
    final map = <String, LeaseParty>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseParty.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseParty-objects as value to a dart map
  static Map<String, List<LeaseParty>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseParty>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseParty.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'role',
    'name',
    'share_bps',
    'position',
    'me',
  };
}


class LeasePartyRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const LeasePartyRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const landlord = LeasePartyRoleEnum._(r'landlord');
  static const tenant = LeasePartyRoleEnum._(r'tenant');
  static const coTenant = LeasePartyRoleEnum._(r'co_tenant');
  static const subtenant = LeasePartyRoleEnum._(r'subtenant');
  static const guarantor = LeasePartyRoleEnum._(r'guarantor');

  /// List of all possible values in this [enum][LeasePartyRoleEnum].
  static const values = <LeasePartyRoleEnum>[
    landlord,
    tenant,
    coTenant,
    subtenant,
    guarantor,
  ];

  static LeasePartyRoleEnum? fromJson(dynamic value) => LeasePartyRoleEnumTypeTransformer().decode(value);

  static List<LeasePartyRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeasePartyRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeasePartyRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeasePartyRoleEnum] to String,
/// and [decode] dynamic data back to [LeasePartyRoleEnum].
class LeasePartyRoleEnumTypeTransformer {
  factory LeasePartyRoleEnumTypeTransformer() => _instance ??= const LeasePartyRoleEnumTypeTransformer._();

  const LeasePartyRoleEnumTypeTransformer._();

  String encode(LeasePartyRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a LeasePartyRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeasePartyRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'landlord': return LeasePartyRoleEnum.landlord;
        case r'tenant': return LeasePartyRoleEnum.tenant;
        case r'co_tenant': return LeasePartyRoleEnum.coTenant;
        case r'subtenant': return LeasePartyRoleEnum.subtenant;
        case r'guarantor': return LeasePartyRoleEnum.guarantor;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LeasePartyRoleEnumTypeTransformer] instance.
  static LeasePartyRoleEnumTypeTransformer? _instance;
}


