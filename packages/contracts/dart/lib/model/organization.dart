//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Organization {
  /// Returns a new [Organization] instance.
  Organization({
    required this.id,
    required this.kind,
    required this.name,
    this.registrationNo,
    this.vatNo,
    required this.jurisdictionCode,
    required this.createdAt,
  });

  String id;

  OrganizationKindEnum kind;

  String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? registrationNo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? vatNo;

  String jurisdictionCode;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Organization &&
    other.id == id &&
    other.kind == kind &&
    other.name == name &&
    other.registrationNo == registrationNo &&
    other.vatNo == vatNo &&
    other.jurisdictionCode == jurisdictionCode &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (kind.hashCode) +
    (name.hashCode) +
    (registrationNo == null ? 0 : registrationNo!.hashCode) +
    (vatNo == null ? 0 : vatNo!.hashCode) +
    (jurisdictionCode.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'Organization[id=$id, kind=$kind, name=$name, registrationNo=$registrationNo, vatNo=$vatNo, jurisdictionCode=$jurisdictionCode, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'kind'] = this.kind;
      json[r'name'] = this.name;
    if (this.registrationNo != null) {
      json[r'registration_no'] = this.registrationNo;
    } else {
      json[r'registration_no'] = null;
    }
    if (this.vatNo != null) {
      json[r'vat_no'] = this.vatNo;
    } else {
      json[r'vat_no'] = null;
    }
      json[r'jurisdiction_code'] = this.jurisdictionCode;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Organization] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Organization? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Organization[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Organization[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Organization(
        id: mapValueOfType<String>(json, r'id')!,
        kind: OrganizationKindEnum.fromJson(json[r'kind'])!,
        name: mapValueOfType<String>(json, r'name')!,
        registrationNo: mapValueOfType<String>(json, r'registration_no'),
        vatNo: mapValueOfType<String>(json, r'vat_no'),
        jurisdictionCode: mapValueOfType<String>(json, r'jurisdiction_code')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<Organization> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Organization>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Organization.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Organization> mapFromJson(dynamic json) {
    final map = <String, Organization>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Organization.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Organization-objects as value to a dart map
  static Map<String, List<Organization>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Organization>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Organization.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'kind',
    'name',
    'jurisdiction_code',
    'created_at',
  };
}


class OrganizationKindEnum {
  /// Instantiate a new enum with the provided [value].
  const OrganizationKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const personal = OrganizationKindEnum._(r'personal');
  static const company = OrganizationKindEnum._(r'company');

  /// List of all possible values in this [enum][OrganizationKindEnum].
  static const values = <OrganizationKindEnum>[
    personal,
    company,
  ];

  static OrganizationKindEnum? fromJson(dynamic value) => OrganizationKindEnumTypeTransformer().decode(value);

  static List<OrganizationKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrganizationKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrganizationKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [OrganizationKindEnum] to String,
/// and [decode] dynamic data back to [OrganizationKindEnum].
class OrganizationKindEnumTypeTransformer {
  factory OrganizationKindEnumTypeTransformer() => _instance ??= const OrganizationKindEnumTypeTransformer._();

  const OrganizationKindEnumTypeTransformer._();

  String encode(OrganizationKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a OrganizationKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  OrganizationKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'personal': return OrganizationKindEnum.personal;
        case r'company': return OrganizationKindEnum.company;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [OrganizationKindEnumTypeTransformer] instance.
  static OrganizationKindEnumTypeTransformer? _instance;
}


