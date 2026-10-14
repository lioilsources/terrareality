//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApplicationInput {
  /// Returns a new [ApplicationInput] instance.
  ApplicationInput({
    required this.listingId,
    this.groupId,
    this.message,
    this.prescreenAnswers = const {},
    this.preferredFrom,
    this.durationMonths,
    this.householdSize,
  });

  String listingId;

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
  String? message;

  Map<String, String> prescreenAnswers;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? preferredFrom;

  /// Minimum value: 1
  /// Maximum value: 120
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? durationMonths;

  /// Minimum value: 1
  /// Maximum value: 20
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? householdSize;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ApplicationInput &&
    other.listingId == listingId &&
    other.groupId == groupId &&
    other.message == message &&
    _deepEquality.equals(other.prescreenAnswers, prescreenAnswers) &&
    other.preferredFrom == preferredFrom &&
    other.durationMonths == durationMonths &&
    other.householdSize == householdSize;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (listingId.hashCode) +
    (groupId == null ? 0 : groupId!.hashCode) +
    (message == null ? 0 : message!.hashCode) +
    (prescreenAnswers.hashCode) +
    (preferredFrom == null ? 0 : preferredFrom!.hashCode) +
    (durationMonths == null ? 0 : durationMonths!.hashCode) +
    (householdSize == null ? 0 : householdSize!.hashCode);

  @override
  String toString() => 'ApplicationInput[listingId=$listingId, groupId=$groupId, message=$message, prescreenAnswers=$prescreenAnswers, preferredFrom=$preferredFrom, durationMonths=$durationMonths, householdSize=$householdSize]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'listing_id'] = this.listingId;
    if (this.groupId != null) {
      json[r'group_id'] = this.groupId;
    } else {
      json[r'group_id'] = null;
    }
    if (this.message != null) {
      json[r'message'] = this.message;
    } else {
      json[r'message'] = null;
    }
      json[r'prescreen_answers'] = this.prescreenAnswers;
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
    if (this.householdSize != null) {
      json[r'household_size'] = this.householdSize;
    } else {
      json[r'household_size'] = null;
    }
    return json;
  }

  /// Returns a new [ApplicationInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApplicationInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ApplicationInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ApplicationInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ApplicationInput(
        listingId: mapValueOfType<String>(json, r'listing_id')!,
        groupId: mapValueOfType<String>(json, r'group_id'),
        message: mapValueOfType<String>(json, r'message'),
        prescreenAnswers: mapCastOfType<String, String>(json, r'prescreen_answers') ?? const {},
        preferredFrom: mapDateTime(json, r'preferred_from', r''),
        durationMonths: mapValueOfType<int>(json, r'duration_months'),
        householdSize: mapValueOfType<int>(json, r'household_size'),
      );
    }
    return null;
  }

  static List<ApplicationInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplicationInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicationInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApplicationInput> mapFromJson(dynamic json) {
    final map = <String, ApplicationInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApplicationInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApplicationInput-objects as value to a dart map
  static Map<String, List<ApplicationInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ApplicationInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApplicationInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'listing_id',
  };
}

