//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseImportPartyInput {
  /// Returns a new [LeaseImportPartyInput] instance.
  LeaseImportPartyInput({
    required this.name,
    this.email,
    required this.role,
    this.shareBps,
    this.openingBalance,
  });

  String name;

  /// Optional; nobody is contacted at import.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  LeaseImportPartyInputRoleEnum role;

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

  /// Owed at the cutover (minor units); 0 = nothing.
  ///
  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? openingBalance;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseImportPartyInput &&
    other.name == name &&
    other.email == email &&
    other.role == role &&
    other.shareBps == shareBps &&
    other.openingBalance == openingBalance;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (role.hashCode) +
    (shareBps == null ? 0 : shareBps!.hashCode) +
    (openingBalance == null ? 0 : openingBalance!.hashCode);

  @override
  String toString() => 'LeaseImportPartyInput[name=$name, email=$email, role=$role, shareBps=$shareBps, openingBalance=$openingBalance]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
      json[r'role'] = this.role;
    if (this.shareBps != null) {
      json[r'share_bps'] = this.shareBps;
    } else {
      json[r'share_bps'] = null;
    }
    if (this.openingBalance != null) {
      json[r'opening_balance'] = this.openingBalance;
    } else {
      json[r'opening_balance'] = null;
    }
    return json;
  }

  /// Returns a new [LeaseImportPartyInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseImportPartyInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseImportPartyInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseImportPartyInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseImportPartyInput(
        name: mapValueOfType<String>(json, r'name')!,
        email: mapValueOfType<String>(json, r'email'),
        role: LeaseImportPartyInputRoleEnum.fromJson(json[r'role'])!,
        shareBps: mapValueOfType<int>(json, r'share_bps'),
        openingBalance: mapValueOfType<int>(json, r'opening_balance'),
      );
    }
    return null;
  }

  static List<LeaseImportPartyInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseImportPartyInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseImportPartyInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseImportPartyInput> mapFromJson(dynamic json) {
    final map = <String, LeaseImportPartyInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseImportPartyInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseImportPartyInput-objects as value to a dart map
  static Map<String, List<LeaseImportPartyInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseImportPartyInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseImportPartyInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'role',
  };
}


class LeaseImportPartyInputRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const LeaseImportPartyInputRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const tenant = LeaseImportPartyInputRoleEnum._(r'tenant');
  static const coTenant = LeaseImportPartyInputRoleEnum._(r'co_tenant');
  static const subtenant = LeaseImportPartyInputRoleEnum._(r'subtenant');
  static const guarantor = LeaseImportPartyInputRoleEnum._(r'guarantor');

  /// List of all possible values in this [enum][LeaseImportPartyInputRoleEnum].
  static const values = <LeaseImportPartyInputRoleEnum>[
    tenant,
    coTenant,
    subtenant,
    guarantor,
  ];

  static LeaseImportPartyInputRoleEnum? fromJson(dynamic value) => LeaseImportPartyInputRoleEnumTypeTransformer().decode(value);

  static List<LeaseImportPartyInputRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseImportPartyInputRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseImportPartyInputRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeaseImportPartyInputRoleEnum] to String,
/// and [decode] dynamic data back to [LeaseImportPartyInputRoleEnum].
class LeaseImportPartyInputRoleEnumTypeTransformer {
  factory LeaseImportPartyInputRoleEnumTypeTransformer() => _instance ??= const LeaseImportPartyInputRoleEnumTypeTransformer._();

  const LeaseImportPartyInputRoleEnumTypeTransformer._();

  String encode(LeaseImportPartyInputRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a LeaseImportPartyInputRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeaseImportPartyInputRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'tenant': return LeaseImportPartyInputRoleEnum.tenant;
        case r'co_tenant': return LeaseImportPartyInputRoleEnum.coTenant;
        case r'subtenant': return LeaseImportPartyInputRoleEnum.subtenant;
        case r'guarantor': return LeaseImportPartyInputRoleEnum.guarantor;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LeaseImportPartyInputRoleEnumTypeTransformer] instance.
  static LeaseImportPartyInputRoleEnumTypeTransformer? _instance;
}


