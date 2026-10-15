//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeasePartyInput {
  /// Returns a new [LeasePartyInput] instance.
  LeasePartyInput({
    required this.name,
    required this.email,
    required this.role,
    this.shareBps,
  });

  String name;

  String email;

  LeasePartyInputRoleEnum role;

  /// Payment share in basis points; all zero = equal shares.
  ///
  /// Minimum value: 0
  /// Maximum value: 10000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? shareBps;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeasePartyInput &&
    other.name == name &&
    other.email == email &&
    other.role == role &&
    other.shareBps == shareBps;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (email.hashCode) +
    (role.hashCode) +
    (shareBps == null ? 0 : shareBps!.hashCode);

  @override
  String toString() => 'LeasePartyInput[name=$name, email=$email, role=$role, shareBps=$shareBps]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'email'] = this.email;
      json[r'role'] = this.role;
    if (this.shareBps != null) {
      json[r'share_bps'] = this.shareBps;
    } else {
      json[r'share_bps'] = null;
    }
    return json;
  }

  /// Returns a new [LeasePartyInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeasePartyInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeasePartyInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeasePartyInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeasePartyInput(
        name: mapValueOfType<String>(json, r'name')!,
        email: mapValueOfType<String>(json, r'email')!,
        role: LeasePartyInputRoleEnum.fromJson(json[r'role'])!,
        shareBps: mapValueOfType<int>(json, r'share_bps'),
      );
    }
    return null;
  }

  static List<LeasePartyInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeasePartyInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeasePartyInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeasePartyInput> mapFromJson(dynamic json) {
    final map = <String, LeasePartyInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeasePartyInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeasePartyInput-objects as value to a dart map
  static Map<String, List<LeasePartyInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeasePartyInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeasePartyInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'email',
    'role',
  };
}


class LeasePartyInputRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const LeasePartyInputRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const tenant = LeasePartyInputRoleEnum._(r'tenant');
  static const coTenant = LeasePartyInputRoleEnum._(r'co_tenant');
  static const subtenant = LeasePartyInputRoleEnum._(r'subtenant');
  static const guarantor = LeasePartyInputRoleEnum._(r'guarantor');

  /// List of all possible values in this [enum][LeasePartyInputRoleEnum].
  static const values = <LeasePartyInputRoleEnum>[
    tenant,
    coTenant,
    subtenant,
    guarantor,
  ];

  static LeasePartyInputRoleEnum? fromJson(dynamic value) => LeasePartyInputRoleEnumTypeTransformer().decode(value);

  static List<LeasePartyInputRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeasePartyInputRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeasePartyInputRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeasePartyInputRoleEnum] to String,
/// and [decode] dynamic data back to [LeasePartyInputRoleEnum].
class LeasePartyInputRoleEnumTypeTransformer {
  factory LeasePartyInputRoleEnumTypeTransformer() => _instance ??= const LeasePartyInputRoleEnumTypeTransformer._();

  const LeasePartyInputRoleEnumTypeTransformer._();

  String encode(LeasePartyInputRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a LeasePartyInputRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeasePartyInputRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'tenant': return LeasePartyInputRoleEnum.tenant;
        case r'co_tenant': return LeasePartyInputRoleEnum.coTenant;
        case r'subtenant': return LeasePartyInputRoleEnum.subtenant;
        case r'guarantor': return LeasePartyInputRoleEnum.guarantor;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LeasePartyInputRoleEnumTypeTransformer] instance.
  static LeasePartyInputRoleEnumTypeTransformer? _instance;
}


