//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InvitationInput {
  /// Returns a new [InvitationInput] instance.
  InvitationInput({
    required this.email,
    required this.role,
    this.locale,
  });

  String email;

  InvitationInputRoleEnum role;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UserLocale? locale;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InvitationInput &&
    other.email == email &&
    other.role == role &&
    other.locale == locale;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (role.hashCode) +
    (locale == null ? 0 : locale!.hashCode);

  @override
  String toString() => 'InvitationInput[email=$email, role=$role, locale=$locale]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'role'] = this.role;
    if (this.locale != null) {
      json[r'locale'] = this.locale;
    } else {
      json[r'locale'] = null;
    }
    return json;
  }

  /// Returns a new [InvitationInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InvitationInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "InvitationInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "InvitationInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InvitationInput(
        email: mapValueOfType<String>(json, r'email')!,
        role: InvitationInputRoleEnum.fromJson(json[r'role'])!,
        locale: UserLocale.fromJson(json[r'locale']),
      );
    }
    return null;
  }

  static List<InvitationInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InvitationInput> mapFromJson(dynamic json) {
    final map = <String, InvitationInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InvitationInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InvitationInput-objects as value to a dart map
  static Map<String, List<InvitationInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InvitationInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InvitationInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'role',
  };
}


class InvitationInputRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const InvitationInputRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const admin = InvitationInputRoleEnum._(r'admin');
  static const agent = InvitationInputRoleEnum._(r'agent');
  static const accountant = InvitationInputRoleEnum._(r'accountant');
  static const maintenance = InvitationInputRoleEnum._(r'maintenance');
  static const viewer = InvitationInputRoleEnum._(r'viewer');

  /// List of all possible values in this [enum][InvitationInputRoleEnum].
  static const values = <InvitationInputRoleEnum>[
    admin,
    agent,
    accountant,
    maintenance,
    viewer,
  ];

  static InvitationInputRoleEnum? fromJson(dynamic value) => InvitationInputRoleEnumTypeTransformer().decode(value);

  static List<InvitationInputRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationInputRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationInputRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [InvitationInputRoleEnum] to String,
/// and [decode] dynamic data back to [InvitationInputRoleEnum].
class InvitationInputRoleEnumTypeTransformer {
  factory InvitationInputRoleEnumTypeTransformer() => _instance ??= const InvitationInputRoleEnumTypeTransformer._();

  const InvitationInputRoleEnumTypeTransformer._();

  String encode(InvitationInputRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a InvitationInputRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  InvitationInputRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'admin': return InvitationInputRoleEnum.admin;
        case r'agent': return InvitationInputRoleEnum.agent;
        case r'accountant': return InvitationInputRoleEnum.accountant;
        case r'maintenance': return InvitationInputRoleEnum.maintenance;
        case r'viewer': return InvitationInputRoleEnum.viewer;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [InvitationInputRoleEnumTypeTransformer] instance.
  static InvitationInputRoleEnumTypeTransformer? _instance;
}


