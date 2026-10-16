//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApplicantPerson {
  /// Returns a new [ApplicantPerson] instance.
  ApplicantPerson({
    required this.userId,
    required this.displayName,
    required this.verificationLevel,
    required this.hasIncomeProof,
    this.incomeProofName,
    required this.insolvency,
  });

  String userId;

  String displayName;

  VerificationLevel verificationLevel;

  /// An income proof can be downloaded now (getApplicantIncomeProof); false once the application is closed.
  bool hasIncomeProof;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? incomeProofName;

  ApplicantPersonInsolvencyEnum insolvency;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ApplicantPerson &&
    other.userId == userId &&
    other.displayName == displayName &&
    other.verificationLevel == verificationLevel &&
    other.hasIncomeProof == hasIncomeProof &&
    other.incomeProofName == incomeProofName &&
    other.insolvency == insolvency;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (displayName.hashCode) +
    (verificationLevel.hashCode) +
    (hasIncomeProof.hashCode) +
    (incomeProofName == null ? 0 : incomeProofName!.hashCode) +
    (insolvency.hashCode);

  @override
  String toString() => 'ApplicantPerson[userId=$userId, displayName=$displayName, verificationLevel=$verificationLevel, hasIncomeProof=$hasIncomeProof, incomeProofName=$incomeProofName, insolvency=$insolvency]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user_id'] = this.userId;
      json[r'display_name'] = this.displayName;
      json[r'verification_level'] = this.verificationLevel;
      json[r'has_income_proof'] = this.hasIncomeProof;
    if (this.incomeProofName != null) {
      json[r'income_proof_name'] = this.incomeProofName;
    } else {
      json[r'income_proof_name'] = null;
    }
      json[r'insolvency'] = this.insolvency;
    return json;
  }

  /// Returns a new [ApplicantPerson] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApplicantPerson? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ApplicantPerson[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ApplicantPerson[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ApplicantPerson(
        userId: mapValueOfType<String>(json, r'user_id')!,
        displayName: mapValueOfType<String>(json, r'display_name')!,
        verificationLevel: VerificationLevel.fromJson(json[r'verification_level'])!,
        hasIncomeProof: mapValueOfType<bool>(json, r'has_income_proof')!,
        incomeProofName: mapValueOfType<String>(json, r'income_proof_name'),
        insolvency: ApplicantPersonInsolvencyEnum.fromJson(json[r'insolvency'])!,
      );
    }
    return null;
  }

  static List<ApplicantPerson> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplicantPerson>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicantPerson.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApplicantPerson> mapFromJson(dynamic json) {
    final map = <String, ApplicantPerson>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApplicantPerson.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApplicantPerson-objects as value to a dart map
  static Map<String, List<ApplicantPerson>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ApplicantPerson>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApplicantPerson.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user_id',
    'display_name',
    'verification_level',
    'has_income_proof',
    'insolvency',
  };
}


class ApplicantPersonInsolvencyEnum {
  /// Instantiate a new enum with the provided [value].
  const ApplicantPersonInsolvencyEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const unchecked = ApplicantPersonInsolvencyEnum._(r'unchecked');
  static const clear = ApplicantPersonInsolvencyEnum._(r'clear');
  static const record = ApplicantPersonInsolvencyEnum._(r'record');
  static const error = ApplicantPersonInsolvencyEnum._(r'error');

  /// List of all possible values in this [enum][ApplicantPersonInsolvencyEnum].
  static const values = <ApplicantPersonInsolvencyEnum>[
    unchecked,
    clear,
    record,
    error,
  ];

  static ApplicantPersonInsolvencyEnum? fromJson(dynamic value) => ApplicantPersonInsolvencyEnumTypeTransformer().decode(value);

  static List<ApplicantPersonInsolvencyEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplicantPersonInsolvencyEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicantPersonInsolvencyEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ApplicantPersonInsolvencyEnum] to String,
/// and [decode] dynamic data back to [ApplicantPersonInsolvencyEnum].
class ApplicantPersonInsolvencyEnumTypeTransformer {
  factory ApplicantPersonInsolvencyEnumTypeTransformer() => _instance ??= const ApplicantPersonInsolvencyEnumTypeTransformer._();

  const ApplicantPersonInsolvencyEnumTypeTransformer._();

  String encode(ApplicantPersonInsolvencyEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ApplicantPersonInsolvencyEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ApplicantPersonInsolvencyEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'unchecked': return ApplicantPersonInsolvencyEnum.unchecked;
        case r'clear': return ApplicantPersonInsolvencyEnum.clear;
        case r'record': return ApplicantPersonInsolvencyEnum.record;
        case r'error': return ApplicantPersonInsolvencyEnum.error;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ApplicantPersonInsolvencyEnumTypeTransformer] instance.
  static ApplicantPersonInsolvencyEnumTypeTransformer? _instance;
}


