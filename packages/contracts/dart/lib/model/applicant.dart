//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Applicant {
  /// Returns a new [Applicant] instance.
  Applicant({
    required this.application,
    required this.applicantName,
    required this.verificationLevel,
    this.people = const [],
    this.prescreen = const [],
    required this.aiStatus,
    this.aiSummary,
  });

  Application application;

  String applicantName;

  VerificationLevel verificationLevel;

  List<ApplicantPerson> people;

  List<PrescreenAnswer> prescreen;

  ApplicantAiStatusEnum aiStatus;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ApplicationSummary? aiSummary;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Applicant &&
    other.application == application &&
    other.applicantName == applicantName &&
    other.verificationLevel == verificationLevel &&
    _deepEquality.equals(other.people, people) &&
    _deepEquality.equals(other.prescreen, prescreen) &&
    other.aiStatus == aiStatus &&
    other.aiSummary == aiSummary;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (application.hashCode) +
    (applicantName.hashCode) +
    (verificationLevel.hashCode) +
    (people.hashCode) +
    (prescreen.hashCode) +
    (aiStatus.hashCode) +
    (aiSummary == null ? 0 : aiSummary!.hashCode);

  @override
  String toString() => 'Applicant[application=$application, applicantName=$applicantName, verificationLevel=$verificationLevel, people=$people, prescreen=$prescreen, aiStatus=$aiStatus, aiSummary=$aiSummary]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'application'] = this.application;
      json[r'applicant_name'] = this.applicantName;
      json[r'verification_level'] = this.verificationLevel;
      json[r'people'] = this.people;
      json[r'prescreen'] = this.prescreen;
      json[r'ai_status'] = this.aiStatus;
    if (this.aiSummary != null) {
      json[r'ai_summary'] = this.aiSummary;
    } else {
      json[r'ai_summary'] = null;
    }
    return json;
  }

  /// Returns a new [Applicant] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Applicant? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Applicant[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Applicant[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Applicant(
        application: Application.fromJson(json[r'application'])!,
        applicantName: mapValueOfType<String>(json, r'applicant_name')!,
        verificationLevel: VerificationLevel.fromJson(json[r'verification_level'])!,
        people: ApplicantPerson.listFromJson(json[r'people']),
        prescreen: PrescreenAnswer.listFromJson(json[r'prescreen']),
        aiStatus: ApplicantAiStatusEnum.fromJson(json[r'ai_status'])!,
        aiSummary: ApplicationSummary.fromJson(json[r'ai_summary']),
      );
    }
    return null;
  }

  static List<Applicant> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Applicant>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Applicant.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Applicant> mapFromJson(dynamic json) {
    final map = <String, Applicant>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Applicant.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Applicant-objects as value to a dart map
  static Map<String, List<Applicant>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Applicant>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Applicant.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'application',
    'applicant_name',
    'verification_level',
    'people',
    'ai_status',
  };
}


class ApplicantAiStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ApplicantAiStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const pending = ApplicantAiStatusEnum._(r'pending');
  static const ready = ApplicantAiStatusEnum._(r'ready');
  static const failed = ApplicantAiStatusEnum._(r'failed');
  static const disabled = ApplicantAiStatusEnum._(r'disabled');

  /// List of all possible values in this [enum][ApplicantAiStatusEnum].
  static const values = <ApplicantAiStatusEnum>[
    pending,
    ready,
    failed,
    disabled,
  ];

  static ApplicantAiStatusEnum? fromJson(dynamic value) => ApplicantAiStatusEnumTypeTransformer().decode(value);

  static List<ApplicantAiStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplicantAiStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicantAiStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ApplicantAiStatusEnum] to String,
/// and [decode] dynamic data back to [ApplicantAiStatusEnum].
class ApplicantAiStatusEnumTypeTransformer {
  factory ApplicantAiStatusEnumTypeTransformer() => _instance ??= const ApplicantAiStatusEnumTypeTransformer._();

  const ApplicantAiStatusEnumTypeTransformer._();

  String encode(ApplicantAiStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ApplicantAiStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ApplicantAiStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pending': return ApplicantAiStatusEnum.pending;
        case r'ready': return ApplicantAiStatusEnum.ready;
        case r'failed': return ApplicantAiStatusEnum.failed;
        case r'disabled': return ApplicantAiStatusEnum.disabled;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ApplicantAiStatusEnumTypeTransformer] instance.
  static ApplicantAiStatusEnumTypeTransformer? _instance;
}


