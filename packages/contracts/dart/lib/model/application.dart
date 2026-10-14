//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Application {
  /// Returns a new [Application] instance.
  Application({
    required this.id,
    required this.listingId,
    required this.orgId,
    required this.listingTitle,
    this.groupId,
    this.groupName,
    required this.status,
    this.rejectReason,
    this.message,
    this.preferredFrom,
    this.durationMonths,
    required this.householdSize,
    required this.consentNeeded,
    this.myConsentAt,
    required this.createdAt,
    this.submittedAt,
  });

  String id;

  String listingId;

  String orgId;

  I18nText listingTitle;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? groupId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? groupName;

  ApplicationStatus status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  RejectReason? rejectReason;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? message;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? preferredFrom;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? durationMonths;

  int householdSize;

  /// True when I am asked to consent (group application).
  bool consentNeeded;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? myConsentAt;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? submittedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Application &&
    other.id == id &&
    other.listingId == listingId &&
    other.orgId == orgId &&
    other.listingTitle == listingTitle &&
    other.groupId == groupId &&
    other.groupName == groupName &&
    other.status == status &&
    other.rejectReason == rejectReason &&
    other.message == message &&
    other.preferredFrom == preferredFrom &&
    other.durationMonths == durationMonths &&
    other.householdSize == householdSize &&
    other.consentNeeded == consentNeeded &&
    other.myConsentAt == myConsentAt &&
    other.createdAt == createdAt &&
    other.submittedAt == submittedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (listingId.hashCode) +
    (orgId.hashCode) +
    (listingTitle.hashCode) +
    (groupId == null ? 0 : groupId!.hashCode) +
    (groupName == null ? 0 : groupName!.hashCode) +
    (status.hashCode) +
    (rejectReason == null ? 0 : rejectReason!.hashCode) +
    (message == null ? 0 : message!.hashCode) +
    (preferredFrom == null ? 0 : preferredFrom!.hashCode) +
    (durationMonths == null ? 0 : durationMonths!.hashCode) +
    (householdSize.hashCode) +
    (consentNeeded.hashCode) +
    (myConsentAt == null ? 0 : myConsentAt!.hashCode) +
    (createdAt.hashCode) +
    (submittedAt == null ? 0 : submittedAt!.hashCode);

  @override
  String toString() => 'Application[id=$id, listingId=$listingId, orgId=$orgId, listingTitle=$listingTitle, groupId=$groupId, groupName=$groupName, status=$status, rejectReason=$rejectReason, message=$message, preferredFrom=$preferredFrom, durationMonths=$durationMonths, householdSize=$householdSize, consentNeeded=$consentNeeded, myConsentAt=$myConsentAt, createdAt=$createdAt, submittedAt=$submittedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'listing_id'] = this.listingId;
      json[r'org_id'] = this.orgId;
      json[r'listing_title'] = this.listingTitle;
    if (this.groupId != null) {
      json[r'group_id'] = this.groupId;
    } else {
      json[r'group_id'] = null;
    }
    if (this.groupName != null) {
      json[r'group_name'] = this.groupName;
    } else {
      json[r'group_name'] = null;
    }
      json[r'status'] = this.status;
    if (this.rejectReason != null) {
      json[r'reject_reason'] = this.rejectReason;
    } else {
      json[r'reject_reason'] = null;
    }
    if (this.message != null) {
      json[r'message'] = this.message;
    } else {
      json[r'message'] = null;
    }
    if (this.preferredFrom != null) {
      json[r'preferred_from'] = _dateFormatter.format(this.preferredFrom!.toUtc());
    } else {
      json[r'preferred_from'] = null;
    }
    if (this.durationMonths != null) {
      json[r'duration_months'] = this.durationMonths;
    } else {
      json[r'duration_months'] = null;
    }
      json[r'household_size'] = this.householdSize;
      json[r'consent_needed'] = this.consentNeeded;
    if (this.myConsentAt != null) {
      json[r'my_consent_at'] = this.myConsentAt!.toUtc().toIso8601String();
    } else {
      json[r'my_consent_at'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    if (this.submittedAt != null) {
      json[r'submitted_at'] = this.submittedAt!.toUtc().toIso8601String();
    } else {
      json[r'submitted_at'] = null;
    }
    return json;
  }

  /// Returns a new [Application] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Application? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Application[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Application[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Application(
        id: mapValueOfType<String>(json, r'id')!,
        listingId: mapValueOfType<String>(json, r'listing_id')!,
        orgId: mapValueOfType<String>(json, r'org_id')!,
        listingTitle: I18nText.fromJson(json[r'listing_title'])!,
        groupId: mapValueOfType<String>(json, r'group_id'),
        groupName: mapValueOfType<String>(json, r'group_name'),
        status: ApplicationStatus.fromJson(json[r'status'])!,
        rejectReason: RejectReason.fromJson(json[r'reject_reason']),
        message: mapValueOfType<String>(json, r'message'),
        preferredFrom: mapDateTime(json, r'preferred_from', r''),
        durationMonths: mapValueOfType<int>(json, r'duration_months'),
        householdSize: mapValueOfType<int>(json, r'household_size')!,
        consentNeeded: mapValueOfType<bool>(json, r'consent_needed')!,
        myConsentAt: mapDateTime(json, r'my_consent_at', r''),
        createdAt: mapDateTime(json, r'created_at', r'')!,
        submittedAt: mapDateTime(json, r'submitted_at', r''),
      );
    }
    return null;
  }

  static List<Application> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Application>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Application.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Application> mapFromJson(dynamic json) {
    final map = <String, Application>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Application.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Application-objects as value to a dart map
  static Map<String, List<Application>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Application>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Application.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'listing_id',
    'org_id',
    'listing_title',
    'status',
    'household_size',
    'consent_needed',
    'created_at',
  };
}

