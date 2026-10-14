//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Passport {
  /// Returns a new [Passport] instance.
  Passport({
    required this.verificationLevel,
    this.incomeProofName,
    this.incomeUploadedAt,
    required this.insolvency,
    this.insolvencyCheckedAt,
  });

  VerificationLevel verificationLevel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? incomeProofName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? incomeUploadedAt;

  PassportInsolvencyEnum insolvency;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? insolvencyCheckedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Passport &&
    other.verificationLevel == verificationLevel &&
    other.incomeProofName == incomeProofName &&
    other.incomeUploadedAt == incomeUploadedAt &&
    other.insolvency == insolvency &&
    other.insolvencyCheckedAt == insolvencyCheckedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (verificationLevel.hashCode) +
    (incomeProofName == null ? 0 : incomeProofName!.hashCode) +
    (incomeUploadedAt == null ? 0 : incomeUploadedAt!.hashCode) +
    (insolvency.hashCode) +
    (insolvencyCheckedAt == null ? 0 : insolvencyCheckedAt!.hashCode);

  @override
  String toString() => 'Passport[verificationLevel=$verificationLevel, incomeProofName=$incomeProofName, incomeUploadedAt=$incomeUploadedAt, insolvency=$insolvency, insolvencyCheckedAt=$insolvencyCheckedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'verification_level'] = this.verificationLevel;
    if (this.incomeProofName != null) {
      json[r'income_proof_name'] = this.incomeProofName;
    } else {
      json[r'income_proof_name'] = null;
    }
    if (this.incomeUploadedAt != null) {
      json[r'income_uploaded_at'] = this.incomeUploadedAt!.toUtc().toIso8601String();
    } else {
      json[r'income_uploaded_at'] = null;
    }
      json[r'insolvency'] = this.insolvency;
    if (this.insolvencyCheckedAt != null) {
      json[r'insolvency_checked_at'] = this.insolvencyCheckedAt!.toUtc().toIso8601String();
    } else {
      json[r'insolvency_checked_at'] = null;
    }
    return json;
  }

  /// Returns a new [Passport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Passport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Passport[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Passport[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Passport(
        verificationLevel: VerificationLevel.fromJson(json[r'verification_level'])!,
        incomeProofName: mapValueOfType<String>(json, r'income_proof_name'),
        incomeUploadedAt: mapDateTime(json, r'income_uploaded_at', r''),
        insolvency: PassportInsolvencyEnum.fromJson(json[r'insolvency'])!,
        insolvencyCheckedAt: mapDateTime(json, r'insolvency_checked_at', r''),
      );
    }
    return null;
  }

  static List<Passport> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Passport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Passport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Passport> mapFromJson(dynamic json) {
    final map = <String, Passport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Passport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Passport-objects as value to a dart map
  static Map<String, List<Passport>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Passport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Passport.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'verification_level',
    'insolvency',
  };
}


class PassportInsolvencyEnum {
  /// Instantiate a new enum with the provided [value].
  const PassportInsolvencyEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const unchecked = PassportInsolvencyEnum._(r'unchecked');
  static const clear = PassportInsolvencyEnum._(r'clear');
  static const record = PassportInsolvencyEnum._(r'record');
  static const error = PassportInsolvencyEnum._(r'error');

  /// List of all possible values in this [enum][PassportInsolvencyEnum].
  static const values = <PassportInsolvencyEnum>[
    unchecked,
    clear,
    record,
    error,
  ];

  static PassportInsolvencyEnum? fromJson(dynamic value) => PassportInsolvencyEnumTypeTransformer().decode(value);

  static List<PassportInsolvencyEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PassportInsolvencyEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PassportInsolvencyEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PassportInsolvencyEnum] to String,
/// and [decode] dynamic data back to [PassportInsolvencyEnum].
class PassportInsolvencyEnumTypeTransformer {
  factory PassportInsolvencyEnumTypeTransformer() => _instance ??= const PassportInsolvencyEnumTypeTransformer._();

  const PassportInsolvencyEnumTypeTransformer._();

  String encode(PassportInsolvencyEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PassportInsolvencyEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PassportInsolvencyEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'unchecked': return PassportInsolvencyEnum.unchecked;
        case r'clear': return PassportInsolvencyEnum.clear;
        case r'record': return PassportInsolvencyEnum.record;
        case r'error': return PassportInsolvencyEnum.error;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PassportInsolvencyEnumTypeTransformer] instance.
  static PassportInsolvencyEnumTypeTransformer? _instance;
}


